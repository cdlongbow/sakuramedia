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
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_state.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_page_frame.dart';
import 'package:sakuramedia/widgets/base/navigation/app_section_header.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_grid.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

class DesktopDiscoverPage extends ConsumerStatefulWidget {
  const DesktopDiscoverPage({super.key});

  @override
  ConsumerState<DesktopDiscoverPage> createState() =>
      _DesktopDiscoverPageState();
}

class _DesktopDiscoverPageState extends ConsumerState<DesktopDiscoverPage> {
  // 推荐三腿与关注女优上新均由 provider 驱动；本 State 只保留页面交互与导航职责。
  // 桌面发现页保留两行预览的缓冲数据，窗口变化只重排，不重新请求。
  static const int _previewPageSize = 24;
  static const _followScope = MovieSummaryScope.subscribedActorsLatest(
    pageSize: _previewPageSize,
    initialLoadErrorText: '女优上新加载失败，请稍后重试',
  );

  MovieCardHoverFeatureActions get _hoverFeatureActions =>
      movieCardHoverFeatureActions(context);

  /// 三个预览独立刷新，单侧失败不影响其余区块。
  Future<void> _refreshDiscovery() async {
    await Future.wait(<Future<void>>[
      ref
          .read(
            discoveryHotActressReleasePreviewProvider(
              _previewPageSize,
            ).notifier,
          )
          .refresh(),
      ref
          .read(discoveryDailyPreviewProvider(_previewPageSize).notifier)
          .refresh(),
      ref
          .read(discoveryMomentPreviewProvider(_previewPageSize).notifier)
          .refresh(),
    ]);
  }

  Future<void> _handleRefresh() {
    return Future.wait<void>([
      _refreshDiscovery(),
      ref.read(movieSummaryProvider(_followScope).notifier).refresh(),
    ]);
  }

  Future<void> _toggleFollowSubscription(String movieNumber) async {
    final result = await ref
        .read(movieSummaryProvider(_followScope).notifier)
        .toggleSubscription(movieNumber);
    if (!mounted) return;
    showMovieSubscriptionFeedback(result);
  }

