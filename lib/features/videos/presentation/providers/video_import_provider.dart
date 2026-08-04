import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/activity/data/activity_stream_event.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/media_import/data/media_import_source.dart';
import 'package:sakuramedia/features/media_import/presentation/import_jobs_view_controller.dart';
import 'package:sakuramedia/features/media_import/presentation/import_jobs_view_state.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/import_sse_channel_provider.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';
import 'package:sakuramedia/features/videos/data/dto/video_import_job_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';

part 'video_import_provider.g.dart';

const String kVideoImportTaskKey = 'video_directory_import';

typedef VideoImportState =
    ImportJobsViewState<VideoImportJobListItemDto, VideoImportJobDto>;

/// PornBox 视频导入：与 JAV 导入保持逐项平行的 Riverpod 状态源。
@Riverpod(retry: kNoAsyncNotifierRetry)
class VideoImport extends _$VideoImport
    with AsyncNotifierDisposeGuardMixin<VideoImportState>
    implements ImportJobsViewController {
  static const int _pageSize = 20;

  late final SseChannel<ActivityStreamEvent> _channel;
  int _lastEventId = 0;

  VideoImportState get _current =>
      state.value ?? VideoImportState(isInitialLoading: true);

  @override
  Future<VideoImportState> build() async {
    attachDisposeGuard();
    _channel = ref.read(importSseChannelFactoryProvider)(
      connect: _connectStream,
      bootstrap: _bootstrapStream,
    );
    ref.onDispose(() => unawaited(_channel.shutdown()));

    final initial = await _fetchFirstPage(
      VideoImportState(isInitialLoading: true),
    );
    unawaited(_startStreamAfterBuild());
    return initial;
  }

  Future<void> _startStreamAfterBuild() async {
    await Future<void>.delayed(Duration.zero);
    if (isDisposed) return;
    await _channel.start(onEvent: _handleStreamEvent);
  }

  @override
  Future<void> loadFirstPage() async {
    if (isDisposed) return;
    final before = _current;
    state = AsyncData(
      before.copyWith(isInitialLoading: true, initialError: null),
    );
    final next = await _fetchFirstPage(before.copyWith(isInitialLoading: true));
    if (!isDisposed) state = AsyncData(_mergeFirstPage(_current, next));
  }

  VideoImportState _mergeFirstPage(
    VideoImportState current,
    VideoImportState result,
  ) {
    return current.copyWith(
      jobs: result.jobs,
      nextPage: result.nextPage,
      hasMore: result.hasMore,
      isInitialLoading: result.isInitialLoading,
      initialError: result.initialError,
      loadMoreError: result.loadMoreError,
    );
  }

  Future<VideoImportState> _fetchFirstPage(VideoImportState base) async {
    try {
      final response = await ref
          .read(videoImportsApiProvider)
          .listVideoImportJobs(page: 1, pageSize: _pageSize);
      return base.copyWith(
        jobs: response.items,
        nextPage: 2,
        hasMore: response.items.length < response.total,
        isInitialLoading: false,
        initialError: null,
        loadMoreError: null,
      );
    } catch (error) {
      return base.copyWith(
        isInitialLoading: false,
        initialError: apiErrorMessage(error, fallback: '加载导入作业失败，请稍后重试。'),
      );
    }
  }

  @override
  Future<void> refresh() async {
    if (isDisposed) return;
    final before = _current;
    if (before.isRefreshing) return;
    state = AsyncData(before.copyWith(isRefreshing: true));
    try {
      final response = await ref
          .read(videoImportsApiProvider)
          .listVideoImportJobs(page: 1, pageSize: _pageSize);
      if (isDisposed) return;
      final current = _current;
      state = AsyncData(
        current.copyWith(
          jobs: response.items,
          nextPage: 2,
          hasMore: response.items.length < response.total,
          initialError: null,
          loadMoreError: null,
          isRefreshing: false,
        ),
      );
    } catch (_) {
      if (!isDisposed) {
        state = AsyncData(_current.copyWith(isRefreshing: false));
      }
    }
  }

  @override
  Future<void> loadMore() async {
    if (isDisposed) return;
    final before = _current;
    if (before.isLoadingMore || !before.hasMore || before.isInitialLoading) {
      return;
    }
    state = AsyncData(
      before.copyWith(isLoadingMore: true, loadMoreError: null),
    );
    try {
      final response = await ref
          .read(videoImportsApiProvider)
          .listVideoImportJobs(page: before.nextPage, pageSize: _pageSize);
      if (isDisposed) return;
      final current = _current;
      final existingIds = current.jobs.map((job) => job.id).toSet();
      final jobs = <VideoImportJobListItemDto>[
        ...current.jobs,
        ...response.items.where((job) => !existingIds.contains(job.id)),
      ];
      state = AsyncData(
        current.copyWith(
          jobs: jobs,
          nextPage: response.page + 1,
          hasMore: jobs.length < response.total,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (isDisposed) return;
      state = AsyncData(
        _current.copyWith(
          isLoadingMore: false,
          loadMoreError: apiErrorMessage(error, fallback: '加载更多失败，请重试。'),
        ),
      );
    }
  }

  @override
  Future<void> ensureDetail(int jobId, {bool force = false}) async {
    if (isDisposed) return;
    final before = _current;
    if ((!force && before.details.containsKey(jobId)) ||
        before.detailLoading.contains(jobId)) {
      return;
    }
    final loading = Set<int>.of(before.detailLoading)..add(jobId);
    final errors = Map<int, String>.of(before.detailErrors)..remove(jobId);
    state = AsyncData(
      before.copyWith(detailLoading: loading, detailErrors: errors),
    );
    try {
      final detail = await ref
          .read(videoImportsApiProvider)
          .getVideoImportJob(jobId);
      if (isDisposed) return;
      final current = _current;
      final details = Map<int, VideoImportJobDto>.of(current.details)
        ..[jobId] = detail;
      state = AsyncData(
        _replaceJob(current, detail).copyWith(details: details),
      );
    } catch (error) {
      if (isDisposed) return;
      final current = _current;
      final detailErrors = Map<int, String>.of(current.detailErrors)
        ..[jobId] = apiErrorMessage(error, fallback: '加载失败文件失败，请重试。');
      state = AsyncData(current.copyWith(detailErrors: detailErrors));
    } finally {
      if (!isDisposed) {
        final current = _current;
        final nextLoading = Set<int>.of(current.detailLoading)..remove(jobId);
        state = AsyncData(current.copyWith(detailLoading: nextLoading));
      }
    }
  }

  Future<String?> triggerImport({
    required int libraryId,
    required MediaImportSource source,
    required TransferMode transferMode,
    int? collectionId,
  }) async {
    if (isDisposed) return null;
    try {
      await ref
          .read(videoImportsApiProvider)
          .createVideoImport(
            libraryId: libraryId,
            source: source,
            transferMode: transferMode,
            collectionId: collectionId,
          );
      if (isDisposed) return null;
      await refresh();
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: '触发导入失败，请稍后重试。');
    }
  }

  @override
  Future<String?> retryFailedFiles(int jobId, {List<String>? files}) async {
    if (isDisposed) return null;
    try {
      await ref
          .read(videoImportsApiProvider)
          .retryFailedFiles(jobId, files: files);
      if (isDisposed) return null;
      await refresh();
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: '重导失败文件失败，请稍后重试。');
    }
  }

  @override
  Future<String?> reimportJob(int jobId) async {
    if (isDisposed) return null;
    final current = _current;
    final index = current.jobs.indexWhere((item) => item.id == jobId);
    final source = index < 0 ? null : current.jobs[index].reimportSource;
    if (source == null) return '该作业无法重新导入，请刷新后重试。';
    return triggerImport(
      libraryId: current.jobs[index].libraryId,
      source: source,
      transferMode: current.jobs[index].transferMode,
      collectionId: current.jobs[index].collectionId,
    );
  }

  VideoImportState _replaceJob(
    VideoImportState current,
    VideoImportJobListItemDto job,
  ) {
    final index = current.jobs.indexWhere((item) => item.id == job.id);
    if (index < 0) return current;
    final jobs = List<VideoImportJobListItemDto>.of(current.jobs)
      ..[index] = job;
    return current.copyWith(jobs: jobs);
  }

  Future<String?> _bootstrapStream() async {
    final bootstrap = await ref.read(activityApiProvider).getBootstrap();
    if (isDisposed) return null;
    _lastEventId = bootstrap.latestEventId;
    final runs = Map<int, TaskRunDto>.of(_current.taskRunsById);
    for (final run in bootstrap.activeTaskRuns) {
      if (run.taskKey == kVideoImportTaskKey) runs[run.id] = run;
    }
    state = AsyncData(_current.copyWith(taskRunsById: runs));
    return _lastEventId.toString();
  }

  Stream<ActivityStreamEvent> _connectStream({String? afterEventId}) {
    final cursor = int.tryParse(afterEventId ?? '') ?? _lastEventId;
    return ref.read(activityApiProvider).streamEvents(afterEventId: cursor);
  }

  void _handleStreamEvent(ActivityStreamEvent event) {
    if (isDisposed) return;
    if (event.id != null && event.id! > _lastEventId) {
      _lastEventId = event.id!;
    }
    final run = event.taskRun;
    if (run == null ||
        !(event.isTaskRunCreated || event.isTaskRunUpdated) ||
        run.taskKey != kVideoImportTaskKey) {
      return;
    }
    final current = _current;
    final runs = Map<int, TaskRunDto>.of(current.taskRunsById)..[run.id] = run;
    state = AsyncData(current.copyWith(taskRunsById: runs));

    final job = _jobForTaskRun(run.id);
    if (job == null) {
      if (event.isTaskRunCreated) unawaited(_reconcileFirstPage());
    } else if (run.isFinished) {
      unawaited(_refreshJobAfterFinish(job.id));
    }
  }

  Future<void> _reconcileFirstPage() async {
    final before = _current;
    if (before.isReconciling) return;
    state = AsyncData(before.copyWith(isReconciling: true));
    try {
      final response = await ref
          .read(videoImportsApiProvider)
          .listVideoImportJobs(page: 1, pageSize: _pageSize);
      if (isDisposed) return;
      final current = _current;
      final fresh = <int, VideoImportJobListItemDto>{
        for (final job in response.items) job.id: job,
      };
      final merged = <VideoImportJobListItemDto>[
        ...response.items,
        for (final job in current.jobs)
          if (!fresh.containsKey(job.id)) job,
      ]..sort((left, right) => right.id.compareTo(left.id));
      state = AsyncData(
        current.copyWith(
          jobs: merged,
          nextPage: (merged.length / _pageSize).ceil() + 1,
          hasMore: merged.length < response.total,
          isReconciling: false,
        ),
      );
    } catch (_) {
      if (!isDisposed) {
        state = AsyncData(_current.copyWith(isReconciling: false));
      }
    }
  }

  VideoImportJobListItemDto? _jobForTaskRun(int taskRunId) {
    for (final job in _current.jobs) {
      if (job.taskRunId == taskRunId) return job;
    }
    return null;
  }

  Future<void> _refreshJobAfterFinish(int jobId) async {
    try {
      final detail = await ref
          .read(videoImportsApiProvider)
          .getVideoImportJob(jobId);
      if (isDisposed) return;
      final current = _current;
      var next = _replaceJob(current, detail);
      if (current.details.containsKey(jobId)) {
        final details = Map<int, VideoImportJobDto>.of(current.details)
          ..[jobId] = detail;
        next = next.copyWith(details: details);
      }
      state = AsyncData(next);
    } catch (_) {
      // 终态刷新失败不影响实时进度展示。
    }
  }
}
