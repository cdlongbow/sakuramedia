import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

/// 「最近添加」全量列表页：概览页分区的「更多」落点，按最新入库分页加载。
class DesktopLatestMoviesPage extends ConsumerStatefulWidget {
  const DesktopLatestMoviesPage({super.key});

  @override
  ConsumerState<DesktopLatestMoviesPage> createState() =>
      _DesktopLatestMoviesPageState();
}

class _DesktopLatestMoviesPageState
    extends ConsumerState<DesktopLatestMoviesPage> {
  static const _scope = MovieSummaryScope.latest();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreIfNeeded);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final summary = ref.read(movieSummaryProvider(_scope)).value;
    if (summary == null ||
        summary.paged.loadMoreErrorMessage != null ||
        position.pixels < position.maxScrollExtent - 300) {
      return;
    }
    unawaited(ref.read(movieSummaryProvider(_scope).notifier).loadMore());
  }

  Future<void> _refresh() async {
    await ref.read(movieSummaryProvider(_scope).notifier).refresh();
  }

  Future<void> _toggleMovieSubscription(String movieNumber) async {
    final result = await ref
        .read(movieSummaryProvider(_scope).notifier)
        .toggleSubscription(movieNumber);
    if (!mounted) {
      return;
    }
    showMovieSubscriptionFeedback(result);
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(movieSummaryProvider(_scope));
    final summary = moviesAsync.value;
    final paged = summary?.paged;
    final isLoading = moviesAsync.isLoading && summary == null;
    final items = isLoading
        ? movieListItemPlaceholders(count: 18)
        : paged?.items ?? const [];
    final showFooter =
        items.isNotEmpty &&
        (paged!.isLoadingMore || paged.loadMoreErrorMessage != null);

    return AppPageRefreshScope(
      onRefresh: _refresh,
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        child: AppFixedHeaderLayout(
          header: AppFilterTotalHeader(
            leading: const SizedBox.shrink(),
            totalText: '${paged?.total ?? 0} 部',
            totalKey: const Key('desktop-latest-movies-total'),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverMainAxisGroup(
                key: const Key('desktop-latest-movies-page'),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: context.appSpacing.lg),
                  ),
                  AppSkeletonizer.sliver(
                    enabled: isLoading,
                    child: MovieSummarySliver(
                      items: items,
                      errorMessage: moviesAsync.hasError && summary == null
                          ? _scope.initialLoadErrorText
                          : null,
                      onMovieTap: (movie) => context.pushDesktopMovieDetail(
                        movieNumber: movie.movieNumber,
                        fallbackPath: desktopLatestMoviesPath,
                      ),
                      onMovieMenuRequest: (movie, globalPosition) =>
                          requestMovieCollectionMenu(
                            context,
                            movie.movieNumber,
                            globalPosition,
                            isSubscribed: movie.isSubscribed,
                          ),
                      onMovieSubscriptionTap: (movie) =>
                          _toggleMovieSubscription(movie.movieNumber),
                      isMovieSubscriptionUpdating: (movie) =>
                          summary?.isSubscriptionUpdating(movie.movieNumber) ??
                          false,
                      emptyMessage: '暂无入库影片，去搜索看看吧',
                    ),
                  ),
                  if (showFooter)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: context.appSpacing.md),
                        child: AppPagedLoadMoreFooter(
                          isLoading: paged.isLoadingMore,
                          errorMessage: paged.loadMoreErrorMessage,
                          onRetry: () => ref
                              .read(movieSummaryProvider(_scope).notifier)
                              .loadMore(),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
