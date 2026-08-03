import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sakuramedia/core/format/synced_at_label.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_review_list_item_dto.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_review_period.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/hot_review_filter_sections.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_provider.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_state.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_pull_to_refresh.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/layout/grids/app_adaptive_card_grid.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

typedef HotReviewMovieOpenHandler =
    void Function(BuildContext context, HotReviewListItemDto item);
const double _hotReviewCardHeight = 150;

class DesktopHotReviewsPage extends HookConsumerWidget {
  const DesktopHotReviewsPage({
    super.key,
    this.onOpenMovieDetail,
    this.minColumns = 2,
    this.maxColumns = 4,
    this.targetCardWidth = 420,
    this.enablePullToRefresh = false,
    this.scrollPhysics,
    this.useMobileFilterDrawer = false,
  }) : assert(minColumns >= 1),
       assert(maxColumns >= minColumns),
       assert(targetCardWidth > 0);

  final HotReviewMovieOpenHandler? onOpenMovieDetail;
  final int minColumns;
  final int maxColumns;
  final double targetCardWidth;
  final bool enablePullToRefresh;
  final ScrollPhysics? scrollPhysics;

  /// 顶栏筛选入口点开什么：`true` 弹底部抽屉（移动端），`false` 就地展开浮层
  /// （桌面端）。两端按钮外观、面板内容、即时生效行为完全一致，只有容器不同。
  final bool useMobileFilterDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hotReviewsProvider);
    final state = async.value;
    final paged =
        state?.paged ?? const PagedListState<HotReviewListItemDto>();
    // AsyncLoading 期间（切周期 reload 中）state 无值，从 notifier 读当前周期，
    // 避免顶栏标签闪回默认值。
    final period = state?.period ?? ref.read(hotReviewsProvider.notifier).period;
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 对齐旧基类：loadMore 失败存续期间滚动不自动重试。
        if (paged.loadMoreErrorMessage == null) {
          unawaited(ref.read(hotReviewsProvider.notifier).loadMore());
        }
      },
      triggerOffset: 300,
    );

    final showFooter =
        paged.isNotEmpty &&
        (paged.isLoadingMore || paged.loadMoreErrorMessage != null);
    final slivers = <Widget>[
      SliverMainAxisGroup(
        key: const Key('desktop-hot-reviews-page'),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, scrollController, paged, period),
          ),
          SliverToBoxAdapter(child: SizedBox(height: context.appSpacing.lg)),
          _buildBodySliver(context, ref, async, paged),
          if (showFooter)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: context.appSpacing.md),
                child: AppPagedLoadMoreFooter(
                  isLoading: paged.isLoadingMore,
                  errorMessage: paged.loadMoreErrorMessage,
                  onRetry:
                      () => unawaited(
                        ref.read(hotReviewsProvider.notifier).loadMore(),
                      ),
                ),
              ),
            ),
        ],
      ),
    ];
    final scrollView = CustomScrollView(
      key: const Key('desktop-hot-reviews-scroll-view'),
      physics:
          enablePullToRefresh
              ? scrollPhysics ?? const AlwaysScrollableScrollPhysics()
              : scrollPhysics,
      controller: scrollController,
      slivers: slivers,
    );

    return AppPageRefreshScope(
      onRefresh: () => _handleRefresh(context, ref),
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        child: _buildRefreshableBody(
          context,
          ref,
          scrollController,
          scrollView,
          slivers,
        ),
      ),
    );
  }

  Widget _buildRefreshableBody(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    CustomScrollView scrollView,
    List<Widget> slivers,
  ) {
    if (!enablePullToRefresh) {
      return scrollView;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppAdaptiveRefreshScrollView(
        onRefresh: () => _handleRefresh(context, ref),
        controller: scrollController,
        physics: scrollPhysics ?? const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      );
    }

    return AppPullToRefresh(
      onRefresh: () => _handleRefresh(context, ref),
      child: scrollView,
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final errorMessage =
        await ref.read(hotReviewsProvider.notifier).refresh();
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  Future<void> _applyPeriod(
    WidgetRef ref,
    ScrollController scrollController,
    HotReviewPeriod period,
  ) async {
    final notifier = ref.read(hotReviewsProvider.notifier);
    // 同值去重在这里做（applyFilterState 内部也会短路），避免同值时误 jumpTo(0)。
    if (notifier.period == period) {
      return;
    }
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    await notifier.applyFilterState(period);
  }

  /// 桌面与移动共用同一条顶栏：筛选入口（当前周期）+ 总数 / 抓取时间信息槽。
  /// 差别只在筛选面板的容器——桌面就地浮层，移动底部抽屉。
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    PagedListState<HotReviewListItemDto> paged,
    HotReviewPeriod period,
  ) {
    final syncedAtLabel = formatSyncedAtLabel(paged.syncedAt, withPrefix: false);

    return AppListHeader(
      filterButtonKey: const Key('hot-reviews-filter-trigger'),
      filterIcon: Icons.date_range_rounded,
      filterLabel: period.label,
      filterPanelKey: const Key('hot-reviews-filter-panel'),
      filterPanelExtraWidth: 180,
      onFilterTap:
          useMobileFilterDrawer
              ? () => unawaited(
                _openFilterDrawer(context, ref, scrollController, period),
              )
              : null,
      filterPanelBuilder:
          useMobileFilterDrawer
              ? null
              : (_) => HotReviewFilterSectionGroup(
                period: period,
                onChanged:
                    (next) =>
                        unawaited(_applyPeriod(ref, scrollController, next)),
              ),
      informationSlots: [
        AppListHeaderInfo(
          key: const Key('desktop-hot-reviews-page-total'),
          label: '${paged.total} 条',
        ),
        if (syncedAtLabel != null)
          AppListHeaderInfo(
            key: const Key('hot-reviews-synced-at'),
            label: syncedAtLabel,
            icon: Icons.schedule_rounded,
          ),
      ],
    );
  }

  Future<void> _openFilterDrawer(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    HotReviewPeriod period,
  ) async {
    await showMobileHotReviewFilterDrawer(
      context,
      current: period,
      onChanged:
          (next) => unawaited(_applyPeriod(ref, scrollController, next)),
    );
  }

  Widget _buildBodySliver(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<HotReviewsState> async,
    PagedListState<HotReviewListItemDto> paged,
  ) {
    if (async.isLoading) {
      return _HotReviewSliver(
        isLoading: true,
        items: <HotReviewListItemDto>[],
        minColumns: minColumns,
        maxColumns: maxColumns,
        targetCardWidth: targetCardWidth,
      );
    }

    if (async.hasError && paged.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '热评加载失败，请稍后重试'),
      );
    }

    if (paged.isEmpty) {
      return const SliverToBoxAdapter(child: AppEmptyState(message: '暂无热评数据'));
    }

    return _HotReviewSliver(
      isLoading: false,
      items: paged.items,
      onItemTap: (item) => _openMovieDetail(context, item),
      minColumns: minColumns,
      maxColumns: maxColumns,
      targetCardWidth: targetCardWidth,
    );
  }

  void _openMovieDetail(BuildContext context, HotReviewListItemDto item) {
    final movieNumber = item.movie.movieNumber.trim();
    if (movieNumber.isEmpty) {
      return;
    }
    final onOpenMovieDetail = this.onOpenMovieDetail;
    if (onOpenMovieDetail != null) {
      onOpenMovieDetail(context, item);
      return;
    }
    context.pushDesktopMovieDetail(
      movieNumber: movieNumber,
      fallbackPath: desktopHotReviewsPath,
    );
  }
}

