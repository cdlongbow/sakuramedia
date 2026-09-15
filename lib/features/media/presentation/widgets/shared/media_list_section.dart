import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/media_browse_filter_state.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_browse_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/media_browse_filter_toolbar.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_card.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_result_loading_overlay.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart'
    show AppFilterPanelFooter;

/// 「媒体管理」列表 tab 的主体：筛选头 + 白底 media card 列表（桌面 / 移动共用）。
///
/// 数据源：`mediaBrowseProvider` + `mediaLibrariesProvider`。多选、筛选、reload 全部
/// 由内部 `ref.read(...notifier)` 触发；父页只提供跨 provider 的批量操作与复合刷新。
///
/// 平台差异（`mobile: true` 时启用）：
/// - 行卡片：桌面 / 移动均使用 [MediaListItemCard]（移动端长按进入多选态）；
/// - 筛选入口：桌面 popover 工具栏 / 移动底部抽屉（`MediaBrowseFilterSectionGroup` 复用）；
/// - 多选：桌面顶栏按钮流 / 移动 `AppListHeader.selection`（顶）+ `AppSelectionBottomBar`（底）。
///
/// 视觉参考「下载任务」卡片（[_DownloadTaskCard]）：页面灰底 + 每张 media card 直接浮起
/// 为独立白卡（不再套 `AppContentCard`）。多选操作全部收敛到顶部 [AppFilterTotalHeader]
/// 的 trailing，跟筛选、总数、刷新同一条行。
class MediaListSection extends StatelessWidget {
  const MediaListSection({
    super.key,
    required this.scrollController,
    required this.isDeleting,
    required this.isTransferring,
    required this.onBatchDelete,
    required this.onBatchTransfer,
    this.isResettingThumbnails = false,
    this.onBatchResetThumbnails,
    this.onRefresh,
    this.onOpenMovieDetail,
    this.keyPrefix = 'media-management',
    this.mobile = false,
    this.selectionMode = false,
    this.onEnterSelection,
    this.onExitSelection,
    this.onDeleteItem,
    this.deletingItemId,
    this.onRetryThumbnails,
    this.retryingThumbnailMediaId,
  });

  final ScrollController scrollController;

  /// 批量操作进行中——按钮 spinner + 禁用其它多选动作。
  final bool isDeleting;

  final bool isTransferring;

  /// 父页批量删除入口：弹二次确认 → 串行循环 `mediaApi.deleteMedia` → 汇总 toast。
  final Future<void> Function() onBatchDelete;

  final Future<void> Function() onBatchTransfer;

  final bool isResettingThumbnails;

  final Future<void> Function()? onBatchResetThumbnails;

  /// 可选：父页复合刷新；不传则默认刷新媒体列表 + 媒体库。
  final Future<void> Function()? onRefresh;

  /// 可选：媒体封面点击跳影片详情（JAV 项）；不传则封面不可点。
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;

  /// 测试 Key 前缀：桌面 `media-management`，移动 `mobile-media-management`。
  final String keyPrefix;

  /// 移动端布局开关：流式行卡 + 底部抽屉筛选 + 多选态工具栏/底部操作条。
  final bool mobile;

  /// 多选态（移动端长按进入后为 true）：行卡切换为点选、顶栏换选择工具栏、
  /// 列表底部追加批量操作条。
  final bool selectionMode;

  /// 移动端长按行进入多选态；桌面端不用。
  final VoidCallback? onEnterSelection;

  /// 移动端退出多选态（清空选择由本组件内部调 provider）；桌面端不用。
  final VoidCallback? onExitSelection;

  /// 单项删除入口；不传时不显示卡片级删除按钮。
  final Future<void> Function(MediaListItemDto item)? onDeleteItem;

  /// 当前正在删除的媒体 ID，用于只显示对应卡片的 loading。
  final ValueListenable<int?>? deletingItemId;

  /// 单项缩略图重试入口；不传时不显示卡片级重试按钮。
  final Future<void> Function(MediaListItemDto item)? onRetryThumbnails;

