import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';

/// 「最近订阅」全量列表页：概览页分区的「更多」落点，按订阅时间倒序分页加载。
class DesktopRecentlySubscribedMoviesPage extends StatelessWidget {
  const DesktopRecentlySubscribedMoviesPage({super.key});

  static const _scope = MovieSummaryScope.recentlySubscribed();

  @override
  Widget build(BuildContext context) {
    return MovieSummaryListContent(
      scope: _scope,
      surfaceColor: context.appColors.surfaceElevated,
      contentKey: const Key('desktop-recently-subscribed-movies-page'),
      sectionSpacing: context.appSpacing.lg,
      registerPageRefresh: true,
      emptyMessage: '暂无订阅影片',
      headerBuilder: (context, args) => AppFilterTotalHeader(
        leading: const SizedBox.shrink(),
        totalText: '${args.total} 部',
        totalKey: const Key('desktop-recently-subscribed-movies-total'),
      ),
      onMovieTap: (context, movieNumber) => context.pushDesktopMovieDetail(
        movieNumber: movieNumber,
        fallbackPath: desktopRecentlySubscribedMoviesPath,
      ),
      bodyBuilder: (context, scrollController, sliver, _) => CustomScrollView(
        controller: scrollController,
        slivers: [sliver],
      ),
    );
  }
}
