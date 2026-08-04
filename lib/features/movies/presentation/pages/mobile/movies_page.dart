import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/page_cache_keys.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/features/movies/presentation/pages/mobile/movie_filter_drawer.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';

class MobileMoviesPage extends ConsumerStatefulWidget {
  const MobileMoviesPage({super.key});

  @override
  ConsumerState<MobileMoviesPage> createState() => _MobileMoviesPageState();
}

class _MobileMoviesPageState extends ConsumerState<MobileMoviesPage> {
  static const _scope = MovieSummaryScope.movies(
    cacheKey: 'mobile:movies:list',
  );

  late final RiverpodPageHandle _pageCacheHandle;

  @override
  void initState() {
    super.initState();
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: mobileMoviesPageCacheKey(),
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
      surfaceColor: context.appColors.surfaceCard,
      contentKey: const Key('mobile-movies-page'),
      totalKey: const Key('mobile-movies-page-total'),
      sectionSpacing: context.appSpacing.md,
      onMovieTap:
          (context, movieNumber) => MobileMovieDetailRouteData(
            movieNumber: movieNumber,
          ).push(context),
      headerBuilder: _buildMobileHeader,
      useMobileSelectionLayout: true,
      bodyBuilder:
          (context, scrollController, sliver, onRefresh) =>
              AppAdaptiveRefreshScrollView(
                key: const PageStorageKey<String>('mobile:movies:list'),
                onRefresh: onRefresh!,
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[sliver],
              ),
      enableRefresh: true,
      onRefreshFailure: (_) => showToast('刷新失败'),
    );
  }

  Widget _buildMobileHeader(
    BuildContext context,
    MovieSummaryListHeaderArgs args,
  ) {
    return AppListHeader(
      filterButtonKey: const Key('mobile-movies-filter-button'),
      filterTooltip: '筛选',
      filterLabel: args.filterState.triggerLabel,
      onFilterTap: () => _openFilterDrawer(context, args),
      informationSlots: [
        AppListHeaderInfo(
          key: const Key('mobile-movies-total'),
          label: '${args.total} 部',
        ),
      ],
    );
  }

  Future<void> _openFilterDrawer(
    BuildContext context,
    MovieSummaryListHeaderArgs args,
  ) async {
    await showMobileMovieFilterDrawer(
      context,
      current: args.filterState,
      onChanged: args.onApply,
    );
  }
}
