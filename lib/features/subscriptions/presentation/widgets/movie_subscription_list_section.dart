import 'package:sakuramedia/widgets/base/operations/batch/batch_progress_dialog.dart';
import 'package:sakuramedia/features/downloads/data/download_request_dto.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/download_task_center_provider.dart';
import 'package:sakuramedia/widgets/domain/downloads/download_task_delete_dialog.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show HookConsumerWidget;
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_list_item_dto.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_status.dart';
import 'package:sakuramedia/features/subscriptions/presentation/movie_subscription_filter_state.dart';
import 'package:sakuramedia/features/subscriptions/presentation/providers/movie_subscription_manager_provider.dart';
import 'package:sakuramedia/features/subscriptions/presentation/providers/movie_subscription_manager_state.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/features/subscriptions/presentation/widgets/movie_subscription_filter_sections.dart';
import 'package:sakuramedia/features/subscriptions/presentation/widgets/movie_subscription_row.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_placeholders.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_notice_card.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_result_loading_overlay.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_magnet_search_dialog.dart';

/// 订阅管理页的列表主体：顶栏（筛选 / 计数 / 操作）+ 行卡片列表。
///
/// 双端分流只发生在容器层：筛选桌面走就地浮层、移动走底部抽屉；多选态桌面用
/// [AppSelectionHeaderToolbar] 原地改写整行，移动用 `AppListHeader.selection`
/// （顶）+ [AppSelectionBottomBar]（底）。列表体、行卡片、空态完全共用。
///
/// 状态分段签不在这里——它归页面，固定在滚动区之上。
class MovieSubscriptionListSection extends HookConsumerWidget {
  const MovieSubscriptionListSection({
    super.key,
    required this.onOpenMovie,
    required this.onOpenDownloads,
    this.mobile = false,
    this.scrollController,
  });

  /// 打开影片详情。桌面 / 移动的详情路由不同，由各自的页面注入——本组件不认路由。
  final void Function(BuildContext context, String movieNumber) onOpenMovie;

  /// 打开该订阅片对应的下载任务列表，同样由页面注入各自的平台路由。
  final void Function(BuildContext context, String movieNumber) onOpenDownloads;

  /// 移动端布局：底部抽屉筛选 + 贴底批量操作条。
  final bool mobile;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final spacing = context.appSpacing;
    final ownedScrollController = useScrollController();
    final effectiveScrollController = scrollController ?? ownedScrollController;
    // 移动端删除下载任务的 loading：顶栏（退出 / 全选）和贴底操作条要同步禁用。
    final batchDeleting = useState(false);
    useEffect(() {
      void loadMoreIfNeeded() {
        if (!effectiveScrollController.hasClients) return;
        final current = ref.read(managerProvider).value;
        if (current == null ||
            current.paged.loadMoreErrorMessage != null ||
            effectiveScrollController.position.extentAfter > 300) {
          return;
        }
        unawaited(ref.read(managerProvider.notifier).loadMore());
      }

      effectiveScrollController.addListener(loadMoreIfNeeded);
      return () => effectiveScrollController.removeListener(loadMoreIfNeeded);
    }, [effectiveScrollController, managerProvider]);
    ref.listen(managerProvider.select((value) => value.value?.filter), (
      previous,
      next,
    ) {
      if (previous != null &&
          next != null &&
          previous != next &&
          effectiveScrollController.hasClients) {
        effectiveScrollController.jumpTo(0);
      }
    });
    final paged = ref.watch(
      managerProvider.select((asyncState) => asyncState.value?.paged),
    );
    final resultView = AppFixedHeaderLayout(
      header: _ListHeader(mobile: mobile, batchDeleting: batchDeleting.value),
      child: AppFilterResultLoadingOverlay(
        isLoading: paged?.filterUpdate.isLoading ?? false,
        hasPreviousItems: paged?.items.isNotEmpty ?? false,
        child: CustomScrollView(
          key: PageStorageKey(managerProvider),
          controller: effectiveScrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: spacing.lg)),
            const SliverToBoxAdapter(child: _queryExplanationTip),
            SliverToBoxAdapter(child: SizedBox(height: spacing.md)),
            _ListBodySliver(
              onOpenMovie: onOpenMovie,
              onOpenDownloads: onOpenDownloads,
              mobile: mobile,
            ),
          ],
        ),
      ),
    );
    if (!mobile) return resultView;
    final selectionMode = ref.watch(
      managerProvider.select(
        (asyncState) => asyncState.value?.selectionMode ?? false,
      ),
    );
    if (!selectionMode) return resultView;
    return Column(
      children: [
        Expanded(child: resultView),
        _MobileSelectionBar(
          deleting: batchDeleting.value,
          onDeletingChanged: (value) => batchDeleting.value = value,
        ),
      ],
    );
  }
}

