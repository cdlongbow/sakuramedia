import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/discovery/data/daily_recommendation_movie_dto.dart';
import 'package:sakuramedia/features/discovery/data/hot_actress_release_movie_dto.dart';
import 'package:sakuramedia/features/discovery/data/moment_recommendation_dto.dart';
import 'package:sakuramedia/features/discovery/presentation/moment_recommendation_mapping.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/shared/discovery_recommendation_content.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_preview_providers.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_preview_state.dart';
import 'package:sakuramedia/features/moments/presentation/actions/moment_preview_flow.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/features/moments/presentation/moment_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_state.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_section_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_grid.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

class MobileOverviewDiscoverTab extends ConsumerWidget {
  const MobileOverviewDiscoverTab({super.key});

  static const int _dailyPreviewCount = 6;
  static const int _followPreviewCount = 6;
  static const int _hotActressPreviewCount = 6;
  static const int _momentPreviewCount = 4;
  static const int _dailyPageSize = 10;
  static const int _followPageSize = 10;
  static const int _hotActressPageSize = 10;
  static const int _momentPageSize = 10;
  static const _followScope = MovieSummaryScope.subscribedActorsLatest(
    pageSize: _followPageSize,
    initialLoadErrorText: '女优上新加载失败，请稍后重试',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotActress = ref.watch(
      discoveryHotActressReleasePreviewProvider(_hotActressPageSize),
    );
    final follow = ref.watch(movieSummaryProvider(_followScope));
    final daily = ref.watch(discoveryDailyPreviewProvider(_dailyPageSize));
    final moment = ref.watch(discoveryMomentPreviewProvider(_momentPageSize));

    return AppAdaptiveRefreshScrollView(
      key: const Key('mobile-overview-discover-tab'),
      onRefresh: () => _handleRefresh(ref),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.appSpacing.sm),
              _buildFollowSection(context, ref, follow),
              SizedBox(height: context.appSpacing.lg),
              _buildHotActressSection(context, ref, hotActress),
              SizedBox(height: context.appSpacing.lg),
              _buildDailySection(context, ref, daily),
              SizedBox(height: context.appSpacing.lg),
              _buildMomentSection(context, ref, moment),
              SizedBox(height: context.appSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  /// 三个预览独立刷新，单侧失败不影响其余区块。
  Future<void> _handleRefresh(WidgetRef ref) async {
    await Future.wait(<Future<void>>[
      ref
          .read(
            discoveryHotActressReleasePreviewProvider(
              _hotActressPageSize,
            ).notifier,
          )
          .refresh(),
      ref.read(movieSummaryProvider(_followScope).notifier).refresh(),
      ref
          .read(discoveryDailyPreviewProvider(_dailyPageSize).notifier)
          .refresh(),
      ref
          .read(discoveryMomentPreviewProvider(_momentPageSize).notifier)
          .refresh(),
    ]);
  }

  Widget _buildFollowSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MovieSummaryState> followAsync,
  ) {
    final follow = followAsync.value;
    final paged = follow?.paged;
    final isLoading = followAsync.isLoading && follow == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '女优上新',
          trailingText: '${paged?.total ?? 0} 部',
          actionKey: const Key('mobile-discover-load-more-follow'),
          actionLabel: '更多',
          actionSize: AppTextButtonSize.xSmall,
          onActionTap: () => context.push(mobileFollowPath),
        ),
        SizedBox(height: context.appSpacing.md),
        AppSkeletonizer(
          enabled: isLoading,
          child: MovieSummaryGrid(
            items: isLoading
                ? movieListItemPlaceholders(count: _followPreviewCount)
                : paged?.items.take(_followPreviewCount).toList() ?? const [],
            errorMessage: followAsync.hasError && follow == null
                ? _followScope.initialLoadErrorText
                : null,
            emptyMessage: '暂无女优上新，先订阅感兴趣的女优，等定时任务同步后展示',
            onMovieTap: (movie) => _openMovieDetail(context, movie.movieNumber),
            onMovieMenuRequest: (movie, globalPosition) =>
                requestMovieCollectionMenu(
                  context,
                  movie.movieNumber,
                  globalPosition,
                  isSubscribed: movie.isSubscribed,
                ),
            onMovieSubscriptionTap: (movie) =>
                _toggleFollowSubscription(ref, movie.movieNumber),
            isMovieSubscriptionUpdating: (movie) =>
                follow?.isSubscriptionUpdating(movie.movieNumber) ?? false,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollowSubscription(
    WidgetRef ref,
    String movieNumber,
  ) async {
    final result = await ref
        .read(movieSummaryProvider(_followScope).notifier)
        .toggleSubscription(movieNumber);
    showMovieSubscriptionFeedback(result);
  }

  Widget _buildHotActressSection(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<HotActressReleaseMovieDto> hotActress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '热门新片',
          trailingText: '${hotActress.total} 部',
          actionKey: const Key('mobile-discover-load-more-hot-actress'),
          actionLabel: '更多',
          actionSize: AppTextButtonSize.xSmall,
          onActionTap: () => context.push(mobileHotActressReleasesPath),
        ),
        SizedBox(height: context.appSpacing.md),
        _buildHotActressBody(context, ref, hotActress),
      ],
    );
  }

