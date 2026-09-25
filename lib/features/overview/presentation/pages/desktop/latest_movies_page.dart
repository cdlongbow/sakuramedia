import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';

/// 「最近添加」全量列表页：概览页分区的「更多」落点，按最新入库分页加载。
class DesktopLatestMoviesPage extends StatelessWidget {
  const DesktopLatestMoviesPage({super.key});

  static const _scope = MovieSummaryScope.latest();

  @override
  Widget build(BuildContext context) {
    return MovieSummaryListContent(
      scope: _scope,
      surfaceColor: context.appColors.surfaceElevated,
      contentKey: const Key('desktop-latest-movies-page'),
      sectionSpacing: context.appSpacing.lg,
      registerPageRefresh: true,
      emptyMessage: '暂无入库影片，去搜索看看吧',
      headerBuilder: (context, args) => AppFilterTotalHeader(
        leading: const SizedBox.shrink(),
        totalText: '${args.total} 部',
        totalKey: const Key('desktop-latest-movies-total'),
      ),
      onMovieTap: (context, movieNumber) => context.pushDesktopMovieDetail(
        movieNumber: movieNumber,
        fallbackPath: desktopLatestMoviesPath,
      ),
      bodyBuilder: (context, scrollController, sliver, _) => CustomScrollView(
        controller: scrollController,
        slivers: [sliver],
      ),
    );
  }
}
