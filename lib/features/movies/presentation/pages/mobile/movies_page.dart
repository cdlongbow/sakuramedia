import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/page_cache_keys.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/features/movies/presentation/pages/mobile/movie_filter_drawer.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_provider.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_scope.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/domain/tags/tag_filter_section.dart';

class MobileMoviesPage extends ConsumerStatefulWidget {
  const MobileMoviesPage({super.key});

  @override
  ConsumerState<MobileMoviesPage> createState() => _MobileMoviesPageState();
}

class _MobileMoviesPageState extends ConsumerState<MobileMoviesPage> {
  static const _scope = MovieSummaryScope.movies(
    cacheKey: 'mobile:movies:list',
  );

  /// 影片库的附加标签筛选：选择状态随页面缓存一起保活，避免切页回来后
  /// 「列表按标签过滤、标签面板为空」的不一致；标签数据懒加载。
  static const _tagSelectionScope = TagSelectionScope.custom(
    instanceKey: 'mobile:movies:tags',
    cacheKey: 'mobile:movies:list',
    preload: false,
  );

  late final RiverpodPageHandle _pageCacheHandle;

  /// 供移动筛选抽屉的 footer 实时反映「标签条件是否生效」。
  final ValueNotifier<bool> _tagSelectionActive = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: mobileMoviesPageCacheKey(),
          resolveLinks: () {
            final movieLink = ref
                .read(movieSummaryProvider(_scope).notifier)
                .cacheLink;
            final tagLink = ref
                .read(tagSelectionProvider(_tagSelectionScope).notifier)
                .cacheLink;
            return [?movieLink, ?tagLink];
          },
        );
  }

  @override
  void dispose() {
    _tagSelectionActive.dispose();
    _pageCacheHandle.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tagSelectionProvider(_tagSelectionScope), (_, next) {
      _tagSelectionActive.value = next.hasSelection;
    });
    return MovieSummaryListContent(
      scope: _scope,
      surfaceColor: context.appColors.surfaceCard,
      contentKey: const Key('mobile-movies-page'),
      totalKey: const Key('mobile-movies-page-total'),
      tagSelectionScope: _tagSelectionScope,
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
    final tagSelection = args.tagSelection;
    return AppListHeader(
      filterButtonKey: const Key('mobile-movies-filter-button'),
      filterTooltip: '筛选',
      filterLabel: tagSelection?.hasSelection == true
          ? '标签 · ${tagSelection!.selectedCount}'
          : args.filterState.triggerLabel,
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
    // 抽屉内容是打开那一刻的快照，且页面缓存恢复时 listener 不会补发；
    // 打开前显式同步一次标签生效状态，避免 footer 初始判断错误。
    _tagSelectionActive.value = ref
        .read(tagSelectionProvider(_tagSelectionScope))
        .hasSelection;
    await showMobileMovieFilterDrawer(
      context,
      current: args.filterState,
      onChanged: args.onApply,
      tagSection: TagFilterSection(scope: _tagSelectionScope),
      extraActive: _tagSelectionActive,
      onResetExtra: () {
        ref.read(tagSelectionProvider(_tagSelectionScope).notifier).clear();
      },
    );
  }
}