  /// 当前正在重试缩略图的媒体 ID，用于只显示对应卡片的 loading。
  final ValueListenable<int?>? retryingThumbnailMediaId;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      key: Key('$keyPrefix-list-scroll-view'),
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: context.appSpacing.lg)),
        _MediaListBodySliver(
          keyPrefix: keyPrefix,
          mobile: mobile,
          selectionMode: selectionMode,
          onEnterSelection: onEnterSelection,
          onOpenMovieDetail: onOpenMovieDetail,
          isDeleting: isDeleting,
          isTransferring: isTransferring,
          isResettingThumbnails: isResettingThumbnails,
          onDeleteItem: onDeleteItem,
          deletingItemId: deletingItemId,
          onRetryThumbnails: onRetryThumbnails,
          retryingThumbnailMediaId: retryingThumbnailMediaId,
        ),
      ],
    );
    final resultView = Consumer(
      builder: (context, ref, _) {
        final paged = ref.watch(
          mediaBrowseProvider.select((asyncState) => asyncState.value?.paged),
        );
        return AppFixedHeaderLayout(
          header: _MediaListHeader(
            keyPrefix: keyPrefix,
            mobile: mobile,
            selectionMode: selectionMode,
            isDeleting: isDeleting,
            isTransferring: isTransferring,
            onBatchDelete: onBatchDelete,
            onBatchTransfer: onBatchTransfer,
            isResettingThumbnails: isResettingThumbnails,
            onBatchResetThumbnails: onBatchResetThumbnails,
            onRefresh: onRefresh,
            onExitSelection: onExitSelection,
          ),
          child: AppFilterResultLoadingOverlay(
            isLoading: paged?.filterUpdate.isLoading ?? false,
            hasPreviousItems: paged?.items.isNotEmpty ?? false,
            child: scrollView,
          ),
        );
      },
    );

    // 移动端多选态：列表下方常驻批量操作条。
    if (mobile && selectionMode) {
      return Column(
        children: [
          Expanded(child: resultView),
          _MediaMobileSelectionBar(
            keyPrefix: keyPrefix,
            isDeleting: isDeleting,
            isTransferring: isTransferring,
            isResettingThumbnails: isResettingThumbnails,
            onBatchDelete: onBatchDelete,
            onBatchTransfer: onBatchTransfer,
            onBatchResetThumbnails: onBatchResetThumbnails,
          ),
        ],
      );
    }
    return resultView;
  }
}

class _MediaListHeader extends ConsumerWidget {
  const _MediaListHeader({
    required this.keyPrefix,
    required this.mobile,
    required this.selectionMode,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.onBatchDelete,
    required this.onBatchTransfer,
    required this.onBatchResetThumbnails,
    required this.onRefresh,
    required this.onExitSelection,
  });

  final String keyPrefix;
  final bool mobile;
  final bool selectionMode;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final Future<void> Function() onBatchDelete;
  final Future<void> Function() onBatchTransfer;
  final Future<void> Function()? onBatchResetThumbnails;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onExitSelection;

  Future<void> _defaultRefresh(WidgetRef ref) async {
    await Future.wait<void>([_refreshBrowse(ref), _refreshLibraries(ref)]);
  }

  Future<void> _refreshBrowse(WidgetRef ref) async {
    final message = await ref.read(mediaBrowseProvider.notifier).refresh();
    if (message != null) showToast(message);
  }

  Future<void> _refreshLibraries(WidgetRef ref) async {
    final message = await ref.read(mediaLibrariesProvider.notifier).refresh();
    if (message != null) showToast(message);
  }

  void _applyFilter(WidgetRef ref, MediaBrowseFilterState next) {
    unawaited(ref.read(mediaBrowseProvider.notifier).applyFilterState(next));
  }

  void _resetFilter(WidgetRef ref) {
    unawaited(
      ref
          .read(mediaBrowseProvider.notifier)
          .applyFilterState(MediaBrowseFilterState.initial),
    );
  }

