import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sakuramedia/features/image_search/presentation/desktop_image_search_launcher.dart';
import 'package:sakuramedia/features/moments/presentation/moment_filter_sections.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/features/moments/presentation/providers/moments_provider.dart';
import 'package:sakuramedia/features/moments/presentation/providers/moments_state.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_playback_launcher.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/videos/presentation/pages/mobile/video_player_page.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';
import 'package:sakuramedia/widgets/domain/media/quick_play_dialog.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_grid.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_image.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_preview_launcher.dart';

enum MomentsPagePlatform { desktop, mobile }

class MomentsPage extends HookConsumerWidget {
  const MomentsPage({super.key, required this.platform});

  final MomentsPagePlatform platform;

  bool get _isMobile => platform == MomentsPagePlatform.mobile;

  String get _keyPrefix => _isMobile ? 'mobile-moments' : 'moments';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(momentsProvider);
    final state = async.value;
    final paged = state?.paged ?? const PagedListState<MomentListItem>();
    // AsyncLoading 期间（切筛选 reload 中）state 无值，从 notifier 读当前筛选，
    // 避免顶栏标签闪回默认值。
    final filter = state?.filter ?? ref.read(momentsProvider.notifier).filter;
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 对齐旧基类：loadMore 失败存续期间滚动不自动重试。
        if (paged.loadMoreErrorMessage == null) {
          unawaited(ref.read(momentsProvider.notifier).loadMore());
        }
      },
      triggerOffset: 300,
    );

    final showFooter =
        paged.isNotEmpty &&
        (paged.isLoadingMore || paged.loadMoreErrorMessage != null);
    final sliver = SliverMainAxisGroup(
      key: Key(_isMobile ? 'mobile-overview-moments-tab' : 'moments-page'),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.appSpacing.sm),
              _buildHeader(context, ref, scrollController, paged, filter),
              SizedBox(height: context.appSpacing.md),
            ],
          ),
        ),
        _buildBody(context, ref, async, paged),
        if (showFooter)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: context.appSpacing.md),
              child: AppPagedLoadMoreFooter(
                isLoading: paged.isLoadingMore,
                errorMessage: paged.loadMoreErrorMessage,
                onRetry:
                    () =>
                        unawaited(ref.read(momentsProvider.notifier).loadMore()),
              ),
            ),
          ),
      ],
    );

    return AppPageRefreshScope(
      onRefresh: () => _handleRefresh(context, ref),
      child: ColoredBox(
        color: context.appColors.surfaceCard,
        child:
            _isMobile
                ? AppAdaptiveRefreshScrollView(
                  onRefresh: () => _handleRefresh(context, ref),
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[sliver],
                )
                : CustomScrollView(
                  controller: scrollController,
                  slivers: <Widget>[sliver],
                ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final errorMessage = await ref.read(momentsProvider.notifier).refresh();
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  /// 桌面与移动共用同一条顶栏：筛选入口（当前内容类型）+ 总数信息槽。
  /// 差别只在筛选面板的容器——桌面就地浮层，移动底部抽屉。
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    PagedListState<MomentListItem> paged,
    MomentsFilter filter,
  ) {
    return AppListHeader(
      filterButtonKey: Key('$_keyPrefix-filter-trigger'),
      // 摘要只报「内容类型」这一主维度，排序有独立分节，不堆在入口上。
      filterLabel: filter.kindFilter.label,
      filterPanelKey: Key('$_keyPrefix-filter-panel'),
      filterPanelExtraWidth: 180,
      onFilterTap:
          _isMobile
              ? () => unawaited(
                _openFilterDrawer(context, ref, scrollController, filter),
              )
              : null,
      filterPanelBuilder:
          _isMobile
              ? null
              : (_) => MomentFilterSectionGroup(
                kindFilter: filter.kindFilter,
                sortOrder: filter.sortOrder,
                keyPrefix: _keyPrefix,
                onKindChanged:
                    (next) => _applyFilter(
                      ref,
                      scrollController,
                      (current) => current.copyWith(kindFilter: next),
                    ),
                onSortChanged:
                    (next) => _applyFilter(
                      ref,
                      scrollController,
                      (current) => current.copyWith(sortOrder: next),
                    ),
              ),
      informationSlots: [
        AppListHeaderInfo(
          key: Key('$_keyPrefix-page-total'),
          label: '${paged.total} 个时刻',
        ),
      ],
    );
  }

  Future<void> _openFilterDrawer(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    MomentsFilter filter,
  ) async {
    await showMobileMomentFilterDrawer(
      context,
      kindFilter: filter.kindFilter,
      sortOrder: filter.sortOrder,
      keyPrefix: _keyPrefix,
      onKindChanged:
          (next) => _applyFilter(
            ref,
            scrollController,
            (current) => current.copyWith(kindFilter: next),
          ),
      onSortChanged:
          (next) => _applyFilter(
            ref,
            scrollController,
            (current) => current.copyWith(sortOrder: next),
          ),
    );
  }

  void _applyFilter(
    WidgetRef ref,
    ScrollController scrollController,
    MomentsFilter Function(MomentsFilter current) update,
  ) {
    final notifier = ref.read(momentsProvider.notifier);
    final next = update(notifier.filter);
    // 同值去重在这里做（applyFilterState 内部也会短路），避免同值时误 jumpTo(0)。
    if (next == notifier.filter) {
      return;
    }
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    unawaited(notifier.applyFilterState(next));
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MomentsState> async,
    PagedListState<MomentListItem> paged,
  ) {
    if (async.isLoading) {
      return const SliverToBoxAdapter(child: AppMobileSkeletonList());
    }
    if (async.hasError && paged.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '时刻列表加载失败，请稍后重试'),
      );
    }
    if (paged.isEmpty) {
      return const SliverToBoxAdapter(child: AppEmptyState(message: '暂无时刻数据'));
    }
    return MomentSliver(
      items: paged.items,
      onItemTap: (item) => _openMomentPreview(context, ref, item),
    );
  }

  Future<void> _openMomentPreview(
    BuildContext context,
    WidgetRef ref,
    MomentListItem item,
  ) async {
    final presentation =
        _isMobile
            ? MediaPreviewPresentation.bottomDrawer
            : MediaPreviewPresentation.dialog;
    final action = await showMomentPreviewOverlay(
      context: context,
      item: item,
      presentation: presentation,
      drawerKey:
          _isMobile ? const Key('mobile-moments-preview-bottom-sheet') : null,
      onPointRemoved:
          () => unawaited(ref.read(momentsProvider.notifier).reload()),
      closeOnPointRemoved: true,
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case MediaPreviewAction.searchSimilar:
        await _searchSimilarFromMoment(context, item);
      case MediaPreviewAction.play:
        _openPlayerForMoment(context, item);
      case MediaPreviewAction.openMovieDetail:
        _openMovieDetailForMoment(context, item);
    }
  }

  Future<void> _searchSimilarFromMoment(
    BuildContext context,
    MomentListItem item,
  ) async {
    final imageUrl = resolveMomentImageUrl(item);
    if (imageUrl.isEmpty) {
      return;
    }
    try {
      if (_isMobile) {
        await launchImageSearchFromUrl(
          context,
          imageUrl: imageUrl,
          routePath: mobileImageSearchPath,
          fallbackPath: mobileOverviewPath,
          fileName: buildMomentImageFileName(item, imageUrl),
        );
      } else {
        await launchDesktopImageSearchFromUrl(
          context,
          imageUrl: imageUrl,
          fallbackPath: desktopMomentsPath,
          fileName: buildMomentImageFileName(item, imageUrl),
        );
      }
    } catch (_) {
      if (context.mounted) {
        showToast('读取结果图片失败，请稍后重试');
      }
    }
  }

  void _openPlayerForMoment(BuildContext context, MomentListItem item) {
    if (item.isVideo) {
      if (_isMobile) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder:
                (_) => MobileVideoPlayerPage(
                  videoId: item.videoItemId!,
                  title: item.displayLabel,
                ),
          ),
        );
      } else {
        unawaited(
          showVideoQuickPlayDialog(
            context,
            videoId: item.videoItemId!,
            title: item.displayLabel,
          ),
        );
      }
      return;
    }

    if (_isMobile) {
      unawaited(
        launchMoviePlayback(
          context,
          movieNumber: item.movieNumber!,
          mediaId: item.mediaId > 0 ? item.mediaId : null,
          positionSeconds: item.offsetSeconds,
        ),
      );
      return;
    }

    context.pushDesktopMoviePlayer(
      movieNumber: item.movieNumber!,
      fallbackPath: desktopMomentsPath,
      mediaId: item.mediaId > 0 ? item.mediaId : null,
      positionSeconds: item.offsetSeconds,
    );
  }

  void _openMovieDetailForMoment(BuildContext context, MomentListItem item) {
    if (item.isVideo) {
      return;
    }
    if (_isMobile) {
      MobileMovieDetailRouteData(movieNumber: item.movieNumber!).push(context);
      return;
    }
    context.pushDesktopMovieDetail(
      movieNumber: item.movieNumber!,
      fallbackPath: desktopMomentsPath,
    );
  }
}
