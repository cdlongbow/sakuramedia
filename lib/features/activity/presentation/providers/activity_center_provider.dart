import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/json/json_parse.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/activity/data/activity_bootstrap_dto.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';
import 'package:sakuramedia/features/activity/data/activity_stream_event.dart';
import 'package:sakuramedia/features/activity/data/job_metadata_dto.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:sakuramedia/features/activity/presentation/activity_filter_state.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_center_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';

part 'activity_center_provider.g.dart';

@Riverpod(retry: kNoAsyncNotifierRetry)
class ActivityCenter extends _$ActivityCenter
    with AsyncNotifierDisposeGuardMixin<ActivityCenterState> {
  static const int _pageSize = 20;
  static const Duration _longDisconnectThreshold = Duration(minutes: 2);
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const List<Duration> _reconnectDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ];

  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  StreamSubscription<ActivityStreamEvent>? _eventSubscription;
  DateTime? _disconnectStartedAt;
  int _reconnectAttempt = 0;
  int _taskRefreshRequestId = 0;
  int _lastEventId = 0;
  ActivityTab? _pendingActiveTab;
  int? _pendingHighlightedTaskRunId;
  bool _hasPendingHighlight = false;
  final List<ActivityStreamEvent> _pendingStreamEvents =
      <ActivityStreamEvent>[];
  bool _isStreamFlushScheduled = false;

  ActivityCenterState get current => state.value ?? ActivityCenterState.initial;

  @override
  Future<ActivityCenterState> build() async {
    attachDisposeGuard();
    ref.onDispose(() {
      _cancelReconnectTimer();
      _cancelPollingTimer();
      unawaited(_eventSubscription?.cancel());
      _eventSubscription = null;
      _resetPendingStreamEvents();
    });
    return _loadInitialState();
  }

  Future<ActivityCenterState> _loadInitialState() async {
    try {
      final jobsFuture = _fetchJobs();
      final bootstrap = await _fetchBootstrap(ActivityTaskFilterState.initial);
      final jobsResult = await jobsFuture;
      if (isDisposed) return ActivityCenterState.initial;
      final base = state.value ?? ActivityCenterState.initial;
      var next = _applyBootstrap(base, bootstrap).copyWith(
        initialized: true,
        jobs: jobsResult.jobs,
        jobErrorMessage: jobsResult.errorMessage,
      );
      if (_pendingActiveTab != null || _hasPendingHighlight) {
        next = next.copyWith(
          activeTab: _pendingActiveTab ?? next.activeTab,
          highlightedTaskRunId:
              _hasPendingHighlight
                  ? _pendingHighlightedTaskRunId
                  : next.highlightedTaskRunId,
        );
        _pendingActiveTab = null;
        _pendingHighlightedTaskRunId = null;
        _hasPendingHighlight = false;
      }
      final stream = ref
          .read(activityApiProvider)
          .streamEvents(afterEventId: _lastEventId);
      _eventSubscription = stream.listen(
        _handleStreamEvent,
        onError: _handleStreamError,
        onDone: _handleStreamDone,
        cancelOnError: false,
      );
      next = next.copyWith(
        connectionState: ActivityConnectionState.live,
        connectionMessage: '实时连接中',
      );
      return next;
    } catch (error) {
      return ActivityCenterState.initial.copyWith(
        initialErrorMessage: apiErrorMessage(error, fallback: '任务中心加载失败，请稍后重试'),
        connectionState: ActivityConnectionState.reconnecting,
        connectionMessage: null,
      );
    }
  }

  Future<void> reloadAll() async {
    _taskRefreshRequestId += 1;
    _cancelReconnectTimer();
    _cancelPollingTimer();
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _resetPendingStreamEvents();

    state = AsyncData(
      current.copyWith(
        isInitialLoading: true,
        isLoadingJobs: true,
        isRefreshingTaskHistory: false,
        initialErrorMessage: null,
        jobErrorMessage: null,
        taskRefreshErrorMessage: null,
        connectionState: ActivityConnectionState.connecting,
        connectionMessage: '正在同步任务中心',
      ),
    );
    try {
      final filter = current.taskFilter;
      final jobsFuture = _fetchJobs();
      final bootstrap = await _fetchBootstrap(filter);
      final jobsResult = await jobsFuture;
      if (isDisposed) return;
      state = AsyncData(
        _applyBootstrap(current, bootstrap).copyWith(
          initialized: true,
          isInitialLoading: false,
          isLoadingJobs: false,
          initialErrorMessage: null,
          jobs: jobsResult.jobs,
          jobErrorMessage: jobsResult.errorMessage,
        ),
      );
      await _connectStream();
    } catch (error) {
      if (isDisposed) return;
      state = AsyncData(
        current.copyWith(
          isInitialLoading: false,
          isLoadingJobs: false,
          initialErrorMessage: apiErrorMessage(
            error,
            fallback: '任务中心加载失败，请稍后重试',
          ),
          connectionState: ActivityConnectionState.reconnecting,
          connectionMessage: null,
        ),
      );
    }
  }

  void setActiveTab(ActivityTab tab, {int? highlightTaskRunId}) {
    if (state.value == null) {
      _pendingActiveTab = tab;
      _pendingHighlightedTaskRunId = highlightTaskRunId;
      _hasPendingHighlight = true;
      return;
    }
    final now = current;
    if (now.activeTab == tab &&
        highlightTaskRunId == now.highlightedTaskRunId) {
      return;
    }
    state = AsyncData(
      now.copyWith(activeTab: tab, highlightedTaskRunId: highlightTaskRunId),
    );
  }

  void clearHighlightedTaskRun() {
    if (state.value == null) {
      _pendingHighlightedTaskRunId = null;
      _hasPendingHighlight = true;
      return;
    }
    if (current.highlightedTaskRunId == null) return;
    state = AsyncData(current.copyWith(highlightedTaskRunId: null));
  }

  Future<void> applyTaskFilter(ActivityTaskFilterState next) async {
    if (current.taskFilter == next) return;
    state = AsyncData(current.copyWith(taskFilter: next));
    await refreshTaskHistory();
  }

  Future<void> refreshTaskHistory() async {
    final requestId = ++_taskRefreshRequestId;
    state = AsyncData(
      current.copyWith(
        isRefreshingTaskHistory: true,
        taskRefreshErrorMessage: null,
        taskLoadMoreErrorMessage: null,
      ),
    );
    final filter = current.taskFilter;
    try {
      final response = await ref
          .read(activityApiProvider)
          .getTaskRuns(
            page: 1,
            pageSize: _pageSize,
            state: filter.state,
            taskKey: filter.taskKey,
            triggerType: filter.triggerType,
            sort: filter.sort.apiValue,
          );
      if (isDisposed || requestId != _taskRefreshRequestId) return;
      final tasks = _sortHistoryTasks(response.items, filter);
      state = AsyncData(
        current.copyWith(
          taskRuns: tasks,
          taskNextPage: response.page + 1,
          hasMoreTasks: tasks.length < response.total,
          taskLoadMoreErrorMessage: null,
          taskRefreshErrorMessage: null,
          isRefreshingTaskHistory: false,
        ),
      );
    } catch (error) {
      if (isDisposed || requestId != _taskRefreshRequestId) return;
      state = AsyncData(
        current.copyWith(
          taskRefreshErrorMessage: apiErrorMessage(
            error,
            fallback: '任务筛选刷新失败，请重试',
          ),
          isRefreshingTaskHistory: false,
        ),
      );
    }
  }

  Future<void> refreshJobs() async {
    if (current.isLoadingJobs) return;
    state = AsyncData(
      current.copyWith(isLoadingJobs: true, jobErrorMessage: null),
    );
    final result = await _fetchJobs();
    if (isDisposed) return;
    state = AsyncData(
      current.copyWith(
        jobs: result.jobs,
        jobErrorMessage: result.errorMessage,
        isLoadingJobs: false,
      ),
    );
  }

  Future<ManualJobTriggerResponseDto> triggerJob(String taskKey) async {
    if (current.triggeringTaskKeys.contains(taskKey)) {
      throw StateError('job trigger already running');
    }
    state = AsyncData(
      current.copyWith(
        triggeringTaskKeys: <String>{...current.triggeringTaskKeys, taskKey},
      ),
    );
    try {
      final response = await ref
          .read(activityApiProvider)
          .triggerJob(taskKey: taskKey);
      if (!isDisposed) {
        state = AsyncData(
          current.copyWith(
            activeTab: ActivityTab.tasks,
            highlightedTaskRunId: response.taskRunId,
          ),
        );
        try {
          final bootstrap = await _fetchBootstrap(current.taskFilter);
          if (!isDisposed) {
            state = AsyncData(_applyBootstrap(current, bootstrap));
          }
        } catch (_) {}
      }
      return response;
    } on ApiException catch (error) {
      if (!isDisposed &&
          error.statusCode == 409 &&
          error.error?.code == 'task_conflict') {
        final blockingTaskRunId = asIntOrNull(
          error.error?.details?['blocking_task_run_id'],
        );
        if (blockingTaskRunId != null) {
          state = AsyncData(
            current.copyWith(
              activeTab: ActivityTab.tasks,
              highlightedTaskRunId: blockingTaskRunId,
            ),
          );
        }
      }
      rethrow;
    } finally {
      if (!isDisposed) {
        final keys = <String>{...current.triggeringTaskKeys}..remove(taskKey);
        state = AsyncData(current.copyWith(triggeringTaskKeys: keys));
      }
    }
  }

  Future<void> loadMoreTasks() async {
    final now = current;
    if (now.isLoadingMoreTasks ||
        now.isRefreshingTaskHistory ||
        !now.hasMoreTasks) {
      return;
    }
    state = AsyncData(
      now.copyWith(isLoadingMoreTasks: true, taskLoadMoreErrorMessage: null),
    );
    final filter = now.taskFilter;
    try {
      final response = await ref
          .read(activityApiProvider)
          .getTaskRuns(
            page: now.taskNextPage,
            pageSize: _pageSize,
            state: filter.state,
            taskKey: filter.taskKey,
            triggerType: filter.triggerType,
            sort: filter.sort.apiValue,
          );
      if (isDisposed) return;
      final tasks = _appendUniqueTasks(
        current.taskRuns,
        response.items,
        filter,
      );
      state = AsyncData(
        current.copyWith(
          taskRuns: tasks,
          taskNextPage: response.page + 1,
          hasMoreTasks: tasks.length < response.total,
          taskLoadMoreErrorMessage: null,
          isLoadingMoreTasks: false,
        ),
      );
    } catch (error) {
      if (isDisposed) return;
      state = AsyncData(
        current.copyWith(
          taskLoadMoreErrorMessage: apiErrorMessage(
            error,
            fallback: '加载更多任务失败，请点击重试',
          ),
          isLoadingMoreTasks: false,
        ),
      );
    }
  }

  Future<ActivityBootstrapDto> _fetchBootstrap(ActivityTaskFilterState filter) {
    return ref
        .read(activityApiProvider)
        .getBootstrap(
          taskState: filter.state,
          taskKey: filter.taskKey,
          taskTriggerType: filter.triggerType,
          taskSort: filter.sort.apiValue,
        );
  }

  Future<_JobsResult> _fetchJobs() async {
    try {
      return _JobsResult(jobs: await ref.read(activityApiProvider).getJobs());
    } catch (error) {
      return _JobsResult(
        jobs: const <JobMetadataDto>[],
        errorMessage: apiErrorMessage(error, fallback: '可执行任务加载失败，请重试'),
      );
    }
  }

  ActivityCenterState _applyBootstrap(
    ActivityCenterState base,
    ActivityBootstrapDto response,
  ) {
    _lastEventId = response.latestEventId;
    return base.copyWith(
      activeTaskRuns: response.activeTaskRuns,
      taskRuns: response.taskRuns.items,
      taskNextPage: response.taskRuns.page + 1,
      hasMoreTasks: response.taskRuns.items.length < response.taskRuns.total,
      taskLoadMoreErrorMessage: null,
      taskRefreshErrorMessage: null,
    );
  }

  Future<void> _connectStream() async {
    if (isDisposed) return;
    _cancelReconnectTimer();
    _cancelPollingTimer();
    state = AsyncData(
      current.copyWith(
        connectionState: ActivityConnectionState.connecting,
        connectionMessage: '正在连接实时活动流',
      ),
    );
    if (_disconnectStartedAt != null &&
        DateTime.now().difference(_disconnectStartedAt!) >
            _longDisconnectThreshold) {
      try {
        final bootstrap = await _fetchBootstrap(current.taskFilter);
        if (!isDisposed) state = AsyncData(_applyBootstrap(current, bootstrap));
      } catch (_) {}
    }
    if (isDisposed) return;
    final stream = ref
        .read(activityApiProvider)
        .streamEvents(afterEventId: _lastEventId);
    _eventSubscription = stream.listen(
      _handleStreamEvent,
      onError: _handleStreamError,
      onDone: _handleStreamDone,
      cancelOnError: false,
    );
    _reconnectAttempt = 0;
    _disconnectStartedAt = null;
    state = AsyncData(
      current.copyWith(
        connectionState: ActivityConnectionState.live,
        connectionMessage: '实时连接中',
      ),
    );
  }

  void _handleStreamEvent(ActivityStreamEvent event) {
    if (isDisposed) return;
    if (event.id != null && event.id! > _lastEventId) {
      _lastEventId = event.id!;
    }
    _pendingStreamEvents.add(event);
    if (_isStreamFlushScheduled) return;
    _isStreamFlushScheduled = true;
    scheduleMicrotask(_flushPendingStreamEvents);
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (isDisposed) return;
    if (error is ActivityEventStreamUnsupportedException) {
      _startPollingFallback();
      return;
    }
    _scheduleReconnect();
  }

  void _handleStreamDone() {
    if (isDisposed || current.isPollingFallback) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (isDisposed || current.isPollingFallback) return;
    _disconnectStartedAt ??= DateTime.now();
    state = AsyncData(
      current.copyWith(
        connectionState: ActivityConnectionState.reconnecting,
        connectionMessage: '实时连接已断开，正在重连',
      ),
    );
    final delay =
        _reconnectDelays[_reconnectAttempt.clamp(
          0,
          _reconnectDelays.length - 1,
        )];
    _reconnectAttempt += 1;
    _cancelReconnectTimer();
    _reconnectTimer = Timer(delay, () async {
      if (isDisposed) return;
      try {
        await _eventSubscription?.cancel();
        await _connectStream();
      } catch (error) {
        if (error is ActivityEventStreamUnsupportedException) {
          _startPollingFallback();
          return;
        }
        _scheduleReconnect();
      }
    });
  }

  void _startPollingFallback() {
    if (isDisposed) return;
    _resetPendingStreamEvents();
    _cancelReconnectTimer();
    state = AsyncData(
      current.copyWith(
        connectionState: ActivityConnectionState.polling,
        connectionMessage: '当前浏览器不支持实时连接，已切换为 30 秒轮询',
      ),
    );
    _cancelPollingTimer();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (isDisposed) return;
      try {
        final bootstrap = await _fetchBootstrap(current.taskFilter);
        if (!isDisposed) state = AsyncData(_applyBootstrap(current, bootstrap));
      } catch (_) {}
    });
  }

  void _flushPendingStreamEvents() {
    _isStreamFlushScheduled = false;
    if (isDisposed || _pendingStreamEvents.isEmpty) return;
    final events = List<ActivityStreamEvent>.from(_pendingStreamEvents);
    _pendingStreamEvents.clear();
    var next = current;
    var hasChanges = false;
    for (final event in events) {
      if (event.isHeartbeat) {
        const liveMessage = '实时连接中';
        if (next.connectionState != ActivityConnectionState.live ||
            next.connectionMessage != liveMessage) {
          next = next.copyWith(
            connectionState: ActivityConnectionState.live,
            connectionMessage: liveMessage,
          );
          hasChanges = true;
        }
        continue;
      }
      if (event.taskRun != null &&
          (event.isTaskRunCreated || event.isTaskRunUpdated)) {
        next = _upsertTaskRun(
          next,
          event.taskRun!,
          insertAtFront: event.isTaskRunCreated,
        );
        hasChanges = true;
      }
    }
    if (hasChanges && !isDisposed) state = AsyncData(next);
  }

  ActivityCenterState _upsertTaskRun(
    ActivityCenterState base,
    TaskRunDto taskRun, {
    bool insertAtFront = false,
  }) {
    return base.copyWith(
      activeTaskRuns: _upsertTaskInList(
        base.activeTaskRuns,
        taskRun,
        insertAtFront: insertAtFront,
        keepWhenMissing: taskRun.isActive,
        sorter: _sortActiveTasks,
      ),
      taskRuns: _upsertTaskInList(
        base.taskRuns,
        taskRun,
        insertAtFront: insertAtFront,
        keepWhenMissing: _matchesTaskFilter(taskRun, base.taskFilter),
        sorter: (items) => _sortHistoryTasks(items, base.taskFilter),
      ),
    );
  }

  List<TaskRunDto> _upsertTaskInList(
    List<TaskRunDto> currentItems,
    TaskRunDto next, {
    required bool insertAtFront,
    required bool keepWhenMissing,
    required List<TaskRunDto> Function(List<TaskRunDto>) sorter,
  }) {
    final items = List<TaskRunDto>.from(currentItems);
    final index = items.indexWhere((item) => item.id == next.id);
    if (index >= 0) {
      if (!keepWhenMissing) {
        items.removeAt(index);
      } else {
        items[index] = items[index].mergeFromServer(next);
      }
      return sorter(items);
    }
    if (!keepWhenMissing) return sorter(items);
    if (insertAtFront) {
      items.insert(0, next);
    } else {
      items.add(next);
    }
    return sorter(items);
  }

  bool _matchesTaskFilter(TaskRunDto item, ActivityTaskFilterState filter) {
    if (filter.state != null && filter.state != item.state) return false;
    if (filter.taskKey != null && filter.taskKey != item.taskKey) return false;
    if (filter.triggerType != null && filter.triggerType != item.triggerType) {
      return false;
    }
    return true;
  }

  List<TaskRunDto> _sortActiveTasks(List<TaskRunDto> items) {
    final sorted = items.where((item) => item.isActive).toList();
    sorted.sort((left, right) {
      final leftAt = left.startedAt?.millisecondsSinceEpoch ?? 0;
      final rightAt = right.startedAt?.millisecondsSinceEpoch ?? 0;
      return rightAt.compareTo(leftAt);
    });
    return sorted;
  }

  List<TaskRunDto> _sortHistoryTasks(
    List<TaskRunDto> items,
    ActivityTaskFilterState filter,
  ) {
    final sorted =
        items.where((item) => _matchesTaskFilter(item, filter)).toList();
    int timestampFor(TaskRunDto item) => switch (filter.sort) {
      ActivityTaskSort.startedAtDesc || ActivityTaskSort.startedAtAsc =>
        item.startedAt?.millisecondsSinceEpoch ?? 0,
      ActivityTaskSort.createdAtDesc || ActivityTaskSort.createdAtAsc =>
        item.createdAt?.millisecondsSinceEpoch ?? 0,
      ActivityTaskSort.updatedAtDesc || ActivityTaskSort.updatedAtAsc =>
        item.updatedAt?.millisecondsSinceEpoch ?? 0,
    };
    sorted.sort((left, right) {
      final leftValue = timestampFor(left);
      final rightValue = timestampFor(right);
      return switch (filter.sort) {
        ActivityTaskSort.startedAtDesc ||
        ActivityTaskSort.createdAtDesc ||
        ActivityTaskSort.updatedAtDesc => rightValue.compareTo(leftValue),
        _ => leftValue.compareTo(rightValue),
      };
    });
    return sorted;
  }

  List<TaskRunDto> _appendUniqueTasks(
    List<TaskRunDto> currentItems,
    List<TaskRunDto> incoming,
    ActivityTaskFilterState filter,
  ) {
    final next = List<TaskRunDto>.from(currentItems);
    for (final item in incoming) {
      if (next.any((existing) => existing.id == item.id)) continue;
      next.add(item);
    }
    return _sortHistoryTasks(next, filter);
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cancelPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _resetPendingStreamEvents() {
    _pendingStreamEvents.clear();
    _isStreamFlushScheduled = false;
  }

  bool get initialized => current.initialized;
  bool get isInitialLoading => state.isLoading || current.isInitialLoading;
  String? get initialErrorMessage => current.initialErrorMessage;
  ActivityTab get activeTab => current.activeTab;
  ActivityConnectionState get connectionState => current.connectionState;
  String? get connectionMessage => current.connectionMessage;
  ActivityTaskFilterState get taskFilter => current.taskFilter;
  List<TaskRunDto> get activeTaskRuns => current.activeTaskRuns;
  List<TaskRunDto> get taskRuns => current.taskRuns;
  List<JobMetadataDto> get jobs => current.jobs;
  bool get hasMoreTasks => current.hasMoreTasks;
  bool get isLoadingMoreTasks => current.isLoadingMoreTasks;
  bool get isLoadingJobs => current.isLoadingJobs;
  bool get isRefreshingTaskHistory => current.isRefreshingTaskHistory;
  String? get taskLoadMoreErrorMessage => current.taskLoadMoreErrorMessage;
  String? get jobErrorMessage => current.jobErrorMessage;
  String? get taskRefreshErrorMessage => current.taskRefreshErrorMessage;
  int? get highlightedTaskRunId => current.highlightedTaskRunId;
  bool isTriggeringJob(String taskKey) => current.isTriggeringJob(taskKey);
  bool get isPollingFallback => current.isPollingFallback;
  List<String> get knownTaskKeys => current.knownTaskKeys;
}

class _JobsResult {
  const _JobsResult({required this.jobs, this.errorMessage});

  final List<JobMetadataDto> jobs;
  final String? errorMessage;
}
