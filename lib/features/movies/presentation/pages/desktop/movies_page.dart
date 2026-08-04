import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/page_cache_keys.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';

class DesktopMoviesPage extends ConsumerStatefulWidget {
  const DesktopMoviesPage({super.key});

  @override
  ConsumerState<DesktopMoviesPage> createState() => _DesktopMoviesPageState();
}

class _DesktopMoviesPageState extends ConsumerState<DesktopMoviesPage> {
  static const _scope = MovieSummaryScope.movies(
    cacheKey: 'desktop:movies:list',
  );

  late final RiverpodPageHandle _pageCacheHandle;

  @override
  void initState() {
    super.initState();
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: desktopMoviesPageCacheKey(),
          resolveLinks: () {
            final link =
                ref.read(movieSummaryProvider(_scope).notifier).cacheLink;
            return link == null ? const [] : [link];
          },
        );
  }

  @override
  void dispose() {
    _pageCacheHandle.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MovieSummaryListContent(
      scope: _scope,
      surfaceColor: context.appColors.surfaceElevated,
      contentKey: const Key('movies-page'),
      totalKey: const Key('movies-page-total'),
      sectionSpacing: context.appSpacing.lg,
      registerPageRefresh: true,
      onMovieTap:
          (context, movieNumber) => context.pushDesktopMovieDetail(
            movieNumber: movieNumber,
            fallbackPath: desktopMoviesPath,
          ),
      bodyBuilder:
          (context, scrollController, sliver, _) => CustomScrollView(
            key: const PageStorageKey<String>('desktop:movies:list'),
            controller: scrollController,
            slivers: [sliver],
          ),
    );
  }
}
