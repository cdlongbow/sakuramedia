import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/data/activity_api.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';
import 'package:sakuramedia/features/activity/data/activity_stream_event.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/media_import/data/media_import_api.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/import_sse_channel_provider.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/media_import_api_provider.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/media_import_provider.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';
import 'package:sakuramedia/features/videos/data/api/video_imports_api.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_import_provider.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';

import '../../../../support/fake_http_client_adapter.dart';
import '../../../../support/fake_sse_channel.dart';

void main() {
  late SessionStore sessionStore;
  late _ImportTestBundle bundle;
  late ProviderContainer container;
  late List<FakeSseChannel<ActivityStreamEvent>> channels;
  late bool containerDisposed;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-12-31T12:00:00Z'),
    );
    bundle = _ImportTestBundle(sessionStore);
    channels = <FakeSseChannel<ActivityStreamEvent>>[];
    containerDisposed = false;
    container = ProviderContainer(
      overrides: [
        mediaImportApiProvider.overrideWithValue(bundle.mediaImportApi),
        videoImportsApiProvider.overrideWithValue(bundle.videoImportsApi),
        activityApiProvider.overrideWithValue(bundle.activityApi),
        importSseChannelFactoryProvider.overrideWithValue(({
          required connect,
          required bootstrap,
        }) {
          final channel = FakeSseChannel<ActivityStreamEvent>(
            importBackoff: true,
            giveUpOnUnsupported: true,
            mergeMode: SseMergeMode.none,
            needsBootstrapBeforeStream: true,
            abandonOnBootstrapFailure: true,
            bootstrap: bootstrap,
          );
          channels.add(channel);
          return channel;
        }),
      ],
      retry: (_, __) => null,
    );
  });

  tearDown(() async {
    if (!containerDisposed) container.dispose();
    for (final channel in channels) {
      channel.dispose();
    }
    bundle.dispose();
    sessionStore.dispose();
  });

  test('MediaImport 首屏、分页去重与详情缓存均由 immutable state 承载', () async {
    _enqueueMediaPage(
      bundle,
      page: 1,
      total: 3,
      jobs: [_mediaJob(id: 3, taskRunId: 42)],
    );
    _enqueueBootstrap(bundle, latestEventId: 120);
    final sub = container.listen(mediaImportProvider, (_, __) {});
    addTearDown(sub.close);

    final initial = await container.read(mediaImportProvider.future);
    await _waitUntil(() => channels.single.lastAfterEventId == '120');
    expect(initial.jobs.map((job) => job.id), [3]);
    expect(channels.single.lastAfterEventId, '120');

    _enqueueMediaPage(
      bundle,
      page: 2,
      total: 3,
      jobs: [_mediaJob(id: 3, taskRunId: 42), _mediaJob(id: 2, taskRunId: 41)],
    );
    await container.read(mediaImportProvider.notifier).loadMore();
    final paged = container.read(mediaImportProvider).requireValue;
    expect(paged.jobs.map((job) => job.id), [3, 2]);
    expect(paged.hasMore, isTrue);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/import-jobs/3',
      body: _mediaJob(id: 3, taskRunId: 42, failedFiles: const []),
    );
    final notifier = container.read(mediaImportProvider.notifier);
    await notifier.ensureDetail(3);
    await notifier.ensureDetail(3);
    final detailed = container.read(mediaImportProvider).requireValue;
    expect(detailed.detailFor(3), isNotNull);
    expect(bundle.adapter.hitCount('GET', '/import-jobs/3'), 1);
  });

  test('MediaImport 首屏失败可显式重试', () async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/import-jobs',
      statusCode: 500,
      body: const {'detail': 'boom'},
    );
    _enqueueBootstrap(bundle, latestEventId: 120);
    final sub = container.listen(mediaImportProvider, (_, __) {});
    addTearDown(sub.close);

    final failed = await container.read(mediaImportProvider.future);
    expect(failed.initialError, isNotNull);

    _enqueueMediaPage(
      bundle,
      page: 1,
      total: 1,
      jobs: [_mediaJob(id: 3, taskRunId: 42)],
    );
    await container.read(mediaImportProvider.notifier).loadFirstPage();
    final recovered = container.read(mediaImportProvider).requireValue;
    expect(recovered.initialError, isNull);
    expect(recovered.jobs.single.id, 3);
  });

  test(
    'MediaImport SSE 只在 created reconcile、只在 finished 刷作业并放弃 unsupported',
    () async {
      _enqueueMediaPage(
        bundle,
        page: 1,
        total: 1,
        jobs: [_mediaJob(id: 3, taskRunId: 42, state: 'running')],
      );
      _enqueueBootstrap(bundle, latestEventId: 120);
      final sub = container.listen(mediaImportProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(mediaImportProvider.future);
      await _waitUntil(() => channels.single.lastAfterEventId == '120');
      final channel = channels.single;

      channel.emit(
        ActivityStreamEvent(
          id: 121,
          event: 'task_run_updated',
          taskRun: _taskRun(id: 99, taskKey: kMediaImportTaskKey),
        ),
      );
      await _settleStream();
      expect(bundle.adapter.hitCount('GET', '/import-jobs'), 1);

      _enqueueMediaPage(
        bundle,
        page: 1,
        total: 2,
        jobs: [
          _mediaJob(id: 4, taskRunId: 100, state: 'running'),
          _mediaJob(id: 3, taskRunId: 42, state: 'running'),
        ],
      );
      channel.emit(
        ActivityStreamEvent(
          id: 122,
          event: 'task_run_created',
          taskRun: _taskRun(id: 100, taskKey: kMediaImportTaskKey),
        ),
      );
      await _waitUntil(
        () =>
            container.read(mediaImportProvider).requireValue.jobs.first.id == 4,
      );

      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/import-jobs/3',
        body: _mediaJob(
          id: 3,
          taskRunId: 42,
          state: 'completed',
          imported: 5,
          failedFiles: const [],
        ),
      );
      channel.emit(
        ActivityStreamEvent(
          id: 123,
          event: 'task_run_updated',
          taskRun: _taskRun(
            id: 42,
            taskKey: kMediaImportTaskKey,
            state: 'completed',
          ),
        ),
      );
      await _waitUntil(
        () =>
            container
                .read(mediaImportProvider)
                .requireValue
                .jobs
                .firstWhere((job) => job.id == 3)
                .importedCount ==
            5,
      );
      final finished = container.read(mediaImportProvider).requireValue;
      expect(finished.jobs.firstWhere((job) => job.id == 3).importedCount, 5);

      channel.emitUnsupported();
      await _waitUntil(
        () => channel.state == SseChannelState.unsupportedAbandoned,
      );
      expect(channel.state, SseChannelState.unsupportedAbandoned);
    },
  );

  test('MediaImport refresh 失败保留旧列表', () async {
    _enqueueMediaPage(
      bundle,
      page: 1,
      total: 1,
      jobs: [_mediaJob(id: 3, taskRunId: 42)],
    );
    _enqueueBootstrap(bundle, latestEventId: 120);
    final sub = container.listen(mediaImportProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(mediaImportProvider.future);
    await _settleStream();

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/import-jobs',
      statusCode: 500,
      body: const {'detail': 'boom'},
    );
    await container.read(mediaImportProvider.notifier).refresh();
    expect(container.read(mediaImportProvider).requireValue.jobs.single.id, 3);
  });

  test(
    'VideoImport bootstrap、created reconcile 与 finished refresh 保持平行语义',
    () async {
      _enqueueVideoPage(
        bundle,
        page: 1,
        total: 1,
        jobs: [_videoJob(id: 7, taskRunId: 70, state: 'running')],
      );
      _enqueueBootstrap(bundle, latestEventId: 320);
      final sub = container.listen(videoImportProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(videoImportProvider.future);
      await _waitUntil(() => channels.single.lastAfterEventId == '320');
      final channel = channels.single;
      expect(channel.lastAfterEventId, '320');

      _enqueueVideoPage(
        bundle,
        page: 1,
        total: 2,
        jobs: [
          _videoJob(id: 8, taskRunId: 80, state: 'running'),
          _videoJob(id: 7, taskRunId: 70, state: 'running'),
        ],
      );
      channel.emit(
        ActivityStreamEvent(
          id: 321,
          event: 'task_run_created',
          taskRun: _taskRun(id: 80, taskKey: kVideoImportTaskKey),
        ),
      );
      await _waitUntil(
        () =>
            container.read(videoImportProvider).requireValue.jobs.first.id == 8,
      );

      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/video-imports/7',
        body: _videoJob(
          id: 7,
          taskRunId: 70,
          state: 'completed',
          imported: 6,
          failedFiles: const [],
        ),
      );
      channel.emit(
        ActivityStreamEvent(
          id: 322,
          event: 'task_run_updated',
          taskRun: _taskRun(
            id: 70,
            taskKey: kVideoImportTaskKey,
            state: 'completed',
          ),
        ),
      );
      await _waitUntil(
        () =>
            container
                .read(videoImportProvider)
                .requireValue
                .jobs
                .firstWhere((job) => job.id == 7)
                .importedCount ==
            6,
      );
      expect(
        container
            .read(videoImportProvider)
            .requireValue
            .jobs
            .firstWhere((job) => job.id == 7)
            .importedCount,
        6,
      );
    },
  );

  test('VideoImport 分页去重与详情缓存保持平行语义', () async {
    _enqueueVideoPage(
      bundle,
      page: 1,
      total: 3,
      jobs: [_videoJob(id: 7, taskRunId: 70)],
    );
    _enqueueBootstrap(bundle, latestEventId: 320);
    final sub = container.listen(videoImportProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(videoImportProvider.future);

    _enqueueVideoPage(
      bundle,
      page: 2,
      total: 3,
      jobs: [_videoJob(id: 7, taskRunId: 70), _videoJob(id: 6, taskRunId: 60)],
    );
    final notifier = container.read(videoImportProvider.notifier);
    await notifier.loadMore();
    expect(
      container
          .read(videoImportProvider)
          .requireValue
          .jobs
          .map((job) => job.id),
      [7, 6],
    );

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/video-imports/7',
      body: _videoJob(id: 7, taskRunId: 70, failedFiles: const []),
    );
    await notifier.ensureDetail(7);
    await notifier.ensureDetail(7);
    expect(
      container.read(videoImportProvider).requireValue.detailFor(7),
      isNotNull,
    );
    expect(bundle.adapter.hitCount('GET', '/video-imports/7'), 1);
  });

  test('VideoImport reimport 保留 collectionId 与来源参数', () async {
    _enqueueVideoPage(
      bundle,
      page: 1,
      total: 1,
      jobs: [_videoJob(id: 7, taskRunId: 70, state: 'failed')],
    );
    _enqueueBootstrap(bundle, latestEventId: 320);
    final sub = container.listen(videoImportProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(videoImportProvider.future);
    await _settleStream();

    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/video-imports',
      body: const {
        'video_import_job_id': 8,
        'task_run_id': 80,
        'status': 'pending',
      },
    );
    _enqueueVideoPage(
      bundle,
      page: 1,
      total: 1,
      jobs: [_videoJob(id: 7, taskRunId: 70, state: 'failed')],
    );
    final error = await container
        .read(videoImportProvider.notifier)
        .reimportJob(7);
    expect(error, isNull);
    final posted = bundle.adapter.requests.firstWhere(
      (request) => request.method == 'POST' && request.path == '/video-imports',
    );
    expect(posted.body, {
      'library_id': 1,
      'source_path': '/mnt/incoming/videos',
      'transfer_mode': 'auto',
      'collection_id': 9,
    });
  });

  test('容器销毁后忽略 VideoImport refresh 的迟到回包', () async {
    _enqueueVideoPage(
      bundle,
      page: 1,
      total: 1,
      jobs: [_videoJob(id: 7, taskRunId: 70)],
    );
    _enqueueBootstrap(bundle, latestEventId: 320);
    final sub = container.listen(videoImportProvider, (_, __) {});
    await container.read(videoImportProvider.future);
    await _settleStream();

    final response = Completer<ResponseBody>();
    bundle.adapter.enqueueResponder(
      method: 'GET',
      path: '/video-imports',
      responder: (_, __) => response.future,
    );
    final pending = container.read(videoImportProvider.notifier).refresh();
    await _settleStream();
    sub.close();
    container.dispose();
    containerDisposed = true;
    response.complete(
      ResponseBody.fromString(
        jsonEncode({
          'items': [_videoJob(id: 8, taskRunId: 80)],
          'page': 1,
          'page_size': 20,
          'total': 1,
        }),
        200,
        headers: const {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    await expectLater(pending, completes);
  });
}

Future<void> _settleStream() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('condition was not reached before timeout');
}

void _enqueueMediaPage(
  _ImportTestBundle bundle, {
  required int page,
  required int total,
  required List<Map<String, dynamic>> jobs,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/import-jobs',
    body: {'items': jobs, 'page': page, 'page_size': 20, 'total': total},
  );
}

void _enqueueVideoPage(
  _ImportTestBundle bundle, {
  required int page,
  required int total,
  required List<Map<String, dynamic>> jobs,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/video-imports',
    body: {'items': jobs, 'page': page, 'page_size': 20, 'total': total},
  );
}

void _enqueueBootstrap(_ImportTestBundle bundle, {required int latestEventId}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/activity/bootstrap',
    body: {
      'latest_event_id': latestEventId,
      'notifications': {
        'items': const [],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
      'unread_count': 0,
      'active_task_runs': const [],
      'task_runs': {'items': const [], 'page': 1, 'page_size': 20, 'total': 0},
    },
  );
}

Map<String, dynamic> _mediaJob({
  required int id,
  required int taskRunId,
  String state = 'completed',
  int imported = 0,
  List<Map<String, dynamic>>? failedFiles,
}) {
  return {
    'id': id,
    'source_path': '/mnt/incoming/movies',
    'library_id': 1,
    'task_run_id': taskRunId,
    'state': state,
    'transfer_mode': 'auto',
    'imported_count': imported,
    'skipped_count': 0,
    'failed_count': 0,
    'created_at': '2026-06-07T10:00:00Z',
    'updated_at': '2026-06-07T10:05:00Z',
    if (failedFiles != null) 'failed_files': failedFiles,
  };
}

Map<String, dynamic> _videoJob({
  required int id,
  required int taskRunId,
  String state = 'completed',
  int imported = 0,
  List<Map<String, dynamic>>? failedFiles,
}) {
  return {
    'id': id,
    'source_path': '/mnt/incoming/videos',
    'source_cid': null,
    'source_fid': null,
    'library_id': 1,
    'collection_id': 9,
    'task_run_id': taskRunId,
    'state': state,
    'transfer_mode': 'auto',
    'imported_count': imported,
    'skipped_count': 0,
    'failed_count': 0,
    'created_at': '2026-06-07T10:00:00Z',
    'updated_at': '2026-06-07T10:05:00Z',
    if (failedFiles != null) 'failed_files': failedFiles,
  };
}

TaskRunDto _taskRun({
  required int id,
  required String taskKey,
  String state = 'running',
}) {
  return TaskRunDto(
    id: id,
    taskKey: taskKey,
    taskName: '导入',
    triggerType: 'manual',
    state: state,
    progressCurrent: 1,
    progressTotal: 10,
    progressText: '导入中',
    resultText: null,
    resultSummary: const {},
    errorMessage: null,
    startedAt: DateTime.parse('2026-06-07T10:00:00Z'),
    finishedAt:
        state == 'running' ? null : DateTime.parse('2026-06-07T10:05:00Z'),
    createdAt: DateTime.parse('2026-06-07T10:00:00Z'),
    updatedAt: DateTime.parse('2026-06-07T10:05:00Z'),
  );
}

class _ImportTestBundle {
  _ImportTestBundle(SessionStore sessionStore)
    : apiClient = ApiClient(sessionStore: sessionStore),
      activityStreamClient = _UnusedActivityStreamClient() {
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
    mediaImportApi = MediaImportApi(apiClient: apiClient);
    videoImportsApi = VideoImportsApi(apiClient: apiClient);
    activityApi = ActivityApi(
      apiClient: apiClient,
      streamClient: activityStreamClient,
    );
  }

  final FakeHttpClientAdapter adapter = FakeHttpClientAdapter();
  final ApiClient apiClient;
  final ActivityEventStreamClient activityStreamClient;
  late final MediaImportApi mediaImportApi;
  late final VideoImportsApi videoImportsApi;
  late final ActivityApi activityApi;

  void dispose() {
    activityStreamClient.dispose();
    apiClient.dispose();
  }
}

class _UnusedActivityStreamClient implements ActivityEventStreamClient {
  @override
  Stream<ApiSseEvent> connect({required int afterEventId}) =>
      const Stream.empty();

  @override
  void dispose() {}
}
