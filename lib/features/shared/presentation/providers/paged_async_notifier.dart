import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';

/// 分页列表状态的通用值对象：
/// - [items]：已加载的条目（累加）。
/// - [currentPage]：最近一次成功加载的页码；0 表示尚未加载。
/// - [total]：后端返回的总条数；用于计算 [hasMore]。
/// - [hasMore]：`items.length < total`；分页失败会保留原判定。
/// - [syncedAt]：整批数据的抓取时间（本地时区）；跟随最近一次成功响应更新。
/// - [isLoadingMore] / [loadMoreErrorMessage]：仅描述「下一页」加载态；
///   首次加载的 loading/error 由外层 [AsyncValue] 表达（[AsyncLoading]/[AsyncError]）。
///
/// 可空字段 [syncedAt] / [loadMoreErrorMessage] 的 [copyWith] 使用哨兵：
/// 省略参数 = 保持原值；显式传 `null` = 置空。
@immutable
class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.currentPage = 0,
    this.total = 0,
    this.hasMore = false,
    this.syncedAt,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
  });

  final List<T> items;
  final int currentPage;
  final int total;
  final bool hasMore;
  final DateTime? syncedAt;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// 首页响应直接组装为初始 State。
  factory PagedListState.fromFirstPage(PaginatedResponseDto<T> response) {
    return PagedListState<T>(
      items: List<T>.unmodifiable(response.items),
      currentPage: response.page,
      total: response.total,
      hasMore: response.items.length < response.total,
      syncedAt: response.syncedAt,
    );
  }

  PagedListState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? total,
    bool? hasMore,
    Object? syncedAt = _kSentinel,
    bool? isLoadingMore,
    Object? loadMoreErrorMessage = _kSentinel,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      syncedAt:
          identical(syncedAt, _kSentinel)
              ? this.syncedAt
              : syncedAt as DateTime?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreErrorMessage:
          identical(loadMoreErrorMessage, _kSentinel)
              ? this.loadMoreErrorMessage
              : loadMoreErrorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PagedListState<T> &&
        listEquals(other.items, items) &&
        other.currentPage == currentPage &&
        other.total == total &&
        other.hasMore == hasMore &&
        other.syncedAt == syncedAt &&
        other.isLoadingMore == isLoadingMore &&
        other.loadMoreErrorMessage == loadMoreErrorMessage;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    currentPage,
    total,
    hasMore,
    syncedAt,
    isLoadingMore,
    loadMoreErrorMessage,
  );
}

const Object _kSentinel = Object();

/// 筛选切换的视觉策略：
/// - [spinner]：切 [AsyncLoading]，列表清空显骨架（订阅/媒体管理走这条）；
/// - [preserveList]：保留旧 items + `isReloading: true`，只显示行内薄进度条
///   （downloads 走这条）。
enum FilterReloadStrategy { spinner, preserveList }

/// [PagedListState] 的局部补丁原语：事件/乐观更新后对已加载列表做**就地**
/// 修正，避免整页 invalidate 重拉。
///
/// 三个操作都保持不可变契约（新列表一律 `List.unmodifiable`）与其余分页字段
/// 不变（currentPage / syncedAt / isLoadingMore / loadMoreErrorMessage 原样
/// 透传）；只动 items / total / hasMore 三者中受影响的。
extension PagedListStatePatch<T> on PagedListState<T> {
  /// 移除所有匹配项：同步扣减 [PagedListState.total]（下限 0）并重算
  /// [PagedListState.hasMore]。无匹配时原样返回自身。
  PagedListState<T> removeWhere(bool Function(T) predicate) {
    final nextItems = items.where((item) => !predicate(item)).toList();
    if (nextItems.length == items.length) {
      return this;
    }
    final removed = items.length - nextItems.length;
    final nextTotal = (total - removed).clamp(0, 1 << 30).toInt();
    return copyWith(
      items: List<T>.unmodifiable(nextItems),
      total: nextTotal,
      hasMore: nextItems.length < nextTotal,
    );
  }

  /// 把**第一个**匹配项替换成 `update(item)` 的结果；不改 [PagedListState.total]
  /// / [PagedListState.hasMore]（条数未变）。无匹配时原样返回自身。
  PagedListState<T> patchWhere(
    bool Function(T) matches,
    T Function(T) update,
  ) {
    final index = items.indexWhere(matches);
    if (index < 0) {
      return this;
    }
    final nextItems = List<T>.of(items);
    nextItems[index] = update(items[index]);
    return copyWith(items: List<T>.unmodifiable(nextItems));
  }