  Future<void> _openMobileFilterDrawer(
    BuildContext context, {
    required MediaBrowseFilterState filter,
    required List<MediaLibraryDto> libraries,
    required WidgetRef ref,
  }) {
    return showAppBottomDrawer(
      context: context,
      drawerKey: Key('$keyPrefix-filter-drawer'),
      heightFactor: 0.8,
      builder: (_) => _MediaListMobileFilterDrawerContent(
        initial: filter,
        libraries: libraries,
        onChanged: (next) => _applyFilter(ref, next),
        scrollViewKey: Key('$keyPrefix-filter-scroll-view'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mediaBrowseProvider);
    final librariesAsync = ref.watch(mediaLibrariesProvider);
    final librariesState = librariesAsync.value ?? MediaLibrariesState.empty;

    final currentState = asyncState.value;
    final total = currentState?.paged.total ?? 0;
    final selectionCount = currentState?.selectionCount ?? 0;
    final hasSelection = selectionCount > 0;
    final hasItems =
        currentState != null && currentState.paged.items.isNotEmpty;
    final filter = currentState?.filter ?? MediaBrowseFilterState.initial;
    final isInitialLoading = asyncState.isLoading && !asyncState.hasValue;
    final busy = isDeleting || isTransferring || isResettingThumbnails;
    final allLoadedSelected = currentState?.allLoadedSelected ?? false;

    // 移动端多选态：顶栏换 `AppListHeader.selection`（退出 / 计数 / 全选），
    // 与 PornBox / 订阅列表的多选顶栏同一套组件；高度与常规顶栏严格一致。
    if (mobile && selectionMode) {
      return AppListHeader.selection(
        key: Key('$keyPrefix-selection-header'),
        selectionLabel: '已选 $selectionCount 项',
        selectionExitButtonKey: Key('$keyPrefix-exit-selection-button'),
        onExitSelection: () {
          ref.read(mediaBrowseProvider.notifier).clearSelection();
          onExitSelection?.call();
        },
        actionSlots: [
          AppTextButton(
            key: Key('$keyPrefix-select-all-button'),
            label: allLoadedSelected ? '取消全选本页' : '全选本页',
            size: AppTextButtonSize.small,
            onPressed: !hasItems || busy
                ? null
                : () => ref
                      .read(mediaBrowseProvider.notifier)
                      .toggleSelectAllLoaded(),
          ),
        ],
      );
    }

    // 移动端非多选态：筛选入口（开底部抽屉）+ 总数 + 刷新，用双端共用的
    // AppListHeader（常规态与多选态由同一个组件原地切换）。
    if (mobile) {
      return AppListHeader(
        key: Key('$keyPrefix-header'),
        onFilterTap: () => _openMobileFilterDrawer(
          context,
          filter: filter,
          libraries: librariesState.libraries,
          ref: ref,
        ),
        filterLabel: filter.triggerLabel,
        filterButtonKey: Key('$keyPrefix-filter-trigger'),
        filterTooltip: '筛选',
        filterUpdate:
            currentState?.paged.filterUpdate ?? const FilterUpdateState.idle(),
        hasPreviousFilterItems: hasItems,
        onRetryFilter: () =>
            unawaited(ref.read(mediaBrowseProvider.notifier).retryFilter()),
        informationSlots: [
          AppListHeaderInfo(
            key: Key('$keyPrefix-total-text'),
            label: '共 $total 条',
          ),
        ],
        actionSlots: [
          AppIconButton(
            key: Key('$keyPrefix-refresh-button'),
            tooltip: isInitialLoading ? '刷新中' : '刷新',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isInitialLoading
                ? null
                : () {
                    unawaited((onRefresh ?? () => _defaultRefresh(ref))());
                  },
          ),
        ],
      );
    }

    return AppFilterTotalHeader(
      leading: MediaBrowseFilterToolbar(
        filterState: filter,
        libraries: librariesState.libraries,
        onChanged: (next) => _applyFilter(ref, next),
        onReset: () => _resetFilter(ref),
      ),
      totalText: hasSelection
          ? '共 $total 条 · 已选 $selectionCount 项'
          : '共 $total 条',
      totalKey: const Key('media-management-total-text'),
      filterUpdate:
          currentState?.paged.filterUpdate ?? const FilterUpdateState.idle(),
      hasPreviousFilterItems: hasItems,
      onRetryFilter: () =>
          unawaited(ref.read(mediaBrowseProvider.notifier).retryFilter()),
      trailing: _MediaListActionBar(
        hasItems: hasItems,
        hasSelection: hasSelection,
        selectionCount: selectionCount,
        allLoadedSelected: allLoadedSelected,
        isDeleting: isDeleting,
        isTransferring: isTransferring,
        isResettingThumbnails: isResettingThumbnails,
        isInitialLoading: isInitialLoading,
        busy: busy,
        onBatchDelete: onBatchDelete,
        onBatchTransfer: onBatchTransfer,
        canResetThumbnails:
            filter.thumbnailGenerationState ==
            MediaBrowseThumbnailGenerationFilter.terminal,
        onBatchResetThumbnails: onBatchResetThumbnails,
        onRefresh: () => unawaited((onRefresh ?? () => _defaultRefresh(ref))()),
      ),
    );
  }
}

/// 移动端筛选抽屉内容：沿用 `movie_filter_drawer` 的「本地 `_local` + 即时外发」模式
/// （就地反映选中态，打开期间点选 chip 立即点亮），壳用共享
/// [AppMobileFilterDrawerScaffold]（与其余筛选抽屉一致，无标题、条件即时更新）。
class _MediaListMobileFilterDrawerContent extends StatefulWidget {
  const _MediaListMobileFilterDrawerContent({
    required this.initial,
    required this.libraries,
    required this.onChanged,
    required this.scrollViewKey,
  });

  final MediaBrowseFilterState initial;
  final List<MediaLibraryDto> libraries;
  final ValueChanged<MediaBrowseFilterState> onChanged;
  final Key scrollViewKey;

  @override
  State<_MediaListMobileFilterDrawerContent> createState() =>
      _MediaListMobileFilterDrawerContentState();
}

class _MediaListMobileFilterDrawerContentState
    extends State<_MediaListMobileFilterDrawerContent> {
  late MediaBrowseFilterState _local;

  @override
  void initState() {
    super.initState();
    _local = widget.initial;
  }

  void _apply(MediaBrowseFilterState next) {
    setState(() => _local = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return AppMobileFilterDrawerScaffold(
      scrollViewKey: widget.scrollViewKey,
      footer: AppFilterPanelFooter(
        isDefault: _local.isDefault,
        onReset: () => _apply(MediaBrowseFilterState.initial),
      ),
      child: MediaBrowseFilterSectionGroup(
        filterState: _local,
        libraries: widget.libraries,
        onChanged: _apply,
      ),
    );
  }
}

class _MediaListBodySliver extends ConsumerWidget {
  const _MediaListBodySliver({
    required this.keyPrefix,
    required this.mobile,
    required this.selectionMode,
    required this.onEnterSelection,
    required this.onOpenMovieDetail,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.onDeleteItem,
    required this.deletingItemId,
    required this.onRetryThumbnails,
    required this.retryingThumbnailMediaId,
  });

  final String keyPrefix;
  final bool mobile;
  final bool selectionMode;
  final VoidCallback? onEnterSelection;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final Future<void> Function(MediaListItemDto item)? onDeleteItem;
  final ValueListenable<int?>? deletingItemId;
  final Future<void> Function(MediaListItemDto item)? onRetryThumbnails;
  final ValueListenable<int?>? retryingThumbnailMediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 多选集合变化时 paged 段保持相等，因此列表 sliver 不会整体重建；
    // 每一行通过 [_MediaRowConsumer] 只订阅自己的选中态。
    final asyncPaged = ref.watch(
      mediaBrowseProvider.select(
        (asyncState) => asyncState.whenData((state) => state.paged),
      ),
    );

    return SliverPagedAsyncSection<
      PagedListState<MediaListItemDto>,
      MediaListItemDto
    >(
      asyncState: asyncPaged,
      pagedOf: (state) => state,
      itemSpacing: context.appSpacing.sm,
      fixedItemExtent: mobile
          ? null
          : context.appComponentTokens.mediaManagementRowHeight,
      initialErrorMessage: '媒体列表加载失败，请稍后重试',
      emptyMessage: '当前筛选下没有媒体记录。调整筛选条件或稍后再试。',
      initialRetryKey: Key('$keyPrefix-initial-retry-button'),
      onReload: () =>
          unawaited(ref.read(mediaBrowseProvider.notifier).reload()),
      onLoadMore: () =>
          unawaited(ref.read(mediaBrowseProvider.notifier).loadMore()),
      itemBuilder: (context, item, _) => mobile
          ? _MediaMobileRowConsumer(
              keyPrefix: keyPrefix,
              item: item,
              selectionMode: selectionMode,
              onEnterSelection: onEnterSelection,
              onOpenMovieDetail: onOpenMovieDetail,
              isDeleting: isDeleting,
              isTransferring: isTransferring,
              isResettingThumbnails: isResettingThumbnails,
              onDeleteItem: onDeleteItem,
              deletingItemId: deletingItemId,
              onRetryThumbnails: onRetryThumbnails,
              retryingThumbnailMediaId: retryingThumbnailMediaId,
            )
          : _MediaRowConsumer(
              keyPrefix: keyPrefix,
              item: item,
              onOpenMovieDetail: onOpenMovieDetail,
              isDeleting: isDeleting,
              isTransferring: isTransferring,
              isResettingThumbnails: isResettingThumbnails,
              onDeleteItem: onDeleteItem,
              deletingItemId: deletingItemId,
              onRetryThumbnails: onRetryThumbnails,
              retryingThumbnailMediaId: retryingThumbnailMediaId,
            ),
    );
  }
}

/// 移动端行 consumer：订阅选中态 / 媒体库，组装 [MediaListItemCard]。
class _MediaMobileRowConsumer extends ConsumerWidget {
  const _MediaMobileRowConsumer({
    required this.keyPrefix,
    required this.item,
    required this.selectionMode,
    required this.onEnterSelection,
    this.onOpenMovieDetail,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.onDeleteItem,
    required this.deletingItemId,
    required this.onRetryThumbnails,
    required this.retryingThumbnailMediaId,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final bool selectionMode;
  final VoidCallback? onEnterSelection;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final Future<void> Function(MediaListItemDto item)? onDeleteItem;
  final ValueListenable<int?>? deletingItemId;
  final Future<void> Function(MediaListItemDto item)? onRetryThumbnails;
  final ValueListenable<int?>? retryingThumbnailMediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      mediaBrowseProvider.select(
        (asyncState) => asyncState.value?.isSelected(item.id) ?? false,
      ),
    );
    final librariesById = ref.watch(
      mediaLibrariesProvider.select(
        (asyncState) =>
            asyncState.value?.librariesById ?? const <int, MediaLibraryDto>{},
      ),
    );
    final library = item.libraryId == null
        ? null
        : librariesById[item.libraryId];

    Widget buildCard(int? deletingId, int? retryingId) {
      final isRetryable =
          !selectionMode &&
          item.thumbnailGenerationState ==
              MediaThumbnailGenerationState.terminal;
      final isRetrying = retryingId == item.id;
      return MediaListItemCard(
        keyPrefix: keyPrefix,
        item: item,
        library: library,
        mobile: true,
        selected: isSelected,
        onTap: selectionMode
            ? () => ref
                  .read(mediaBrowseProvider.notifier)
                  .toggleSelection(item.id)
            : null,
        onLongPress: selectionMode
            ? null
            : () {
                ref.read(mediaBrowseProvider.notifier).toggleSelection(item.id);
                onEnterSelection?.call();
              },
        onOpenMovieDetail: onOpenMovieDetail,
        onDelete: selectionMode || onDeleteItem == null
            ? null
            : () => unawaited(onDeleteItem!(item)),
        isDeleting: deletingId == item.id,
        canDelete:
            !isDeleting &&
            !isTransferring &&
            !isResettingThumbnails &&
            retryingId == null &&
            deletingId == null,
        onRetryThumbnails: isRetryable && onRetryThumbnails != null
            ? () => unawaited(onRetryThumbnails!(item))
            : null,
        isRetryingThumbnails: isRetrying,
        canRetryThumbnails:
            isRetryable &&
            !isDeleting &&
            !isTransferring &&
            !isResettingThumbnails &&
            retryingId == null,
      );
    }

    final listenables = <Listenable>[
      ?deletingItemId,
      ?retryingThumbnailMediaId,
    ];
    if (listenables.isEmpty) return buildCard(null, null);
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, child) =>
          buildCard(deletingItemId?.value, retryingThumbnailMediaId?.value),
    );
  }
}

