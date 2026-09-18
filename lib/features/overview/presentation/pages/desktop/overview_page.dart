import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_state.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/providers/overview_system_info_provider.dart';
import 'package:sakuramedia/features/overview/presentation/providers/recently_played_playlist_provider.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/asset_summary_card.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/storage_usage_card.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/watch_trend_card.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/navigation/app_section_header.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/widgets/system_diagnostics_strip.dart';

class DesktopOverviewPage extends ConsumerWidget {
  const DesktopOverviewPage({super.key});

  static const _latestScope = MovieSummaryScope.latest();

  /// 宽屏时「观看趋势 + 存储分布」并排；窄窗口堆叠。
  static const double _twoColumnMinWidth = 960;

  /// 预览分区的行数上限（「最近添加」「最近播放」各三行，更多内容进各自页面）。
  static const int _previewMaxRows = 3;

  Future<void> _refreshOverview(WidgetRef ref) async {
    final recentPlaylist = ref
        .read(recentlyPlayedPlaylistProvider)
        .value;
    final futures = <Future<void>>[
      // 沿用旧行为:桌面刷新走 load()(不置 loading 标志),卡片不闪骨架。
      ref.read(overviewSystemInfoProvider.notifier).load(),
      ref.read(movieSummaryProvider(_latestScope).notifier).refresh(),
    ];
    if (recentPlaylist != null) {
      futures.add(
        ref
            .read(
              movieSummaryProvider(
                MovieSummaryScope.playlist(playlistId: recentPlaylist.id),
              ).notifier,
            )
            .refresh(),
      );
    }
    ref.invalidate(recentlyPlayedPlaylistProvider);
    await Future.wait<void>(futures);
  }

  Future<void> _toggleMovieSubscription(
    WidgetRef ref,
    MovieSummaryScope scope,
    String movieNumber,
  ) async {
    final result = await ref
        .read(movieSummaryProvider(scope).notifier)
        .toggleSubscription(movieNumber);
    showMovieSubscriptionFeedback(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemInfo = ref.watch(overviewSystemInfoProvider);
    final systemInfoNotifier = ref.read(overviewSystemInfoProvider.notifier);
    final latestAsync = ref.watch(movieSummaryProvider(_latestScope));
    final latest = latestAsync.value;
    final recentPlaylist = ref
        .watch(recentlyPlayedPlaylistProvider)
        .value;
    final recentScope = recentPlaylist == null
        ? null
        : MovieSummaryScope.playlist(playlistId: recentPlaylist.id);
    final recentAsync = recentScope == null
        ? null
        : ref.watch(movieSummaryProvider(recentScope));

    return AppPageRefreshScope(
      onRefresh: () => _refreshOverview(ref),
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        child: CustomScrollView(
          slivers: [
            SliverMainAxisGroup(
              slivers: [
                const SliverToBoxAdapter(
                  child: KeyedSubtree(
                    key: Key('overview-page'),
                    child: SystemDiagnosticsStrip(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.appSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: AssetSummaryCard(
                    status: systemInfo.status,
                    insights: systemInfo.insights,
                    pendingIndexCount: pendingIndexCount(
                      systemInfo.imageSearchStatus,
                    ),
                    isLoading: systemInfo.isLoadingStatus,
                    errorMessage: systemInfo.statusError,
                    onRetry: systemInfoNotifier.loadStatus,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.appSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trendCard = WatchTrendCard(
                        trend: systemInfo.watchTrend,
                        range: systemInfo.watchTrendRange,
                        onRangeChanged: systemInfoNotifier.setWatchTrendRange,
                        compactSelector: false,
                        isLoading: systemInfo.isLoadingWatchTrend,
                        errorMessage: systemInfo.watchTrendError,
                        onRetry: systemInfoNotifier.loadWatchTrend,
                      );
                      final storageCard = StorageUsageCard(
                        libraries: systemInfo.insights?.mediaLibraries,
                        isLoading: systemInfo.isLoadingInsights,
                        errorMessage: systemInfo.insightsError,
                        onRetry: systemInfoNotifier.loadInsights,
                      );
                      if (constraints.maxWidth < _twoColumnMinWidth) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            trendCard,
                            SizedBox(height: context.appSpacing.lg),
                            storageCard,
                          ],
                        );
                      }
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: trendCard),
                            SizedBox(width: context.appSpacing.lg),
                            Expanded(child: storageCard),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.appSpacing.xxl),
                ),
                SliverToBoxAdapter(
                  child: AppSectionHeader(
                    title: '最近添加',
                    actionLabel: '更多',
                    actionKey: const Key('overview-latest-more'),
                    onActionTap: () => context.pushDesktopLatestMovies(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: context.appSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: _buildMovieGrid(
                    context,
                    ref: ref,
                    scope: _latestScope,
                    summary: latest,
                    isLoading: latestAsync.isLoading && latest == null,
                    errorMessage: latestAsync.hasError && latest == null
                        ? _latestScope.initialLoadErrorText
                        : null,
                    emptyMessage: '暂无入库影片，去搜索看看吧',
                  ),
                ),
                if (recentPlaylist != null && recentScope != null) ...<Widget>[
                  SliverToBoxAdapter(
                    child: SizedBox(height: context.appSpacing.xxl),
                  ),
                  SliverToBoxAdapter(
                    child: AppSectionHeader(
                      title: '最近播放',
                      trailingText: '${recentPlaylist!.movieCount} 部',
                      actionLabel: '更多',
                      actionKey: const Key('overview-recent-played-more'),
                      onActionTap: () => context.pushDesktopPlaylistDetail(
                        playlistId: recentPlaylist!.id,
                        fallbackPath: desktopOverviewPath,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: context.appSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: _buildMovieGrid(
                      context,
                      ref: ref,
                      scope: recentScope!,
                      summary: recentAsync?.value,
                      isLoading: (recentAsync?.isLoading ?? false) &&
                          recentAsync?.value == null,
                      errorMessage:
                          (recentAsync?.hasError ?? false) &&
                              recentAsync?.value == null
                          ? recentScope.initialLoadErrorText
                          : null,
                      emptyMessage: '还没有观看记录',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid(
    BuildContext context, {
    required WidgetRef ref,
    required MovieSummaryScope scope,
    required MovieSummaryState? summary,
    required bool isLoading,
    required String? errorMessage,
    required String emptyMessage,
  }) {
    return MovieSummaryGrid(
      items: summary?.paged.items ?? const [],
      isLoading: isLoading,
      errorMessage: errorMessage,
      onMovieTap: (movie) => context.pushDesktopMovieDetail(
        movieNumber: movie.movieNumber,
        fallbackPath: desktopOverviewPath,
      ),
      onMovieMenuRequest: (movie, globalPosition) => requestMovieCollectionMenu(
        context,
        movie.movieNumber,
        globalPosition,
        isSubscribed: movie.isSubscribed,
      ),
      onMovieSubscriptionTap: (movie) =>
          _toggleMovieSubscription(ref, scope, movie.movieNumber),
      isMovieSubscriptionUpdating: (movie) =>
          summary?.isSubscriptionUpdating(movie.movieNumber) ?? false,
      emptyMessage: emptyMessage,
      placeholderCount: 12,
      maxRows: _previewMaxRows,
    );
  }
}