  /// 前置 upsert：命中则替换第一个匹配项（条数不变，total/hasMore 不动）；
  /// 未命中则在**列表头部**插入 [item]，`total + 1` 并重算 [PagedListState.hasMore]。
  PagedListState<T> upsertFront(T item, {required bool Function(T) matches}) {
    final index = items.indexWhere(matches);
    if (index >= 0) {
      final nextItems = List<T>.of(items);
      nextItems[index] = item;
      return copyWith(items: List<T>.unmodifiable(nextItems));
    }
    final nextItems = List<T>.unmodifiable(<T>[item, ...items]);
    final nextTotal = total + 1;
    return copyWith(
      items: nextItems,
      total: nextTotal,
      hasMore: nextItems.length < nextTotal,
    );
  }
}

/// `$AsyncNotifier<S>` 的分页 mixin，把 `PagedLoadController` 的语义
/// 迁移到 Riverpod 侧。首例见 `features/media/presentation/providers/`。
///
/// 使用范式（S 中携带 [PagedListState<T>] 段 + 额外字段，如 filter/selection）：
///
/// ```dart
/// @Riverpod(keepAlive: true, retry: kNoAsyncNotifierRetry)
/// class MediaBrowse extends _$MediaBrowse
///     with PagedAsyncNotifierMixin<MediaBrowseState, MediaListItemDto> {
///   @override int get pageSize => 30;
///   @override String get initialLoadErrorText => '媒体列表加载失败，请稍后重试';
///   @override String get loadMoreErrorText => '加载更多媒体失败，请点击重试';
///
///   @override
///   PagedListState<MediaListItemDto> pagedOf(MediaBrowseState s) => s.paged;
///   @override
///   MediaBrowseState applyPaged(MediaBrowseState s, PagedListState<MediaListItemDto> p) =>
///       s.copyWith(paged: p);
///
///   @override
///   Future<PaginatedResponseDto<MediaListItemDto>> fetchPage(int page, int pageSize) =>
///       ref.read(mediaApiProvider).getMediaList(page: page, pageSize: pageSize, ...);
///
///   @override
///   Future<MediaBrowseState> build() async {
///     attachDisposeGuard();
///     final paged = await loadInitialPage();
///     return MediaBrowseState.initial.copyWith(paged: paged);
///   }
/// }
/// ```
///
/// 若 S 本身就是 `PagedListState<T>`（无额外字段），`pagedOf` / `applyPaged` 是恒等。
///
/// 生命周期与 `AsyncNotifier` 一致：首次加载态由外层 [AsyncLoading] 表达；成功后
/// State 内的 [PagedListState.items] 累加；loadMore 失败保留原列表 + 挂 error text；
/// 关闭 provider 自动重试（`AsyncNotifierProvider` 传 `retry: (_, __) => null`
/// 或 `@Riverpod(..., retry: kNoAsyncNotifierRetry)`）避免失败态里 `build()` 打爆后端。
mixin PagedAsyncNotifierMixin<S, T> on $AsyncNotifier<S> {
  bool _disposed = false;

  /// 「首页重置」代次：每次 [reload] / [refresh] 开始时 +1。
  /// 正在飞的 [loadMore] 在 await 返回后若发现代次已变，即视为结果作废、
  /// 不再写回 State——避免用旧 `paged.items` 覆盖 reload 后的新首页。
  int _generation = 0;

  @protected
  bool get isDisposed => _disposed;

  @protected
  int get initialPage => 1;

  @protected
  int get pageSize;

  @protected
  String get initialLoadErrorText;

  @protected
  String get loadMoreErrorText;

  @protected
  Future<PaginatedResponseDto<T>> fetchPage(int page, int pageSize);

  /// 从 S 里取出 [PagedListState] 段。
  @protected
  PagedListState<T> pagedOf(S state);

  /// 把新的 [PagedListState] 应用回 S。
  @protected
  S applyPaged(S state, PagedListState<T> paged);

  /// 必须在 `build()` 首行调用；防 dispose 后 `state = ...` 静默失败或抛错。
  @protected
  void attachDisposeGuard() {
    ref.onDispose(() => _disposed = true);
  }

  /// 让**当前正在飞的 [loadMore]** 视为过期结果（回来后不再写回 State）。
  ///
  /// 子类在自定义「重置首页」路径（比如筛选切换想要保留旧 items + 展示轻量
  /// LinearProgressIndicator 而不走 [reload] 的 AsyncLoading 分支）时，
  /// 在**开始拉取新第一页之前**调用一次，避免旧 loadMore 覆盖新首页。
  @protected
  void invalidateInFlightLoadMore() {
    _generation++;
  }

  /// 抓第一页并构造 [PagedListState]。抛出交给 [AsyncNotifier] 自动转 [AsyncError]。
  @protected
  Future<PagedListState<T>> loadInitialPage() async {
    final response = await fetchPage(initialPage, pageSize);
    return PagedListState<T>.fromFirstPage(response);
  }

  /// 强制重新加载：切 [AsyncLoading] → 拉第一页 → 覆盖回 State。
  ///
  /// 若子类要在 reload 前对 S 打补丁（如清空多选/清空辅助集合），传 [updateBaseState]。
  /// 尚未成功 build 时（还在 loading / 初次失败）走 `ref.invalidateSelf()`。
  Future<void> reload({S Function(S current)? updateBaseState}) async {
    _generation++;
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      try {
        await future;
      } catch (_) {
        // 已切 AsyncError，UI 侧展示错误；这里吞异常避免污染调用点。
      }
      return;
    }
    final baseState =
        updateBaseState != null ? updateBaseState(current) : current;
    state = AsyncLoading<S>();
    final next = await AsyncValue.guard<S>(() async {
      final firstPage = await loadInitialPage();
      return applyPaged(baseState, firstPage);
    });
    if (!_disposed) {
      state = next;
    }
  }

  /// 保留态刷新：不切 loading；失败返回中文错误消息由页面 toast。
  ///
  /// 子类可覆写以在刷新前清辅助集合（如 `_deleteEnabledMediaIds`），例如：
  /// ```dart
  /// @override
  /// Future<String?> refresh() async {
  ///   final current = state.value;
  ///   if (current != null) {
  ///     state = AsyncData(current.copyWith(deleteEnabledMediaIds: const {}));
  ///   }
  ///   return super.refresh();
  /// }
  /// ```
  Future<String?> refresh() async {
    final current = state.value;
    if (current == null) {
      await reload();
      return null;
    }
    if (pagedOf(current).isLoadingMore) {
      return null;
    }
    _generation++;
    try {
      final response = await fetchPage(initialPage, pageSize);
      if (_disposed) return null;
      final currentAfter = state.value ?? current;
      state = AsyncData(
        applyPaged(currentAfter, PagedListState<T>.fromFirstPage(response)),
      );
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: initialLoadErrorText);
    }
  }

  /// 加载下一页。未 build / 已在加载 / 无更多时短路。
  /// 失败保留原列表并把 [loadMoreErrorText] 写进 State。
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    final paged = pagedOf(current);
    if (paged.isLoadingMore || !paged.hasMore) return;

    // 抢占当前代次；reload / refresh 期间飞出去的响应用它来判「已作废」。
    final generation = _generation;

    state = AsyncData(
      applyPaged(
        current,
        paged.copyWith(isLoadingMore: true, loadMoreErrorMessage: null),
      ),
    );

    try {
      final response = await fetchPage(paged.currentPage + 1, pageSize);
      if (_disposed || generation != _generation) return;
      // 合并基线取 await **之后**的分页态，不是入口处的 `paged` 快照：await 期间
      // mutation 广播可能已对 items 做过就地补丁（取消订阅摘行、删除等），拿旧快照
      // 整体覆盖会把补丁抹掉、让数据短暂回退。失败分支一直是这么写的，这里对齐。
      final currentAfter = state.value ?? current;
      final pagedAfter = pagedOf(currentAfter);
      final merged = List<T>.unmodifiable(<T>[
        ...pagedAfter.items,
        ...response.items,
      ]);
      state = AsyncData(
        applyPaged(
          currentAfter,
          pagedAfter.copyWith(
            items: merged,
            currentPage: response.page,
            total: response.total,
            syncedAt: response.syncedAt,
            hasMore: merged.length < response.total,
            isLoadingMore: false,
            loadMoreErrorMessage: null,
          ),
        ),
      );
    } catch (_) {
      if (_disposed || generation != _generation) return;
      final currentAfter = state.value ?? current;
      final currentPaged = pagedOf(currentAfter);
      state = AsyncData(
        applyPaged(
          currentAfter,
          currentPaged.copyWith(
            isLoadingMore: false,
            loadMoreErrorMessage: loadMoreErrorText,
            hasMore: currentPaged.items.length < currentPaged.total,
          ),
        ),
      );
    }
  }
}

