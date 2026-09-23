import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/downloads/presentation/download_task_filter_state.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/download_task_center_state.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/providers/session_scoped_invalidation.dart';

part 'download_task_center_provider.g.dart';

/// 下载任务中心：列表快照轮询 + 删除。
@Riverpod(keepAlive: true, retry: kNoAsyncNotifierRetry)
class DownloadTaskCenter extends _$DownloadTaskCenter
    with
        PagedAsyncNotifierMixin<DownloadTaskCenterState, DownloadTaskRowState> {
  static const int _pageSize = 20;
  static const Duration _pollingInterval = Duration(seconds: 30);

  DownloadTaskFilterState _activeFilter = DownloadTaskFilterState.initial;
  late final DebouncedLatestRequest _filterRequests = DebouncedLatestRequest();
  Timer? _pollTimer;
  bool _pollRequested = false;
  bool _pollingEnabled = true;
  int _filterGeneration = 0;
  List<DownloadClientOption>? _pendingClientOptions;
  Map<int, String>? _pendingClientNames;

  @override
  int get pageSize => _pageSize;

  @override
  String get initialLoadErrorText => '下载任务加载失败，请稍后重试';

  @override
  String get loadMoreErrorText => '加载更多失败，请点击重试';

  @override
  PagedListState<DownloadTaskRowState> pagedOf(DownloadTaskCenterState s) =>
      s.paged;

  @override
  DownloadTaskCenterState applyPaged(
    DownloadTaskCenterState s,
    PagedListState<DownloadTaskRowState> paged,
  ) => s.copyWith(paged: paged);

  @override
  Object? itemKeyOf(DownloadTaskRowState item) => item.task.id;

  @override
  Future<PaginatedResponseDto<DownloadTaskRowState>> fetchPage(
    int page,
    int pageSize,
  ) async {
    final filter = _activeFilter;
    final response = await ref
        .read(downloadsApiProvider)
        .getDownloadTasks(
          page: page,
          pageSize: pageSize,
          clientId: filter.clientId,
          movieNumber: filter.normalizedSearch.isEmpty
              ? null
              : filter.normalizedSearch,
          states: filter.stateFilter.apiValues,
          sort: 'created_at:desc',
        );
    return PaginatedResponseDto<DownloadTaskRowState>(
      items: response.items
          .map((task) => DownloadTaskRowState(task: task))
          .toList(growable: false),
      page: response.page,
      pageSize: response.pageSize,
      total: response.total,
      syncedAt: response.syncedAt,
    );
  }

  @override
  Future<DownloadTaskCenterState> build() async {
    invalidateOnSignOut(ref);
    attachDisposeGuard();
    ref.onDispose(() {
      _pollTimer?.cancel();
      // cancel 而不是 dispose：provider 重建（invalidate）也会执行这里注册的
      // onDispose，dispose 会把协调器永久标记为已销毁，重建后的筛选请求再也写不回。
      _filterRequests.cancel();
    });
    unawaited(_loadClientOptionsInBackground());
    final paged = await loadInitialPage();
    final result = _mergePendingClientData(
      DownloadTaskCenterState.initial.copyWith(
        paged: paged,
        filter: _activeFilter,
      ),
    );
    if (_pollRequested && _pollingEnabled && !isDisposed) _beginPolling();
    return result;
  }

  @override
  Future<String?> refresh() async {
    await retryFilter();
    return state.value?.paged.filterUpdate.errorMessage;
  }

  Future<void> applyFilter(DownloadTaskFilterState next) {
    if (_activeFilter == next) return Future<void>.value();
    _activeFilter = next;
    _filterGeneration++;
    final current = state.value;
    if (current == null) return _filterRequests.schedule(_loadSelectedFilter);
    invalidateInFlightLoadMore();
    state = AsyncData(
      current.copyWith(
        filter: next,
        paged: current.paged.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: null,
          filterUpdate: const FilterUpdateState.waiting(),
        ),
      ),
    );
    return _filterRequests.schedule(_loadSelectedFilter);
  }

  Future<void> retryFilter() {
    final current = state.value;
    if (current != null) {
      invalidateInFlightLoadMore();
      state = AsyncData(
        current.copyWith(
          paged: current.paged.copyWith(
            isLoadingMore: false,
            loadMoreErrorMessage: null,
            filterUpdate: const FilterUpdateState.loading(),
          ),
        ),
      );
    }
    return _filterRequests.runNow(_loadSelectedFilter);
  }

  Future<void> _loadSelectedFilter(int requestId) async {
    final current = state.value;
    if (current == null) {
      await super.reload();
      return;
    }
    if (isDisposed || !_filterRequests.isCurrent(requestId)) return;
    state = AsyncData(
      current.copyWith(
        paged: current.paged.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: null,
          filterUpdate: const FilterUpdateState.loading(),
        ),
      ),
    );
    try {
      final firstPage = await loadInitialPage();
      if (isDisposed || !_filterRequests.isCurrent(requestId)) return;
      final current = state.value;
      if (current != null)
        state = AsyncData(current.copyWith(paged: firstPage));
    } catch (error) {
      if (isDisposed || !_filterRequests.isCurrent(requestId)) return;
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            paged: current.paged.copyWith(
              filterUpdate: FilterUpdateState.failed(
                apiErrorMessage(error, fallback: '筛选结果更新失败，请重试'),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Future<void> loadMore() {
    final current = state.value;
    if (current != null && !current.paged.filterUpdate.isIdle) {
      return Future<void>.value();
    }
    return super.loadMore();
  }

  /// 页面进入下载任务 tab 时开始快照轮询。
  Future<void> startPolling() async {
    _pollRequested = true;
    if (isDisposed || !_pollingEnabled || state.value == null) return;
    _beginPolling();
    await _pollSnapshot();
  }

  void stopPolling() {
    _pollRequested = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _setPollingState(DownloadTaskPollingState.idle);
  }

  /// 暂停页面不可见期间的下载快照轮询，但保留当前筛选和轮询请求意图。
  void pausePolling() {
    _pollingEnabled = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _setPollingState(DownloadTaskPollingState.idle);
  }

  /// 恢复页面可见后的下载快照轮询；只有下载 tab 原本已请求轮询时才重新同步。
  Future<void> resumePolling() async {
    if (_pollingEnabled) return;
    _pollingEnabled = true;
    if (!_pollRequested || isDisposed || state.value == null) return;
    _beginPolling();
    await _pollSnapshot();
  }

  void _beginPolling() {
    if (isDisposed || !_pollRequested || !_pollingEnabled) return;
    _pollTimer?.cancel();
    _setPollingState(DownloadTaskPollingState.polling);
    _pollTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(_pollSnapshot());
    });
  }

  Future<void> _pollSnapshot() async {
    if (isDisposed ||
        !_pollRequested ||
        !_pollingEnabled ||
        state.value == null) {
      return;
    }
    final generation = _filterGeneration;
    try {
      final firstPage = await fetchPage(1, _pageSize);
      if (isDisposed ||
          !_pollRequested ||
          !_pollingEnabled ||
          generation != _filterGeneration) {
        return;
      }
      final current = state.value;
      if (current == null || !current.paged.filterUpdate.isIdle) return;
      if (current.paged.currentPage > 1) {
        // 已翻页：只按 task id 就地刷新首页条目的进度/状态，保留已加载的后续页。
        // 整体替换会把列表截回第一页，并与飞行中的 loadMore 错位——它的响应会
        // 带着旧页码写回，导致 currentPage 越界后反复请求空页、底部转圈不消失。
        state = AsyncData(
          current.copyWith(
            pollingState: DownloadTaskPollingState.polling,
            paged: _patchLoadedRows(current.paged, firstPage),
          ),
        );
        return;
      }
      // 未翻页：快照整体替换，并让飞行中的 loadMore 作废，避免旧页码结果写回。
      invalidateInFlightLoadMore();
      state = AsyncData(
        current.copyWith(
          pollingState: DownloadTaskPollingState.polling,
          paged: PagedListState<DownloadTaskRowState>.fromFirstPage(firstPage),
        ),
      );
    } catch (_) {
      // 保留最近一次列表快照，下一轮或手动刷新继续尝试。
    }
  }

  /// 已翻页时的轮询合并：按 task id 就地更新已加载条目的进度/状态，
  /// 不增删条目、不重置 currentPage/hasMore/total，避免打断用户分页。
  PagedListState<DownloadTaskRowState> _patchLoadedRows(
    PagedListState<DownloadTaskRowState> current,
    PaginatedResponseDto<DownloadTaskRowState> firstPage,
  ) {
    final freshById = <int, DownloadTaskRowState>{
      for (final row in firstPage.items) row.task.id: row,
    };
    if (freshById.isEmpty) return current;
    final patched = <DownloadTaskRowState>[
      for (final row in current.items) freshById[row.task.id] ?? row,
    ];
    return current.copyWith(
      items: List<DownloadTaskRowState>.unmodifiable(patched),
      syncedAt: firstPage.syncedAt,
    );
  }

  Future<void> deleteTask(int taskId, {required bool deleteFiles}) async {
    final current = state.value;
    if (current == null || current.isTaskPending(taskId)) return;
    _addPending(taskId);
    try {
      await ref
          .read(downloadsApiProvider)
          .deleteDownloadTask(taskId, deleteFiles: deleteFiles);
      if (!isDisposed) _removeItemById(taskId);
    } finally {
      _removePending(taskId);
    }
  }

  /// 重新触发下载任务的导入，并立刻拉一次快照让卡片转入「导入中」。
  Future<void> triggerImport(int taskId) async {
    final current = state.value;
    if (current == null || current.isTaskPending(taskId)) return;
    _addPending(taskId);
    try {
      await ref.read(downloadsApiProvider).triggerDownloadTaskImport(taskId);
      await _pollSnapshot();
    } finally {
      _removePending(taskId);
    }
  }

  Future<void> _loadClientOptionsInBackground() async {
    try {
      final clients = await ref.read(downloadClientsApiProvider).getClients();
      if (isDisposed) return;
      final options = clients
          .map(
            (client) => DownloadClientOption(id: client.id, name: client.name),
          )
          .toList(growable: false);
      final names = <int, String>{};
      for (final client in clients) {
        names[client.id] = client.name;
      }
      final current = state.value;
      if (current == null) {
        _pendingClientOptions = options;
        _pendingClientNames = names;
      } else {
        state = AsyncData(
          current.copyWith(clientOptions: options, clientNames: names),
        );
      }
    } catch (_) {}
  }

  DownloadTaskCenterState _mergePendingClientData(
    DownloadTaskCenterState value,
  ) {
    final options = _pendingClientOptions;
    final names = _pendingClientNames;
    if (options == null || names == null) return value;
    _pendingClientOptions = null;
    _pendingClientNames = null;
    return value.copyWith(clientOptions: options, clientNames: names);
  }

  void _removeItemById(int taskId) {
    final current = state.value;
    if (current == null) return;
    final next = current.paged.items
        .where((row) => row.task.id != taskId)
        .toList(growable: false);
    if (next.length == current.paged.items.length) return;
    final total = current.paged.total > 0 ? current.paged.total - 1 : 0;
    state = AsyncData(
      current.copyWith(
        paged: current.paged.copyWith(
          items: List.unmodifiable(next),
          total: total,
          hasMore: next.length < total,
        ),
      ),
    );
  }

  void _addPending(int taskId) {
    final current = state.value;
    if (current == null) return;
    final ids = Set<int>.of(current.pendingActionTaskIds)..add(taskId);
    state = AsyncData(current.copyWith(pendingActionTaskIds: ids));
  }

  void _removePending(int taskId) {
    if (isDisposed) return;
    final current = state.value;
    if (current == null) return;
    final ids = Set<int>.of(current.pendingActionTaskIds)..remove(taskId);
    state = AsyncData(current.copyWith(pendingActionTaskIds: ids));
  }

  void _setPollingState(DownloadTaskPollingState value) {
    final current = state.value;
    if (current == null || current.pollingState == value) return;
    state = AsyncData(current.copyWith(pollingState: value));
  }
}