/// 移动端多选态底部批量操作条。
class _MediaMobileSelectionBar extends ConsumerWidget {
  const _MediaMobileSelectionBar({
    required this.keyPrefix,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.onBatchDelete,
    required this.onBatchTransfer,
    required this.onBatchResetThumbnails,
  });

  final String keyPrefix;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final Future<void> Function() onBatchDelete;
  final Future<void> Function() onBatchTransfer;
  final Future<void> Function()? onBatchResetThumbnails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionCount = ref.watch(
      mediaBrowseProvider.select(
        (asyncState) => asyncState.value?.selectionCount ?? 0,
      ),
    );
    final canResetThumbnails = ref.watch(
      mediaBrowseProvider.select(
        (asyncState) =>
            asyncState.value?.filter.thumbnailGenerationState ==
            MediaBrowseThumbnailGenerationFilter.terminal,
      ),
    );
    final busy = isDeleting || isTransferring || isResettingThumbnails;
    return AppSelectionBottomBar(
      leading: Text(
        '已选 $selectionCount 项',
        key: Key('$keyPrefix-bottom-selection-count'),
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s14,
          weight: AppTextWeight.semibold,
          tone: AppTextTone.primary,
        ),
      ),
      actions: [
        AppButton(
          key: Key('$keyPrefix-batch-transfer-button'),
          label: '迁移',
          icon: const Icon(Icons.drive_file_move_outline),
          isLoading: isTransferring,
          onPressed: busy || selectionCount == 0 ? null : onBatchTransfer,
        ),
        AppButton(
          key: Key('$keyPrefix-batch-delete-button'),
          label: '删除',
          variant: AppButtonVariant.danger,
          icon: const Icon(Icons.delete_outline_rounded),
          isLoading: isDeleting,
          onPressed: busy || selectionCount == 0 ? null : onBatchDelete,
        ),
        if (canResetThumbnails && onBatchResetThumbnails != null)
          AppButton(
            key: Key('$keyPrefix-batch-reset-thumbnails-button'),
            label: '重试',
            icon: const Icon(Icons.refresh_rounded),
            isLoading: isResettingThumbnails,
            onPressed: busy || selectionCount == 0
                ? null
                : onBatchResetThumbnails,
          ),
      ],
    );
  }
}