  Widget _buildHotActressBody(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<HotActressReleaseMovieDto> hotActress,
  ) {
    if (hotActress.errorMessage != null) {
      return DiscoveryRetryEmptyState(
        message: hotActress.errorMessage!,
        onRetry: () => _handleRefresh(ref),
        retryKey: Key(
          'mobile-discover-retry-${hotActress.errorMessage!.hashCode}',
        ),
      );
    }
    final actressNames = <String, String>{
      for (final item in hotActress.items)
        if (item.hotActressName.trim().isNotEmpty)
          item.movie.movieNumber: '热门：${item.hotActressName.trim()}',
    };
    final isLoading = hotActress.isLoading && hotActress.items.isEmpty;
    return AppSkeletonizer(
      enabled: isLoading,
      child: MovieSummaryGrid(
        items: isLoading
            ? movieListItemPlaceholders(count: _hotActressPreviewCount)
            : hotActress.items
                  .take(_hotActressPreviewCount)
                  .map((item) => item.movie)
                  .toList(growable: false),
        emptyMessage: '暂无热门新片，待更多影片积累热度后展示',
        secondaryLabelForMovie: (movie) => actressNames[movie.movieNumber],
        useDefaultSubscriptionActions: true,
        onMovieTap: (movie) => _openMovieDetail(context, movie.movieNumber),
        onMovieMenuRequest: (movie, globalPosition) =>
            requestMovieCollectionMenu(
              context,
              movie.movieNumber,
              globalPosition,
              isSubscribed: movie.isSubscribed,
            ),
      ),
    );
  }

  Widget _buildDailySection(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<DailyRecommendationMovieDto> daily,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '今日推荐',
          trailingText: '${daily.total} 部',
          actionKey: const Key('mobile-discover-load-more-daily'),
          actionLabel: '更多',
          actionSize: AppTextButtonSize.xSmall,
          onActionTap: () => context.push(mobileDiscoverMoviesPath),
        ),
        SizedBox(height: context.appSpacing.md),
        _buildDailyBody(context, ref, daily),
      ],
    );
  }

  Widget _buildDailyBody(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<DailyRecommendationMovieDto> daily,
  ) {
    if (daily.errorMessage != null) {
      return DiscoveryRetryEmptyState(
        message: daily.errorMessage!,
        onRetry: () => _handleRefresh(ref),
        retryKey: Key('mobile-discover-retry-${daily.errorMessage!.hashCode}'),
      );
    }
    final isLoading = daily.isLoading && daily.items.isEmpty;
    return AppSkeletonizer(
      enabled: isLoading,
      child: MovieSummaryGrid(
        items: isLoading
            ? movieListItemPlaceholders(count: _dailyPreviewCount)
            : daily.items
                  .take(_dailyPreviewCount)
                  .map((item) => item.movie)
                  .toList(growable: false),
        emptyMessage: '暂无每日推荐，去搜索看看吧',
        onMovieTap: (movie) => _openMovieDetail(context, movie.movieNumber),
        onMovieMenuRequest: (movie, globalPosition) =>
            requestMovieCollectionMenu(
              context,
              movie.movieNumber,
              globalPosition,
              isSubscribed: movie.isSubscribed,
            ),
      ),
    );
  }

  Widget _buildMomentSection(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<MomentRecommendationDto> moment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '推荐时刻',
          trailingText: '${moment.total} 个',
          actionKey: const Key('mobile-discover-load-more-moments'),
          actionLabel: '更多',
          actionSize: AppTextButtonSize.xSmall,
          onActionTap: () => context.push(mobileDiscoverMomentsPath),
        ),
        SizedBox(height: context.appSpacing.md),
        _buildMomentBody(context, ref, moment),
      ],
    );
  }

  Widget _buildMomentBody(
    BuildContext context,
    WidgetRef ref,
    DiscoveryPreviewState<MomentRecommendationDto> moment,
  ) {
    if (moment.isLoading && moment.items.isEmpty) {
      // loading 用占位时刻渲染真实网格，由 [AppSkeletonizer] 灰化；
      // 刷新保留旧推荐时继续显示旧网格。
      return AppSkeletonizer(
        enabled: true,
        child: MomentGrid(
          items: momentListPlaceholders(count: _momentPreviewCount),
          onItemTap: (_) {},
        ),
      );
    }
    if (moment.errorMessage != null) {
      return DiscoveryRetryEmptyState(
        message: moment.errorMessage!,
        onRetry: () => _handleRefresh(ref),
        retryKey: Key('mobile-discover-retry-${moment.errorMessage!.hashCode}'),
      );
    }
    if (moment.items.isEmpty) {
      return const AppEmptyState(message: '暂无推荐时刻，播放时添加标记，等定时任务处理后展示');
    }
    return MomentGrid(
      items: moment.items
          .take(_momentPreviewCount)
          .map((item) => item.toMomentListItem())
          .toList(growable: false),
      onItemTap: (item) => _openMomentPreview(context, item),
      onItemPlay: (item) => _openPlayerForMoment(context, item),
      onItemOpenMovie: (item) => openMomentSourceMovie(
        context: context,
        item: item,
        fallbackPath: mobileOverviewPath,
      ),
      onItemAddToCollection: (item) => unawaited(
        addMomentItemToCollection(context, item: item, isRecommendation: true),
      ),
    );
  }

  void _openMovieDetail(BuildContext context, String movieNumber) {
    MobileMovieDetailRouteData(movieNumber: movieNumber).push(context);
  }

  Future<void> _openMomentPreview(BuildContext context, MomentListItem item) {
    return showMomentPreviewFlow(
      context: context,
      item: item,
      fallbackPath: mobileOverviewPath,
      drawerKey: const Key('mobile-discover-moment-preview-bottom-sheet'),
      isRecommendation: true,
    );
  }

  void _openPlayerForMoment(BuildContext context, MomentListItem item) {
    unawaited(
      playMomentItem(
        context: context,
        item: item,
        fallbackPath: mobileOverviewPath,
      ),
    );
  }
}