// --- 顶栏 -------------------------------------------------------------------

class _ListHeader extends ConsumerWidget {
  const _ListHeader({required this.mobile, required this.batchDeleting});

  final bool mobile;
  final bool batchDeleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final asyncState = ref.watch(managerProvider);
    final current = asyncState.value;
    if (current != null && current.selectionMode) {
      return mobile
          ? _MobileSelectionHeader(state: current, batchDeleting: batchDeleting)
          : _SelectionHeader(state: current);
    }

    final filter =
        current?.filter ??
        MovieSubscriptionFilterState.initial.copyWith(
          status: ref.watch(movieSubscriptionStatusSelectionProvider),
        );
    final total = current?.paged.total ?? 0;
    final hasItems = current?.paged.items.isNotEmpty ?? false;
    final isInitialLoading = asyncState.isLoading && !asyncState.hasValue;

    void applyFilter(MovieSubscriptionFilterState next) {
      unawaited(ref.read(managerProvider.notifier).applyFilterState(next));
    }

    Widget buildPanel(BuildContext panelContext) {
      return MovieSubscriptionFilterSectionGroup(
        filterState: filter,
        onChanged: applyFilter,
      );
    }

    final panelFooter = AppFilterPanelFooter(
      isDefault: filter.isPanelDefault,
      onReset: () => applyFilter(filter.resetPanel()),
    );

    return AppListHeader(
      key: const Key('movie-subscriptions-list-header'),
      onFilterTap: mobile
          ? () => _openMobileFilterDrawer(context, ref, filter)
          : null,
      filterButtonKey: const Key('movie-subscriptions-filter-button'),
      filterLabel: filter.triggerLabel,
      filterPanelKey: mobile
          ? null
          : const Key('movie-subscriptions-filter-panel'),
      filterPanelBuilder: mobile ? null : buildPanel,
      filterPanelFooter: mobile ? null : panelFooter,
      filterUpdate:
          current?.paged.filterUpdate ?? const FilterUpdateState.idle(),
      hasPreviousFilterItems: hasItems,
      onRetryFilter: () =>
          unawaited(ref.read(managerProvider.notifier).retryFilter()),
      informationSlots: <Widget>[
        AppListHeaderInfo(
          key: const Key('movie-subscriptions-total-info'),
          label: '共 $total 部',
        ),
      ],
      actionSlots: <Widget>[
        AppSelectionEntryButton(
          onPressed: hasItems
              ? () => ref.read(managerProvider.notifier).enterSelectionMode()
              : null,
        ),
        AppIconButton(
          key: const Key('movie-subscriptions-refresh-button'),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: isInitialLoading ? '刷新中' : '刷新',
          onPressed: isInitialLoading ? null : () => _refresh(ref),
        ),
      ],
    );
  }
}