class _MediaRowConsumer extends ConsumerWidget {
  const _MediaRowConsumer({
    required this.keyPrefix,
    required this.item,
    this.onOpenMovieDetail,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.onDeleteItem,
    required this.deletingItemId,
    required this.onRetryThumbnails,
    required this.retryingThumbnailMediaId,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final Future<void> Function(MediaListItemDto item)? onDeleteItem;
  final ValueListenable<int?>? deletingItemId;
  final Future<void> Function(MediaListItemDto item)? onRetryThumbnails;
  final ValueListenable<int?>? retryingThumbnailMediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      mediaBrowseProvider.select(
        (asyncState) => asyncState.value?.isSelected(item.id) ?? false,
      ),
    );
    final librariesById = ref.watch(
      mediaLibrariesProvider.select(
        (asyncState) =>
            asyncState.value?.librariesById ?? const <int, MediaLibraryDto>{},
      ),
    );
    final library = item.libraryId == null
        ? null
        : librariesById[item.libraryId];

    Widget buildCard(int? deletingId, int? retryingId) {
      final isRetryable =
          item.thumbnailGenerationState ==
          MediaThumbnailGenerationState.terminal;
      final isRetrying = retryingId == item.id;
      return MediaListItemCard(
        keyPrefix: keyPrefix,
        item: item,
        library: library,
        mobile: false,
        selected: isSelected,
        onTap: () =>
            ref.read(mediaBrowseProvider.notifier).toggleSelection(item.id),
        onOpenMovieDetail: onOpenMovieDetail,
        onDelete: onDeleteItem == null
            ? null
            : () => unawaited(onDeleteItem!(item)),
        isDeleting: deletingId == item.id,
        canDelete:
            !isDeleting &&
            !isTransferring &&
            !isResettingThumbnails &&
            retryingId == null &&
            deletingId == null,
        onRetryThumbnails: isRetryable && onRetryThumbnails != null
            ? () => unawaited(onRetryThumbnails!(item))
            : null,
        isRetryingThumbnails: isRetrying,
        canRetryThumbnails:
            isRetryable &&
            !isDeleting &&
            !isTransferring &&
            !isResettingThumbnails &&
            retryingId == null,
        showUpdatedAt: true,
      );
    }

    final listenables = <Listenable>[
      ?deletingItemId,
      ?retryingThumbnailMediaId,
    ];
    if (listenables.isEmpty) return buildCard(null, null);
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, child) =>
          buildCard(deletingItemId?.value, retryingThumbnailMediaId?.value),
    );
  }
}

