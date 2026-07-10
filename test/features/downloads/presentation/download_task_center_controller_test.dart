import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/downloads/presentation/download_task_center_controller.dart';

import '../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-07-10T10:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  DownloadTaskCenterController newController() {
    return DownloadTaskCenterController(
      downloadsApi: bundle.downloadsApi,
      downloadClientsApi: bundle.downloadClientsApi,
    );
  }

  Map<String, dynamic> taskJson({
    required int id,
    String downloadState = 'downloading',
    String importStatus = 'pending',
    String importStatusLabel = '等待导入',
    double progress = 0.0,
  }) {
    return <String, dynamic>{
      'id': id,
      'client_id': 2,
      'movie_number': 'ABC-00$id',
      'name': 'ABC-00$id',
      'info_hash': 'hash-$id',
      'save_path': '/mnt/$id',
      'progress': progress,
      'download_state': downloadState,
      'import_status': importStatus,
      'import_status_label': importStatusLabel,
      'created_at': '2026-07-10T08:0$id:00Z',
      'updated_at': '2026-07-10T08:0$id:00Z',
    };
  }

  void enqueueFirstPage(List<Map<String, dynamic>> items, {int? total}) {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks',
      body: <String, dynamic>{
        'items': items,
        'page': 1,
        'page_size': 20,
        'total': total ?? items.length,
      },
    );
  }

  void enqueueClients() {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-clients',
      body: <Map<String, dynamic>>[
        {
          'id': 2,
          'name': 'qb-main',
          'base_url': 'http://qb:8080',
          'username': 'admin',
          'client_save_path': '/downloads',
          'local_root_path': '/mnt/qb',
          'media_library_id': 1,
          'has_password': true,
        },
      ],
    );
  }

  test('initialize loads first page and client names', () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();

    final controller = newController();
    addTearDown(controller.dispose);

    await controller.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.initialized, isTrue);
    expect(controller.items, hasLength(1));
    expect(controller.items.first.task.importStatusLabel, '等待导入');
    expect(controller.clientNameOf(2), 'qb-main');
  });

  test('loadMore failure keeps existing list and surfaces error message',
      () async {
    enqueueFirstPage(
      [taskJson(id: 1)],
      total: 40,
    );
    enqueueClients();
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks',
      statusCode: 500,
      body: <String, dynamic>{
        'error': {'code': 'server_error', 'message': 'boom'},
      },
    );

    final controller = newController();
    addTearDown(controller.dispose);

    await controller.initialize();
    expect(controller.hasMore, isTrue);
    await controller.loadMore();

    expect(controller.items, hasLength(1));
    expect(controller.loadMoreErrorMessage, isNotNull);
  });

  test('SSE snapshot patches live progress on known rows', () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();
    bundle.adapter.enqueueSse(
      method: 'GET',
      path: '/download-tasks/stream',
      keepOpen: true,
      chunks: <String>[
        'event: snapshot\n'
            'data: {"client_id":2,"items":[{"task_id":1,"client_id":2,"name":"ABC-001","info_hash":"hash-1","progress":0.5,"raw_state":"downloading","download_state":"downloading","download_speed_bytes":2048,"uploaded_speed_bytes":512,"downloaded_bytes":500,"total_size_bytes":1000,"eta_seconds":60}]}\n\n',
      ],
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.connectStream();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.streamState, DownloadTaskStreamState.live);
    expect(controller.items.first.progress, closeTo(0.5, 1e-9));
    expect(controller.items.first.live?.uploadedSpeedBytes, 512);
  });

  test(
    'SSE update for unknown task_id triggers debounced first-page merge',
    () async {
      // 首次 initialize 时列表只有 id=1；SSE 推来 id=2 未知任务；
      // 800ms 去抖后应触发第二次 /download-tasks 拉取合并纳新。
      enqueueFirstPage([taskJson(id: 1)]);
      enqueueClients();
      bundle.adapter.enqueueSse(
        method: 'GET',
        path: '/download-tasks/stream',
        keepOpen: true,
        chunks: <String>[
          'event: download_task_updated\n'
              'data: {"task_id":2,"client_id":2,"name":"ABC-002","info_hash":"hash-2","progress":0.3,"raw_state":"downloading","download_state":"downloading","download_speed_bytes":1024,"uploaded_speed_bytes":128,"downloaded_bytes":100,"total_size_bytes":333,"eta_seconds":60}\n\n',
        ],
      );
      enqueueFirstPage(
        [taskJson(id: 2), taskJson(id: 1)],
        total: 2,
      );

      final controller = newController();
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.connectStream();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 事件到达后先应用未知任务的短路 → 触发 merge debounce
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(controller.items.map((row) => row.task.id).toList(),
          equals(<int>[2, 1]));
      expect(bundle.adapter.hitCount('GET', '/download-tasks'), 2);
    },
  );

  test('SSE removed frame drops row and decrements total', () async {
    enqueueFirstPage(
      [taskJson(id: 1), taskJson(id: 2)],
      total: 2,
    );
    enqueueClients();
    bundle.adapter.enqueueSse(
      method: 'GET',
      path: '/download-tasks/stream',
      keepOpen: true,
      chunks: <String>[
        'event: download_task_removed\n'
            'data: {"task_id":1,"client_id":2,"info_hash":"hash-1"}\n\n',
      ],
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.connectStream();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.items.map((row) => row.task.id).toList(), <int>[2]);
    expect(controller.total, 1);
  });

  test(
    'download_client_status transfer + health frames update client transfer state',
    () async {
      enqueueFirstPage(const <Map<String, dynamic>>[]);
      enqueueClients();
      bundle.adapter.enqueueSse(
        method: 'GET',
        path: '/download-tasks/stream',
        keepOpen: true,
        chunks: <String>[
          'event: download_client_status\n'
              'data: {"client_id":2,"download_speed_bytes":4096,"upload_speed_bytes":1024,"connection_status":"connected"}\n\n',
          'event: download_client_status\n'
              'data: {"client_id":2,"status":"unavailable","message":"qB offline"}\n\n',
        ],
      );

      final controller = newController();
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.connectStream();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final transfer = controller.clientTransfers[2]!;
      expect(transfer.isAvailable, isFalse);
      expect(transfer.unavailableMessage, 'qB offline');
      // 不可用后速度清零，避免残留错读。
      expect(transfer.downloadSpeedBytes, 0);
      expect(transfer.uploadSpeedBytes, 0);
      expect(controller.totalDownloadSpeedBytes, 0);
    },
  );

  test('pauseTask patches downloadState and clears pending on success',
      () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/download-tasks/1/pause',
      body: {'task_id': 1, 'action': 'pause', 'status': 'ok'},
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.pauseTask(1);
    expect(controller.items.first.task.downloadState, 'paused');
    expect(controller.isTaskPending(1), isFalse);
  });

  test('resumeTask propagates 409 and clears pending', () async {
    enqueueFirstPage([taskJson(id: 1, downloadState: 'paused')]);
    enqueueClients();
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/download-tasks/1/resume',
      statusCode: 409,
      body: {
        'error': {
          'code': 'download_task_remote_missing',
          'message': '任务在下载器中已不存在',
        },
      },
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();

    await expectLater(
      controller.resumeTask(1),
      throwsA(isA<ApiException>()),
    );
    expect(controller.isTaskPending(1), isFalse);
    // 状态未改，仍为 paused。
    expect(controller.items.first.task.downloadState, 'paused');
  });

  test('deleteTask with deleteFiles=true sends double confirm and removes row',
      () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/download-tasks/1',
      statusCode: 204,
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.deleteTask(1, deleteFiles: true);

    final deleteReq = bundle.adapter.requests
        .lastWhere((r) => r.path == '/download-tasks/1' && r.method == 'DELETE');
    expect(deleteReq.uri.queryParameters['delete_files'], 'true');
    expect(deleteReq.uri.queryParameters['confirm_delete_files'], 'true');
    expect(controller.items, isEmpty);
  });

  test('deleteTask failure keeps row and rethrows for toast', () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/download-tasks/1',
      statusCode: 409,
      body: {
        'error': {
          'code': 'download_task_import_running',
          'message': '任务正在导入无法删除',
        },
      },
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();

    await expectLater(
      controller.deleteTask(1, deleteFiles: false),
      throwsA(isA<ApiException>()),
    );
    expect(controller.items, hasLength(1));
  });

  test('disconnectStream returns to idle and later events are dropped',
      () async {
    enqueueFirstPage([taskJson(id: 1)]);
    enqueueClients();
    bundle.adapter.enqueueSse(
      method: 'GET',
      path: '/download-tasks/stream',
      keepOpen: true,
      chunks: <String>[
        'event: heartbeat\n'
            'data: {}\n\n',
      ],
    );

    final controller = newController();
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.connectStream();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.streamState, DownloadTaskStreamState.live);

    controller.disconnectStream();
    expect(controller.streamState, DownloadTaskStreamState.idle);
    // 列表快照仍在。
    expect(controller.items, hasLength(1));
  });
}