/// 移动端筛选底部抽屉：与桌面浮层共用 [MovieSubscriptionFilterSectionGroup] 和
/// [AppFilterPanelFooter]，只有外壳不同。本地态 + 即时外发，与其它移动抽屉一致。
Future<void> _openMobileFilterDrawer(
  BuildContext context,
  WidgetRef ref,
  MovieSubscriptionFilterState filter,
) {
  final managerProvider = movieSubscriptionManagerProvider(filter.status);
  return showAppBottomDrawer<void>(
    context: context,
    drawerKey: const Key('movie-subscriptions-filter-drawer'),
    // 内容自适应高度（最多 60% 屏高），避免「搜索 + 排序」的短面板拖一大片空白。
    maxHeightFactor: 0.6,
    builder: (_) => _MobileFilterDrawerContent(
      initial: filter,
      onChanged: (next) =>
          unawaited(ref.read(managerProvider.notifier).applyFilterState(next)),
      scrollViewKey: const Key('movie-subscriptions-filter-scroll-view'),
    ),
  );
}

class _MobileFilterDrawerContent extends StatefulWidget {
  const _MobileFilterDrawerContent({
    required this.initial,
    required this.onChanged,
    required this.scrollViewKey,
  });

  final MovieSubscriptionFilterState initial;
  final ValueChanged<MovieSubscriptionFilterState> onChanged;
  final Key scrollViewKey;

  @override
  State<_MobileFilterDrawerContent> createState() =>
      _MobileFilterDrawerContentState();
}

class _MobileFilterDrawerContentState
    extends State<_MobileFilterDrawerContent> {
  late MovieSubscriptionFilterState _local;

  @override
  void initState() {
    super.initState();
    _local = widget.initial;
  }

  void _apply(MovieSubscriptionFilterState next) {
    setState(() => _local = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return AppMobileFilterDrawerScaffold(
      scrollViewKey: widget.scrollViewKey,
      footer: AppFilterPanelFooter(
        isDefault: _local.isPanelDefault,
        onReset: () => _apply(_local.resetPanel()),
      ),
      child: MovieSubscriptionFilterSectionGroup(
        filterState: _local,
        onChanged: _apply,
      ),
    );
  }
}

void _refresh(WidgetRef ref) {
  final managerProvider = movieSubscriptionManagerProvider(
    ref.read(movieSubscriptionStatusSelectionProvider),
  );
  unawaited(() async {
    final message = await ref.read(managerProvider.notifier).refresh();
    if (message != null) showToast(message);
  }());
}

// --- 多选态顶栏 --------------------------------------------------------------

class _SelectionHeader extends HookConsumerWidget {
  const _SelectionHeader({required this.state});

  final MovieSubscriptionManagerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final notifier = ref.read(managerProvider.notifier);
    final loadingDownloads = useState(false);
    final busy = state.isBatchRunning || loadingDownloads.value;

    final loadedCount = state.paged.items.length;
    final allSelected = loadedCount > 0 && state.selectionCount >= loadedCount;
    final selectAllLabel = allSelected ? '取消全选' : '全选（$loadedCount）';

    return AppSelectionHeaderToolbar(
      key: const Key('movie-subscriptions-selection-header'),
      countLabel: '已选 ${state.selectionCount} 部',
      countKey: const Key('movie-subscriptions-selection-count'),
      selectAllLabel: selectAllLabel,
      selectAllKey: const Key('movie-subscriptions-select-all-button'),
      onToggleAll: busy || loadedCount == 0
          ? null
          : notifier.toggleSelectAllLoaded,
      exitKey: const Key('movie-subscriptions-selection-exit'),
      onExit: busy ? null : notifier.exitSelectionMode,
      actions: _buildBatchActions(
        context,
        ref,
        state,
        size: AppButtonSize.small,
        loadingDownloads: loadingDownloads.value,
        onDeleteDownloads: () => unawaited(
          _deleteSelectedDownloads(
            context,
            ref,
            state,
            onLoadingChanged: (value) => loadingDownloads.value = value,
          ),
        ),
      ),
    );
  }
}

/// 移动端多选态顶栏：与 PornBox / 媒体管理的 `AppListHeader.selection` 同一套。
class _MobileSelectionHeader extends ConsumerWidget {
  const _MobileSelectionHeader({
    required this.state,
    required this.batchDeleting,
  });

