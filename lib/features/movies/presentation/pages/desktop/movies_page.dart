import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/app/cached_page_state_handle.dart';
import 'package:sakuramedia/app/app_page_state_cache_keys.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_list_page_state.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';

class DesktopMoviesPage extends ConsumerStatefulWidget {
  const DesktopMoviesPage({super.key});

  @override
  ConsumerState<DesktopMoviesPage> createState() => _DesktopMoviesPageState();
}

class _DesktopMoviesPageState extends ConsumerState<DesktopMoviesPage> {
  late final CachedPageStateHandle<MovieListPageStateEntry> _pageStateHandle;

  MovieListPageStateEntry get _pageState => _pageStateHandle.value;

  @override
  void initState() {
    super.initState();
    _pageStateHandle = obtainCachedPageState<MovieListPageStateEntry>(
      context,
      key: desktopMoviesPageStateKey(),
      create:
          () => MovieListPageStateEntry(
            moviesApi: ref.read(moviesApiProvider),
            subscriptionChangeNotifier: ref.read(
              movieSubscriptionBroadcasterProvider,
            ),
          ),
    );
  }

  @override
  void dispose() {
    _pageStateHandle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageRefreshScope(
      onRefresh: _pageState.controller.refresh,
      child: MovieListContent(
        pageState: _pageState,
        surfaceColor: context.appColors.surfaceElevated,
        contentKey: const Key('movies-page'),
        totalKey: const Key('movies-page-total'),
        sectionSpacing: context.appSpacing.lg,
        onMovieTap:
            (context, movieNumber) => context.pushDesktopMovieDetail(
              movieNumber: movieNumber,
              fallbackPath: desktopMoviesPath,
            ),
        bodyBuilder:
            (context, scrollController, sliver, _) => CustomScrollView(
              controller: scrollController,
              slivers: [sliver],
            ),
      ),
    );
  }
}
