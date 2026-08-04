import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/discovery/data/daily_recommendation_movie_dto.dart';
import 'package:sakuramedia/features/discovery/data/moment_recommendation_dto.dart';
import 'package:sakuramedia/features/discovery/presentation/moment_recommendation_mapping.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_recommendation_feeds_provider.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/image_search/presentation/actions/image_search_launcher.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_grid.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_image.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_preview_launcher.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

class DesktopDiscoverMoviesPage extends StatelessWidget {
  const DesktopDiscoverMoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DiscoveryMoviesPage(platform: _DiscoveryListPlatform.desktop);
  }
}

class DesktopDiscoverMomentsPage extends StatelessWidget {
  const DesktopDiscoverMomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DiscoveryMomentsPage(
      platform: _DiscoveryListPlatform.desktop,
    );
  }
}

class MobileDiscoverMoviesPage extends StatelessWidget {
  const MobileDiscoverMoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DiscoveryMoviesPage(platform: _DiscoveryListPlatform.mobile);
  }
}

class MobileDiscoverMomentsPage extends StatelessWidget {
  const MobileDiscoverMomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DiscoveryMomentsPage(platform: _DiscoveryListPlatform.mobile);
  }
}

enum _DiscoveryListPlatform { desktop, mobile }

class _DiscoveryMoviesPage extends HookConsumerWidget {
  const _DiscoveryMoviesPage({required this.platform});

  final _DiscoveryListPlatform platform;

  bool get _isMobile => platform == _DiscoveryListPlatform.mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = dailyRecommendationFeedProvider(_isMobile ? 18 : 24);
    final async = ref.watch(provider);
    final paged =
        async.value ?? const PagedListState<DailyRecommendationMovieDto>();
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 对齐旧 PagedLoadController:loadMore 失败存续期间滚动不自动重试，
        // 恢复分页的唯一入口是 footer 的重试按钮。
        if (paged.loadMoreErrorMessage == null) {
          unawaited(ref.read(provider.notifier).loadMore());
        }
      },
      triggerOffset: 300,
    );

    final showFooter =
        paged.isNotEmpty &&
        (paged.isLoadingMore || paged.loadMoreErrorMessage != null);
    final sliver = SliverMainAxisGroup(
      key: Key(
        _isMobile
            ? 'mobile-discover-movies-page'
            : 'desktop-discover-movies-page',
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFilterTotalHeader(
                leading: const SizedBox.shrink(),
                totalText: '${paged.total} 部',
                totalKey: Key(
                  _isMobile
                      ? 'mobile-discover-movies-total'
                      : 'desktop-discover-movies-total',
                ),
              ),
              SizedBox(
                height:
                    _isMobile ? context.appSpacing.md : context.appSpacing.lg,
              ),
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
                onRetry: () => unawaited(ref.read(provider.notifier).loadMore()),
              ),
            ),
          ),
      ],
    );

    return AppPageRefreshScope(
      onRefresh: () => _handleRefresh(context, ref),
      child:
          _isMobile
              ? ColoredBox(
                color: context.appColors.surfaceCard,
                child: AppAdaptiveRefreshScrollView(
                  controller: scrollController,
                  onRefresh: () => _handleRefresh(context, ref),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[sliver],
                ),
              )
              : ColoredBox(
                color: context.appColors.surfaceElevated,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [sliver],
                ),
              ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final provider = dailyRecommendationFeedProvider(_isMobile ? 18 : 24);
    final errorMessage = await ref.read(provider.notifier).refresh();
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PagedListState<DailyRecommendationMovieDto>> async,
    PagedListState<DailyRecommendationMovieDto> paged,
  ) {
    if (async.hasError) {
      final provider = dailyRecommendationFeedProvider(_isMobile ? 18 : 24);
      return SliverToBoxAdapter(
        child: _RetryEmptyState(
          message: '推荐影片加载失败，请稍后重试',
          onRetry: () => ref.read(provider.notifier).reload(),
        ),
      );
    }
    return MovieSummarySliver(
      items: paged.items.map((item) => item.movie).toList(growable: false),
      isLoading: async.isLoading,
      emptyMessage: '暂无推荐影片，去搜索看看吧',
      placeholderCount: _isMobile ? 6 : 12,
      onMovieTap: (movie) => _openMovieDetail(context, movie.movieNumber),
      onMovieMenuRequest:
          (movie, globalPosition) => requestMovieCollectionMenu(
            context,
            movie.movieNumber,
            globalPosition,
            isSubscribed: movie.isSubscribed,
          ),
    );
  }

  void _openMovieDetail(BuildContext context, String movieNumber) {
    context.push(_movieDetailPath(movieNumber, isMobile: _isMobile));
  }
}

class _DiscoveryMomentsPage extends HookConsumerWidget {
  const _DiscoveryMomentsPage({required this.platform});

  final _DiscoveryListPlatform platform;