  final MovieSubscriptionManagerState state;
  final bool batchDeleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final notifier = ref.read(managerProvider.notifier);
    final busy = state.isBatchRunning || batchDeleting;
    final loadedCount = state.paged.items.length;
    final allSelected = loadedCount > 0 && state.selectionCount >= loadedCount;

    return AppListHeader.selection(
      key: const Key('movie-subscriptions-selection-header'),
      selectionLabel: '已选 ${state.selectionCount} 部',
      selectionExitButtonKey: const Key('movie-subscriptions-selection-exit'),
      onExitSelection: busy ? null : notifier.exitSelectionMode,
      actionSlots: <Widget>[
        AppTextButton(
          key: const Key('movie-subscriptions-select-all-button'),
          label: allSelected ? '取消全选' : '全选（$loadedCount）',
          size: AppTextButtonSize.small,
          onPressed: busy || loadedCount == 0
              ? null
              : notifier.toggleSelectAllLoaded,
        ),
      ],
    );
  }
}

/// 移动端贴底批量操作条：真正的危险动作放拇指够得到的地方，顶栏只留退出 / 全选。
class _MobileSelectionBar extends ConsumerWidget {
  const _MobileSelectionBar({
    required this.deleting,
    required this.onDeletingChanged,
  });

  final bool deleting;
  final ValueChanged<bool> onDeletingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final state = ref.watch(managerProvider).value;
    if (state == null) return const SizedBox.shrink();
    return AppSelectionBottomBar(
      actions: _buildBatchActions(
        context,
        ref,
        state,
        loadingDownloads: deleting,
        onDeleteDownloads: () => unawaited(
          _deleteSelectedDownloads(
            context,
            ref,
            state,
            onLoadingChanged: onDeletingChanged,
          ),
        ),
      ),
    );
  }
}

/// 多选态的批量操作按钮。桌面放进 `AppSelectionHeaderToolbar.actions`（small），
/// 移动贴底 `AppSelectionBottomBar` 用默认 medium 撑满等宽。
List<Widget> _buildBatchActions(
  BuildContext context,
  WidgetRef ref,
  MovieSubscriptionManagerState state, {
  AppButtonSize size = AppButtonSize.medium,
  required bool loadingDownloads,
  required VoidCallback onDeleteDownloads,
}) {
  final busy = state.isBatchRunning || loadingDownloads;
  return <Widget>[
    AppButton(
      key: const Key('movie-subscriptions-batch-delete-downloads-button'),
      label: '删除下载任务',
      size: size,
      variant: AppButtonVariant.danger,
      icon: const Icon(Icons.delete_outline_rounded),
      isLoading: loadingDownloads,
      onPressed: busy || !state.hasSelection ? null : onDeleteDownloads,
    ),
    AppButton(
      key: const Key('movie-subscriptions-batch-unsubscribe-button'),
      label: '取消订阅（${state.selectionCount}）',
      size: size,
      variant: AppButtonVariant.danger,
      icon: const Icon(Icons.bookmark_remove_outlined),
      isLoading: state.isBatchActionRunning(
        MovieSubscriptionBatchAction.unsubscribe,
      ),
      onPressed: busy || !state.hasSelection
          ? null
          : () => unawaited(_confirmBatchUnsubscribe(context, ref, state)),
    ),
  ];
}