  @override
  Widget build(BuildContext context) {
    final hotActress = ref.watch(
      discoveryHotActressReleasePreviewProvider(_previewPageSize),
    );
    final daily = ref.watch(discoveryDailyPreviewProvider(_previewPageSize));
    final moment = ref.watch(discoveryMomentPreviewProvider(_previewPageSize));
    final follow = ref.watch(movieSummaryProvider(_followScope));
    return AppPageRefreshScope(
      onRefresh: _handleRefresh,
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        child: AppPageFrame(
          title: '',
          child: Column(
            key: const Key('desktop-discover-page'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFollowSection(context, follow),
              SizedBox(height: context.appSpacing.xl),
              _buildHotActressSection(context, hotActress),
              SizedBox(height: context.appSpacing.xl),
              _buildDailySection(context, daily),
              SizedBox(height: context.appSpacing.xl),
              _buildMomentSection(context, moment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowSection(
    BuildContext context,
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
          actionKey: const Key('desktop-discover-load-more-follow'),
          actionLabel: '更多',
          onActionTap: () => context.push(desktopFollowPath),
        ),
        SizedBox(height: context.appSpacing.md),
        AppSkeletonizer(
          enabled: isLoading,
          child: MovieSummaryGrid(
            items: isLoading
                ? movieListItemPlaceholders(count: _previewPageSize)
                : paged?.items ?? const [],
            errorMessage: followAsync.hasError && follow == null
                ? _followScope.initialLoadErrorText
                : null,
            onMovieTap: (movie) => _openMovieDetail(movie.movieNumber),
            onMovieMenuRequest: (movie, globalPosition) =>
                requestMovieCollectionMenu(
                  context,
                  movie.movieNumber,
                  globalPosition,
                  isSubscribed: movie.isSubscribed,
                ),
            onMovieSubscriptionTap: (movie) =>
                _toggleFollowSubscription(movie.movieNumber),
            onMovieToggleCollectionType:
                _hoverFeatureActions.toggleCollectionType,
            onMovieBlacklist: _hoverFeatureActions.blacklist,
            isMovieSubscriptionUpdating: (movie) =>
                follow?.isSubscriptionUpdating(movie.movieNumber) ?? false,
            emptyMessage: '暂无女优上新，先订阅感兴趣的女优，等定时任务同步后展示',
            maxRows: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildHotActressSection(
    BuildContext context,
    DiscoveryPreviewState<HotActressReleaseMovieDto> hotActress,
  ) {
    final actressNames = <String, String>{
      for (final item in hotActress.items)
        if (item.hotActressName.trim().isNotEmpty)
          item.movie.movieNumber: '热门：${item.hotActressName.trim()}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '热门新片',
          trailingText: '${hotActress.total} 部',
          actionKey: const Key('desktop-discover-load-more-hot-actress'),
          actionLabel: '更多',
          onActionTap: () => context.push(desktopHotActressReleasesPath),
        ),
        SizedBox(height: context.appSpacing.md),
        AppSkeletonizer(
          enabled: hotActress.isLoading && hotActress.items.isEmpty,
          child: MovieSummaryGrid(
            items: hotActress.isLoading && hotActress.items.isEmpty
                ? movieListItemPlaceholders(count: _previewPageSize)
                : hotActress.items
                      .map((item) => item.movie)
                      .toList(growable: false),
            errorMessage: hotActress.errorMessage,
            onMovieTap: (movie) => _openMovieDetail(movie.movieNumber),
            onMovieMenuRequest: (movie, globalPosition) =>
                requestMovieCollectionMenu(
                  context,
                  movie.movieNumber,
                  globalPosition,
                  isSubscribed: movie.isSubscribed,
                ),
            onMovieToggleCollectionType:
                _hoverFeatureActions.toggleCollectionType,
            onMovieBlacklist: _hoverFeatureActions.blacklist,
            secondaryLabelForMovie: (movie) => actressNames[movie.movieNumber],
            useDefaultSubscriptionActions: true,
            emptyMessage: '暂无热门新片，待更多影片积累热度后展示',
            maxRows: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySection(
    BuildContext context,
    DiscoveryPreviewState<DailyRecommendationMovieDto> daily,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '今日推荐',
          trailingText: '${daily.total} 部',
          actionKey: const Key('desktop-discover-load-more-daily'),
          actionLabel: '更多',
          onActionTap: () => context.push(desktopDiscoverMoviesPath),
        ),
        SizedBox(height: context.appSpacing.md),
        _buildDailyBody(context, daily),
      ],
    );
  }

  Widget _buildDailyBody(
    BuildContext context,
    DiscoveryPreviewState<DailyRecommendationMovieDto> daily,
  ) {
    if (daily.errorMessage != null) {
      return DiscoveryRetryEmptyState(
        message: daily.errorMessage!,
        onRetry: _refreshDiscovery,
        retryKey: Key('desktop-discover-retry-${daily.errorMessage!.hashCode}'),
      );
    }
    final isLoading = daily.isLoading && daily.items.isEmpty;
    return AppSkeletonizer(
      enabled: isLoading,
      child: MovieSummaryGrid(
        items: isLoading
            ? movieListItemPlaceholders(count: _previewPageSize)
            : daily.items.map((item) => item.movie).toList(growable: false),
        emptyMessage: '暂无每日推荐，去搜索看看吧',
        maxRows: 2,
        onMovieTap: (movie) => _openMovieDetail(movie.movieNumber),
        onMovieMenuRequest: (movie, globalPosition) =>
            requestMovieCollectionMenu(
              context,
              movie.movieNumber,
              globalPosition,
              isSubscribed: movie.isSubscribed,
            ),
        onMovieToggleCollectionType: _hoverFeatureActions.toggleCollectionType,
        onMovieBlacklist: _hoverFeatureActions.blacklist,
      ),
    );
  }

  Widget _buildMomentSection(
    BuildContext context,
    DiscoveryPreviewState<MomentRecommendationDto> moment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '推荐时刻',
          trailingText: '${moment.total} 个',
          actionKey: const Key('desktop-discover-load-more-moments'),
          actionLabel: '更多',
          onActionTap: () => context.push(desktopDiscoverMomentsPath),
        ),
        SizedBox(height: context.appSpacing.md),
        _buildMomentBody(context, moment),
      ],
    );
  }

  Widget _buildMomentBody(
    BuildContext context,
    DiscoveryPreviewState<MomentRecommendationDto> moment,
  ) {
    if (moment.isLoading && moment.items.isEmpty) {
      // loading 用占位时刻渲染真实网格，由 [AppSkeletonizer] 灰化。
      return AppSkeletonizer(
        enabled: true,
        child: MomentGrid(
          items: momentListPlaceholders(count: _previewPageSize),
          maxRows: 2,
          onItemTap: _ignoreMomentTap,
        ),
      );
    }
    if (moment.errorMessage != null) {
      return DiscoveryRetryEmptyState(
        message: moment.errorMessage!,
        onRetry: _refreshDiscovery,
        retryKey: Key(
          'desktop-discover-retry-${moment.errorMessage!.hashCode}',
        ),
      );
    }
    if (moment.items.isEmpty) {
      return const AppEmptyState(message: '暂无推荐时刻，播放时添加标记，等定时任务处理后展示');
    }
    return MomentGrid(
      items: moment.items
          .map((item) => item.toMomentListItem())
          .toList(growable: false),
      onItemTap: _openMomentPreview,
      onItemPlay: _openPlayerForMoment,
      onItemOpenMovie: _openMovieDetailForMoment,
      onItemAddToCollection: _addToCollection,
      maxRows: 2,
    );
  }

  void _openMovieDetail(String movieNumber) {
    context.pushDesktopMovieDetail(
      movieNumber: movieNumber,
      fallbackPath: desktopDiscoverPath,
    );
  }

  Future<void> _openMomentPreview(MomentListItem item) {
    return showMomentPreviewFlow(
      context: context,
      item: item,
      fallbackPath: desktopDiscoverPath,
      isRecommendation: true,
    );
  }

  void _openPlayerForMoment(MomentListItem item) {
    unawaited(
      playMomentItem(
        context: context,
        item: item,
        fallbackPath: desktopDiscoverPath,
      ),
    );
  }

  void _openMovieDetailForMoment(MomentListItem item) {
    openMomentSourceMovie(
      context: context,
      item: item,
      fallbackPath: desktopDiscoverPath,
    );
  }

  void _addToCollection(MomentListItem item) {
    unawaited(
      addMomentItemToCollection(context, item: item, isRecommendation: true),
    );
  }
}

void _ignoreMomentTap(MomentListItem _) {}