/// 筛选驱动分页 mixin：统一「值对象筛选状态 → reload/preserveList」两套切换语义。
/// 现有 adopter：movies / actors / videos / clips / moments / hot_reviews 六个
/// listing 域。订阅管理 / 媒体管理 / downloads / resource task center 仍各自手写
/// 筛选切换（downloads 因 SSE 合并等额外语义未收编）——**改本 mixin 的切换语义
/// （如清 isLoadingMore 的死锁修复）时，这几处手写副本要同步对齐**。
///
/// 约定：`F` 是不可变值对象（`==` 即"筛选未变"）；`fetchPage` 从 [activeFilter]
/// 读参数；UI 改筛选后调 [applyFilterState]。State 里的 filter 字段由
/// [applyFilterToState] 负责写入（连带清多选等副作用）。
///
/// ```dart
/// @Riverpod(keepAlive: true, retry: kNoAsyncNotifierRetry)
/// class MediaBrowse extends _$MediaBrowse
///     with PagedAsyncNotifierMixin<MediaBrowseState, MediaListItemDto>,
///          FilterablePagedAsyncNotifierMixin<MediaBrowseState, MediaListItemDto, MediaBrowseFilterState> {
///   @override
///   MediaBrowseFilterState get initialFilter => MediaBrowseFilterState.initial;
///
///   @override
///   MediaBrowseState applyFilterToState(MediaBrowseState s, MediaBrowseFilterState filter) =>
///       s.copyWith(filter: filter, selectedIds: const <int>{});
///
///   @override
///   Future<MediaBrowseState> build() async {
///     attachDisposeGuard();
///     final paged = await loadInitialPage();
///     return MediaBrowseState(paged: paged, filter: activeFilter);
///   }
/// }
/// ```
mixin FilterablePagedAsyncNotifierMixin<S, T, F>
    on PagedAsyncNotifierMixin<S, T> {
  /// 首次 build 的默认筛选。
  @protected
  F get initialFilter;

  late F _activeFilter = initialFilter;

  /// 当前生效的筛选；`fetchPage` 从它读参数拼请求。
  @protected
  F get activeFilter => _activeFilter;

  /// 把新筛选值写进 State（连带清多选等副作用）。注意把 filter 字段本身也写入。
  @protected
  S applyFilterToState(S state, F filter);

  /// 切换筛选的视觉策略，默认 [FilterReloadStrategy.spinner]。
  @protected
  FilterReloadStrategy get filterReloadStrategy =>
      FilterReloadStrategy.spinner;

  /// [FilterReloadStrategy.preserveList] 策略要求实现：写 `isReloading` 标志
  /// （`reloading: true` 显示行内薄进度条）。默认返回原状态。
  @protected
  S copyWithReloading(S state, bool reloading) => state;

  /// 应用新筛选状态。值对象相等则短路（不发请求）；否则按
  /// [filterReloadStrategy] 触发 reload / preserveList 重拉第一页。
  Future<void> applyFilterState(F next) async {
    if (_activeFilter == next) return;
    _activeFilter = next;

    switch (filterReloadStrategy) {
      case FilterReloadStrategy.spinner:
        await reload(updateBaseState: (s) => applyFilterToState(s, next));
      case FilterReloadStrategy.preserveList:
        await _applyPreserveList(next);
    }
  }

  /// preserveList：保留旧 items + 顶部薄进度条 → 拉第一页 → 复位。
  /// 失败：items 保留、`isReloading` 复位（filter 已更新，用户可再触发重试），
  /// 然后**原样抛出**，由调用方决定是否 toast。
  Future<void> _applyPreserveList(F next) async {
    final current = state.value;
    if (current == null) {
      // 尚未 build 完成，走 reload 兜底。
      await reload(updateBaseState: (s) => applyFilterToState(s, next));
      return;
    }

    invalidateInFlightLoadMore();
    // 若当前挂着 in-flight loadMore（isLoadingMore: true），先显式清掉再写
    // 新 State——被代次作废的 loadMore 失败/成功后都不会再回写，不清会永远
    // 卡在 loading 态、loadMore 再也触发不了（死锁）。
    final currentPaged = pagedOf(current);
    final base = currentPaged.isLoadingMore
        ? applyPaged(
            current,
            currentPaged.copyWith(
              isLoadingMore: false,
              loadMoreErrorMessage: null,
            ),
          )
        : current;
    state = AsyncData(copyWithReloading(applyFilterToState(base, next), true));

    try {
      final firstPage = await loadInitialPage();
      if (isDisposed) return;
      final now = state.value ?? current;
      state = AsyncData(copyWithReloading(applyPaged(now, firstPage), false));
    } catch (error) {
      if (isDisposed) return;
      final now = state.value ?? current;
      state = AsyncData(copyWithReloading(now, false));
      rethrow;
    }
  }
}