/// 批量删除所选影片的下载任务：查询 → 确认 → 逐个删除 → 刷新列表。
/// 桌面顶栏与移动贴底条的共用实现。
Future<void> _deleteSelectedDownloads(
  BuildContext context,
  WidgetRef ref,
  MovieSubscriptionManagerState state, {
  required ValueChanged<bool> onLoadingChanged,
}) async {
  onLoadingChanged(true);
  try {
    final managerProvider = movieSubscriptionManagerProvider(
      state.filter.status,
    );
    final tasks = <DownloadTaskDto>[];
    final result = await runBatchOperation<String>(
      context,
      title: '正在查询下载任务',
      items: state.selectedMovieNumbers.toList(),
      action: (number) async {
        tasks.addAll(
          await ref.refresh(movieDownloadTasksProvider(number).future),
        );
      },
    );
    if (!context.mounted) return;
    onLoadingChanged(false);
    if (result.failed.isNotEmpty) return;
    if (tasks.isEmpty) {
      showToast('所选影片没有下载任务');
      return;
    }
    final api = ref.read(downloadsApiProvider);
    var removed = 0;
    await showDownloadTaskDeleteDialog(
      context,
      tasks: tasks,
      showProgress: true,
      onDelete: (id, deleteFiles) async {
        await api.deleteDownloadTask(id, deleteFiles: deleteFiles);
        removed++;
      },
    );
    if (!context.mounted) return;
    if (removed > 0) {
      ref.invalidate(downloadTaskCenterProvider);
      await ref.read(managerProvider.notifier).refresh();
      if (context.mounted) showToast('已删除 $removed 个下载任务');
    }
  } catch (error) {
    if (context.mounted) {
      showToast(apiErrorMessage(error, fallback: '下载任务加载失败'));
    }
  } finally {
    if (context.mounted) onLoadingChanged(false);
  }
}

Future<void> _confirmBatchUnsubscribe(
  BuildContext context,
  WidgetRef ref,
  MovieSubscriptionManagerState state,
) async {
  final managerProvider = movieSubscriptionManagerProvider(state.filter.status);
  final count = state.selectionCount;
  final confirmed = await showAppConfirmDialog(
    context,
    dialogKey: const Key('movie-subscriptions-batch-unsubscribe-dialog'),
    title: '取消订阅 $count 部影片？',
    message: '取消后它们不再自动找资源。已有本地媒体的影片会被跳过，不会删除任何文件。',
    confirmLabel: '取消订阅',
    danger: true,
  );
  if (!confirmed) return;

  final result = await ref.read(managerProvider.notifier).batchUnsubscribe();
  if (!context.mounted) return;
  await showMovieSubscriptionBatchFeedback(context, result, subscribe: false);
}

// --- 查询说明 ----------------------------------------------------------------

const _queryExplanationTip = AppNoticeCard(
  leadingIcon: Icons.info_outline_rounded,
  description:
      '订阅影片后，系统通过定时任务在索引器中搜索可下载资源，找到后自动提交下载。'
      '新片（发行 90 天内）每轮查询、不限次数；'
      '老片默认至多查 3 次，用尽则标记「已放弃」，需手动重置后重新排队。'
      '查询出错不消耗次数，下一轮自动重试。'
      '重置不会清除种子黑名单——已判死的种子不再重试，系统会去寻找新的种子。',
);

// --- 列表体 -----------------------------------------------------------------

class _ListBodySliver extends ConsumerWidget {
  const _ListBodySliver({
    required this.onOpenMovie,
    required this.onOpenDownloads,
    required this.mobile,
  });

  final void Function(BuildContext context, String movieNumber) onOpenMovie;
  final void Function(BuildContext context, String movieNumber) onOpenDownloads;
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    // 只订阅 paged 段：多选 / 进行中集合变化时它保持相等，列表 sliver 不整体重建，
    // 每行由 [_RowConsumer] 各自订阅自己的选中 / pending 态。
    final asyncPaged = ref.watch(
      managerProvider.select(
        (asyncState) => asyncState.whenData((state) => state.paged),
      ),
    );
    final notifier = ref.read(managerProvider.notifier);