/// 顶栏右侧多选操作条：全选 / 迁移 / 重试 / 清空 / 批量删除 / 刷新。
///
/// 无选择态：仅保留「全选本页」+「刷新」（不占空间过多，视觉上不喧宾夺主）；
/// 有选择态：追加「迁移 / 清空 / 批量删除」，危险色只用于删除。
class _MediaListActionBar extends ConsumerWidget {
  const _MediaListActionBar({
    required this.hasItems,
    required this.hasSelection,
    required this.selectionCount,
    required this.allLoadedSelected,
    required this.isDeleting,
    required this.isTransferring,
    required this.isResettingThumbnails,
    required this.isInitialLoading,
    required this.busy,
    required this.onBatchDelete,
    required this.onBatchTransfer,
    required this.canResetThumbnails,
    required this.onBatchResetThumbnails,
    required this.onRefresh,
  });

  final bool hasItems;
  final bool hasSelection;
  final int selectionCount;
  final bool allLoadedSelected;
  final bool isDeleting;
  final bool isTransferring;
  final bool isResettingThumbnails;
  final bool isInitialLoading;
  final bool busy;
  final Future<void> Function() onBatchDelete;
  final Future<void> Function() onBatchTransfer;
  final bool canResetThumbnails;
  final Future<void> Function()? onBatchResetThumbnails;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          key: const Key('media-management-select-all-button'),
          label: allLoadedSelected ? '取消全选本页' : '全选本页',
          size: AppButtonSize.small,
          variant: AppButtonVariant.secondary,
          onPressed: !hasItems || busy
              ? null
              : () => ref
                    .read(mediaBrowseProvider.notifier)
                    .toggleSelectAllLoaded(),
        ),
        if (hasSelection)
          AppButton(
            key: const Key('media-management-batch-transfer-button'),
            label: '迁移（$selectionCount）',
            size: AppButtonSize.small,
            icon: const Icon(Icons.drive_file_move_outline),
            isLoading: isTransferring,
            onPressed: busy ? null : onBatchTransfer,
          ),
        if (hasSelection &&
            canResetThumbnails &&
            onBatchResetThumbnails != null)
          AppButton(
            key: const Key('media-management-batch-reset-thumbnails-button'),
            label: '重试缩略图（$selectionCount）',
            size: AppButtonSize.small,
            icon: const Icon(Icons.refresh_rounded),
            isLoading: isResettingThumbnails,
            onPressed: busy ? null : onBatchResetThumbnails,
          ),
        if (hasSelection)
          AppButton(
            key: const Key('media-management-clear-selection-button'),
            label: '清空选择',
            size: AppButtonSize.small,
            variant: AppButtonVariant.secondary,
            onPressed: busy
                ? null
                : () => ref.read(mediaBrowseProvider.notifier).clearSelection(),
          ),
        if (hasSelection)
          AppButton(
            key: const Key('media-management-batch-delete-button'),
            label: '批量删除（$selectionCount）',
            size: AppButtonSize.small,
            variant: AppButtonVariant.danger,
            icon: const Icon(Icons.delete_outline_rounded),
            isLoading: isDeleting,
            onPressed: busy ? null : onBatchDelete,
          ),
        AppIconButton(
          key: const Key('media-management-refresh-button'),
          tooltip: isInitialLoading ? '刷新中' : '刷新',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: isInitialLoading ? null : onRefresh,
        ),
      ],
    );
  }
}