  bool get _isMobile => platform == _DiscoveryListPlatform.mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = momentRecommendationFeedProvider(_isMobile ? 18 : 24);
    final async = ref.watch(provider);
    final paged =
        async.value ?? const PagedListState<MomentRecommendationDto>();
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 同影片页：loadMore 失败存续期间滚动不自动重试。
        if (paged.loadMoreErrorMessage == null) {
          unawaited(ref.read(provider.notifier).loadMore());
        }
      },
      triggerOffset: 300,
    );

    final showFooter =
        paged.isNotEmpty &&
        (paged.isLoadingMore || paged.loadMoreErrorMessage != null);
    final sliver = SliverMainAxisGroup(
      key: Key(
        _isMobile
            ? 'mobile-discover-moments-page'
            : 'desktop-discover-moments-page',
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFilterTotalHeader(
                leading: const SizedBox.shrink(),
                totalText: '${paged.total} 个',
                totalKey: Key(
                  _isMobile
                      ? 'mobile-discover-moments-total'
                      : 'desktop-discover-moments-total',
                ),
              ),
              SizedBox(
                height:
                    _isMobile ? context.appSpacing.md : context.appSpacing.lg,
              ),
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
                onRetry: () => unawaited(ref.read(provider.notifier).loadMore()),
              ),
            ),
          ),
      ],
    );

    return AppPageRefreshScope(
      onRefresh: () => _handleRefresh(context, ref),
      child:
          _isMobile
              ? ColoredBox(
                color: context.appColors.surfaceCard,
                child: AppAdaptiveRefreshScrollView(
                  controller: scrollController,
                  onRefresh: () => _handleRefresh(context, ref),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[sliver],
                ),
              )
              : ColoredBox(
                color: context.appColors.surfaceElevated,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [sliver],
                ),
              ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final provider = momentRecommendationFeedProvider(_isMobile ? 18 : 24);
    final errorMessage = await ref.read(provider.notifier).refresh();
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PagedListState<MomentRecommendationDto>> async,
    PagedListState<MomentRecommendationDto> paged,
  ) {
    if (async.isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.appLayoutTokens.emptySectionVerticalPadding,
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (async.hasError) {
      final provider = momentRecommendationFeedProvider(_isMobile ? 18 : 24);
      return SliverToBoxAdapter(
        child: _RetryEmptyState(
          message: '推荐时刻加载失败，请稍后重试',
          onRetry: () => ref.read(provider.notifier).reload(),
        ),
      );
    }
    if (paged.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '暂无推荐时刻，播放时添加标记，等定时任务处理后展示'),
      );
    }
    return MomentSliver(
      items: paged.items
          .map((item) => item.toMomentListItem())
          .toList(growable: false),
      onItemTap: (item) => _openMomentPreview(context, item),
    );
  }

  Future<void> _openMomentPreview(
    BuildContext context,
    MomentListItem item,
  ) async {
    final action = await showMomentPreviewOverlay(
      context: context,
      item: item,
      presentation:
          _isMobile
              ? MediaPreviewPresentation.bottomDrawer
              : MediaPreviewPresentation.dialog,
      drawerKey:
          _isMobile
              ? const Key('mobile-discover-moments-preview-bottom-sheet')
              : null,
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

  Future<bool> _searchSimilarFromMoment(
    BuildContext context,
    MomentListItem item,
  ) async {
    final imageUrl = resolveMomentImageUrl(item);
    if (imageUrl.isEmpty) {
      return false;
    }
    if (_isMobile) {
      try {
        await launchImageSearchFromUrl(
          context,
          imageUrl: imageUrl,
          routePath: mobileImageSearchPath,
          fallbackPath: mobileOverviewPath,
          fileName: buildMomentImageFileName(item, imageUrl),
        );
        return true;
      } catch (_) {
        if (context.mounted) {
          showToast('读取结果图片失败，请稍后重试');
        }
        return false;
      }
    }
    await launchDesktopImageSearchFromUrl(
      context,
      imageUrl: imageUrl,
      fallbackPath: desktopDiscoverMomentsPath,
      fileName: buildMomentImageFileName(item, imageUrl),
    );
    return true;
  }

  void _openPlayerForMoment(BuildContext context, MomentListItem item) {
    final movieNumber = item.movieNumber;
    if (movieNumber == null || movieNumber.isEmpty) {
      // discovery 推荐时刻仅 JAV，番号必有；视频时刻不会进入此列表。
      return;
    }
    final path = _moviePlayerPath(
      movieNumber,
      mediaId: item.mediaId > 0 ? item.mediaId : null,
      positionSeconds: item.offsetSeconds,
      isMobile: _isMobile,
    );
    context.push(path);
  }

  void _openMovieDetailForMoment(BuildContext context, MomentListItem item) {
    final movieNumber = item.movieNumber;
    if (movieNumber == null || movieNumber.isEmpty) {
      return;
    }
    context.push(_movieDetailPath(movieNumber, isMobile: _isMobile));
  }
}

class _RetryEmptyState extends StatelessWidget {
  const _RetryEmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppEmptyState(message: message),
        SizedBox(height: context.appSpacing.md),
        AppButton(
          label: '重试',
          size: AppButtonSize.small,
          onPressed: () => unawaited(onRetry()),
        ),
      ],
    );
  }
}

String _movieDetailPath(String movieNumber, {required bool isMobile}) {
  final encoded = Uri.encodeComponent(movieNumber);
  return isMobile
      ? '$mobileMoviesPath/$encoded'
      : '$desktopMoviesPath/$encoded';
}

String _moviePlayerPath(
  String movieNumber, {
  required bool isMobile,
  int? mediaId,
  int? positionSeconds,
}) {
  final encoded = Uri.encodeComponent(movieNumber);
  final basePath = isMobile ? mobileMoviesPath : desktopMoviesPath;
  return Uri(
    path: '$basePath/$encoded/player',
    queryParameters: <String, String>{
      if (mediaId != null) 'mediaId': '$mediaId',
      if (positionSeconds != null) 'positionSeconds': '$positionSeconds',
    },
  ).toString();
}