    // 不传 fixedItemExtent：错误行是条件渲染、进度行会换行，行高本来就不固定，
    // 强行给固定 extent 会让内容溢出。
    return SliverPagedAsyncSection<
      PagedListState<MovieSubscriptionListItemDto>,
      MovieSubscriptionListItemDto
    >(
      asyncState: asyncPaged,
      pagedOf: (paged) => paged,
      itemSpacing: context.appSpacing.sm,
      initialErrorMessage: '订阅列表加载失败，请稍后重试',
      emptyMessage: '当前筛选下没有订阅影片。',
      emptyBuilder: (context) => const _EmptyState(),
      // loading 用占位订阅渲染真实行，由 [AppSkeletonizer] 灰化。
      skeletonBuilder: (context) {
        final placeholders = movieSubscriptionListItemPlaceholders();
        return AppSkeletonizer(
          enabled: true,
          child: Column(
            children: [
              for (var index = 0; index < placeholders.length; index++) ...[
                if (index > 0) SizedBox(height: context.appSpacing.sm),
                MovieSubscriptionRow(
                  item: placeholders[index],
                  selectionMode: false,
                  isSelected: false,
                  isPending: false,
                  onTap: () {},
                  onOpenDownloads: null,
                  onSearchMagnet: () {},
                  onUnsubscribe: () {},
                  mobile: mobile,
                ),
              ],
            ],
          ),
        );
      },
      initialRetryKey: const Key('movie-subscriptions-initial-retry-button'),
      onReload: () => unawaited(notifier.reload()),
      onLoadMore: () => unawaited(notifier.loadMore()),
      itemBuilder: (context, item, _) => _RowConsumer(
        item: item,
        mobile: mobile,
        onOpenMovie: onOpenMovie,
        onOpenDownloads: onOpenDownloads,
      ),
    );
  }
}

/// 分状态的空态文案。
///
/// 待办三态为空是**好消息**，不该用「暂无数据」这种失败口吻打发——说清"没有卡住
/// 的订阅"，并给一个「看全部订阅」的去处，免得用户以为页面坏了。
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final filter =
        ref.watch(
          managerProvider.select((asyncState) => asyncState.value?.filter),
        ) ??
        MovieSubscriptionFilterState.initial;

    if (filter.hasSearch) {
      return AppEmptyState(
        key: const Key('movie-subscriptions-empty-state'),
        icon: Icons.search_off_rounded,
        message: '没有匹配「${filter.trimmedSearch}」的订阅影片。换个番号或标题片段再试。',
      );
    }

    final (icon, title, message) = switch (filter.status) {
      MovieSubscriptionStatus.missing => (
        Icons.check_circle_outline_rounded,
        '没有缺资源的订阅',
        '所有订阅影片要么已经拿到资源，要么还在正常查询中。',
      ),
      MovieSubscriptionStatus.exhausted => (
        Icons.check_circle_outline_rounded,
        '没有被放弃的订阅',
        '没有影片因多次没找到资源而放弃，不需要手动重置。',
      ),
      MovieSubscriptionStatus.importFailed => (
        Icons.check_circle_outline_rounded,
        '没有卡在导入的影片',
        '下载完成的影片都顺利入库了。',
      ),
      MovieSubscriptionStatus.failed => (
        Icons.check_circle_outline_rounded,
        '索引器一切正常',
        '最近一轮资源查询没有出错。',
      ),
      MovieSubscriptionStatus.pending => (
        Icons.hourglass_empty_rounded,
        '没有待查的订阅',
        '新订阅的影片会先落在这里，等下一轮定时任务查过就转到别的状态。',
      ),
      MovieSubscriptionStatus.downloading => (
        Icons.download_outlined,
        '没有正在下载的订阅',
        '找到种子的影片会出现在这里，进度可以去任务中心看。',
      ),
      MovieSubscriptionStatus.imported => (
        Icons.inbox_outlined,
        '还没有入库的订阅影片',
        '资源下载并导入媒体库后，影片会归到这里。',
      ),
      MovieSubscriptionStatus.unknown || null => (
        Icons.bookmark_border_rounded,
        '还没有订阅任何影片',
        '在影片列表或详情页点订阅，之后就能在这里跟进求片进度。',
      ),
    };

    final isFilteredView = filter.status != null;
    return Column(
      children: [
        AppEmptyState(
          key: const Key('movie-subscriptions-empty-state'),
          icon: icon,
          title: title,
          message: message,
        ),
        if (isFilteredView) ...[
          SizedBox(height: context.appSpacing.md),
          AppButton(
            key: const Key('movie-subscriptions-empty-see-all-button'),
            label: '查看全部订阅',
            size: AppButtonSize.small,
            variant: AppButtonVariant.secondary,
            onPressed: () => ref
                .read(movieSubscriptionStatusSelectionProvider.notifier)
                .select(null),
          ),
        ],
      ],
    );
  }
}