class _HotReviewSliver extends StatelessWidget {
  const _HotReviewSliver({
    required this.items,
    required this.isLoading,
    required this.minColumns,
    required this.maxColumns,
    required this.targetCardWidth,
    this.onItemTap,
  });

  final List<HotReviewListItemDto> items;
  final bool isLoading;
  final int minColumns;
  final int maxColumns;
  final double targetCardWidth;
  final ValueChanged<HotReviewListItemDto>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveCardSliver<HotReviewListItemDto>(
      gridKey: const Key('hot-review-grid'),
      items: items,
      isLoading: isLoading,
      placeholderCount: 8,
      minColumns: minColumns,
      maxColumns: maxColumns,
      targetColumnWidth: targetCardWidth,
      mainAxisExtent: _hotReviewCardHeight,
      skeletonBuilder:
          (context, index) => _HotReviewCardSkeleton(
            key: Key('hot-review-card-skeleton-$index'),
          ),
      itemBuilder:
          (context, item, index) => _HotReviewCard(
            item: item,
            onTap: onItemTap == null ? null : () => onItemTap!(item),
          ),
    );
  }
}

class _HotReviewCard extends StatelessWidget {
  const _HotReviewCard({required this.item, this.onTap});

  final HotReviewListItemDto item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final componentTokens = context.appComponentTokens;
    final reviewDate =
        item.createdAt == null
            ? '--/--/--'
            : DateFormat('yy/MM/dd').format(item.createdAt!.toLocal());
    final username = item.username.trim().isEmpty ? '匿名用户' : item.username;
    final content = item.content.trim().isEmpty ? '暂无评论内容' : item.content;
    final compactTextStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s10,
      weight: AppTextWeight.regular,
      tone: AppTextTone.secondary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('hot-review-card-${item.reviewId}'),
        borderRadius: context.appRadius.lgBorder,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: context.appRadius.lgBorder,
            border: Border.all(color: colors.borderSubtle),
            boxShadow: context.appShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width:
                    _hotReviewCardHeight * componentTokens.movieCardAspectRatio,
                child: ColoredBox(
                  key: Key('hot-review-card-cover-pane-${item.reviewId}'),
                  color: colors.surfaceMuted,
                  child: SizedBox.expand(
                    child: MaskedImage(
                      key: Key('hot-review-card-cover-${item.reviewId}'),
                      url: item.movie.coverImage?.bestAvailableUrl ?? '',
                      fit: BoxFit.cover,
                      visibleWidthFactor:
                          context
                              .appComponentTokens
                              .movieCardCoverVisibleWidthFactor,
                      visibleAlignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        key: Key('hot-review-card-meta-row-${item.reviewId}'),
                        children: [
                          Expanded(
                            child: Text(
                              '$username · $reviewDate',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: compactTextStyle,
                            ),
                          ),
                          SizedBox(width: spacing.xs),
                          _MetaStat(
                            icon: Icons.thumb_up_alt_rounded,
                            color: colors.movieCardPlayableBadgeBackground,
                            value: '${item.likeCount}',
                          ),
                          SizedBox(width: spacing.xs),
                          _MetaStat(
                            icon: Icons.star_rounded,
                            color: colors.movieDetailScoreIcon,
                            value: '${item.score}',
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      Expanded(
                        child: SizedBox(
                          key: Key(
                            'hot-review-card-content-box-${item.reviewId}',
                          ),
                          child: SingleChildScrollView(
                            key: Key(
                              'hot-review-card-content-scroll-${item.reviewId}',
                            ),
                            padding: EdgeInsets.zero,
                            child: Text(
                              content,
                              style: resolveAppTextStyle(
                                context,
                                size: AppTextSize.s14,
                                tone: AppTextTone.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compactTextStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s10,
      weight: AppTextWeight.regular,
      tone: AppTextTone.secondary,
    );
    final compactIconSize =
        (resolveAppTextStyle(
              context,
              size: AppTextSize.s10,
              weight: AppTextWeight.regular,
              tone: AppTextTone.muted,
            ).fontSize ??
            context.appComponentTokens.iconSizeXs) +
        1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compactIconSize, color: color),
        SizedBox(width: context.appSpacing.xs),
        Text(value, style: compactTextStyle),
      ],
    );
  }
}

class _HotReviewCardSkeleton extends StatelessWidget {
  const _HotReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final componentTokens = context.appComponentTokens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.lgBorder,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _hotReviewCardHeight * componentTokens.movieCardAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.surfaceMuted),
              child: SizedBox.expand(
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: context.appComponentTokens.iconSize2xl,
                    color: context.appTextPalette.muted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewSkeletonLine(width: 112),
                  SizedBox(height: spacing.xs),
                  _ReviewSkeletonLine(width: 168),
                  SizedBox(height: spacing.sm),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceMuted,
                        borderRadius: context.appRadius.smBorder,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(spacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ReviewSkeletonLine(width: double.infinity),
                            SizedBox(height: spacing.xs),
                            const _ReviewSkeletonLine(width: double.infinity),
                            SizedBox(height: spacing.xs),
                            const _ReviewSkeletonLine(width: 144),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSkeletonLine extends StatelessWidget {
  const _ReviewSkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: context.appColors.borderSubtle,
        borderRadius: context.appRadius.smBorder,
      ),
    );
  }
}