/// 单行的订阅者：只 watch 自己的选中 / pending 态，避免整表重建。
class _RowConsumer extends HookConsumerWidget {
  const _RowConsumer({
    required this.item,
    required this.onOpenMovie,
    required this.onOpenDownloads,
    required this.mobile,
  });

  final MovieSubscriptionListItemDto item;
  final void Function(BuildContext context, String movieNumber) onOpenMovie;
  final void Function(BuildContext context, String movieNumber) onOpenDownloads;
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = movieSubscriptionManagerProvider(
      ref.watch(movieSubscriptionStatusSelectionProvider),
    );
    final selectionMode = ref.watch(
      managerProvider.select(
        (asyncState) => asyncState.value?.selectionMode ?? false,
      ),
    );
    final isSelected = ref.watch(
      managerProvider.select(
        (asyncState) => asyncState.value?.isSelected(item.movieNumber) ?? false,
      ),
    );
    final isPending = ref.watch(
      managerProvider.select(
        (asyncState) => asyncState.value?.isPending(item.movieNumber) ?? false,
      ),
    );
    final notifier = ref.read(managerProvider.notifier);
    final deleting = useState(false);
    final tasksProvider = movieDownloadTasksProvider(item.movieNumber);
    final tasks = ref.watch(tasksProvider).value;

    return MovieSubscriptionRow(
      item: item,
      mobile: mobile,
      selectionMode: selectionMode,
      isSelected: isSelected,
      isPending: isPending || deleting.value,
      onTap: selectionMode
          ? () => notifier.toggleSelection(item.movieNumber)
          : () => onOpenMovie(context, item.movieNumber),
      onOpenDownloads: tasks?.isNotEmpty == true
          ? () => onOpenDownloads(context, item.movieNumber)
          : null,
      onSearchMagnet: () => showMovieMagnetSearchDialog(
        context: context,
        movieNumber: item.movieNumber,
      ),
      onDeleteDownloads: tasks == null || tasks.isEmpty
          ? null
          : () async {
              deleting.value = true;
              try {
                final currentTasks = await ref.refresh(tasksProvider.future);
                if (!context.mounted) return;
                if (currentTasks.isEmpty) {
                  showToast('下载任务已不存在');
                  await notifier.refresh();
                  return;
                }
                final api = ref.read(downloadsApiProvider);
                deleting.value = false;
                var removed = false;
                await showDownloadTaskDeleteDialog(
                  context,
                  tasks: currentTasks,
                  onDelete: (id, deleteFiles) async {
                    await api.deleteDownloadTask(id, deleteFiles: deleteFiles);
                    removed = true;
                  },
                );
                if (!context.mounted) return;
                if (removed) {
                  ref.invalidate(downloadTaskCenterProvider);
                  await notifier.refresh();
                }
              } catch (error) {
                if (context.mounted) {
                  showToast(apiErrorMessage(error, fallback: '下载任务加载失败'));
                }
              } finally {
                if (context.mounted) deleting.value = false;
              }
            },
      onUnsubscribe: () => unawaited(_unsubscribeRow(ref, item.movieNumber)),
    );
  }
}

/// 单条取消订阅不弹确认：它是可逆的（重新订阅即可）、也不删任何文件，
/// 二次确认只会让日常清理变啰嗦。批量才确认——那一下影响面大得多。
Future<void> _unsubscribeRow(WidgetRef ref, String movieNumber) async {
  final managerProvider = movieSubscriptionManagerProvider(
    ref.read(movieSubscriptionStatusSelectionProvider),
  );
  final result = await ref
      .read(managerProvider.notifier)
      .unsubscribe(movieNumber);
  showMovieSubscriptionFeedback(result);
}
