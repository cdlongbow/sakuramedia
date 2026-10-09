import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_load_more_footer_sliver.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_section_error.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

enum _BlacklistedMovieAction { unblacklist }

/// 系统设置「屏蔽影片」分类页：自持滚动容器，滚到底自动加载下一页
/// （与其它列表页同一套 `usePagedLoadMoreScroll`）。
class BlacklistedMoviesSection extends HookConsumerWidget {
  const BlacklistedMoviesSection({super.key, required this.active});

  /// 分类页是否可见；非活跃时不订阅列表，也不响应滚动加载。
  final bool active;

  static const _scope = MovieSummaryScope.blacklisted();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 首次可见后常驻（IndexedStack 保活），未打开过时不建订阅。
    final activated = useRef(active);
    if (active) {
      activated.value = true;
    }
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // loadMore 失败存续期间滚动不自动重试（对齐 moments/discovery）；
        // 恢复分页的唯一入口是页脚重试按钮。
        final loadMoreError = ref
            .read(movieSummaryProvider(_scope))
            .value
            ?.paged
            .loadMoreErrorMessage;
        if (loadMoreError == null) {
          unawaited(
            ref.read(movieSummaryProvider(_scope).notifier).loadMore(),
          );
        }
      },
      enabled: active,
    );
    if (!activated.value) {
      return const SizedBox.shrink();
    }

    final content = _buildContent(context, ref, scrollController);
    return active
        ? AppPageRefreshScope(
            onRefresh: () =>
                ref.read(movieSummaryProvider(_scope).notifier).reload(),
            child: content,
          )
        : content;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
  ) {
    final spacing = context.appSpacing;
    final async = ref.watch(movieSummaryProvider(_scope));
    final isLoading = !async.hasError && async.value == null;
    final slivers = <Widget>[];

    if (async.hasError) {
      slivers.add(
        SliverToBoxAdapter(
          child: AppSectionError(
            title: '屏蔽影片加载失败',
            message: apiErrorMessage(
              async.error!,
              fallback: '屏蔽影片加载失败，请稍后重试。',
            ),
            onRetry: () =>
                ref.read(movieSummaryProvider(_scope).notifier).reload(),
          ),
        ),
      );
    } else {
      // loading 用占位影片渲染真实海报网格，由 [AppSkeletonizer] 灰化。
      final paged = isLoading
          ? PagedListState<MovieListItemDto>(items: movieListItemPlaceholders())
          : async.value!.paged;
      slivers.addAll(<Widget>[
        SliverToBoxAdapter(
          child: Text(
            '已屏蔽的影片不会出现在普通列表和推荐中。右键影片可取消屏蔽。',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.regular,
              tone: AppTextTone.muted,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: spacing.lg)),
        MovieSummarySliver(
          items: paged.items,
          emptyMessage: '还没有屏蔽任何影片',
          onMovieTap: (movie) => context.pushDesktopMovieDetail(
            movieNumber: movie.movieNumber,
            fallbackPath: desktopMoviesPath,
          ),
          onMovieMenuRequest: (movie, position) =>
              _showMovieActions(context, ref, movie, position),
        ),
        // loadMore 页脚独立订阅：翻页 loading / 失败只重建页脚。
        PagedLoadMoreFooterSliver(
          topSpacing: PagedFooterSpacing.lg,
          watchFooter: (ref) => ref.watch(
            movieSummaryProvider(_scope).select(
              (s) => pagedLoadMoreFooterSnapshot(s.value?.paged),
            ),
          ),
          onLoadMore: (ref) => unawaited(
            ref.read(movieSummaryProvider(_scope).notifier).loadMore(),
          ),
        ),
      ]);
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        AppSkeletonizer.sliver(
          enabled: isLoading,
          child: SliverPadding(
            // 与系统设置其它分类页一致的内边距（右侧 + 底部）。
            padding: EdgeInsets.only(right: spacing.lg, bottom: spacing.xxl),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ),
      ],
    );
  }

  Future<void> _unblacklistMovie(
    BuildContext context,
    WidgetRef ref,
    MovieListItemDto movie,
  ) async {
    try {
      await ref
          .read(movieSummaryProvider(_scope).notifier)
          .unblacklistMovie(movieNumber: movie.movieNumber);
    } catch (error) {
      if (context.mounted) {
        showToast(apiErrorMessage(error, fallback: '取消屏蔽影片失败'));
      }
      return;
    }
    if (context.mounted) {
      showToast('已取消屏蔽影片');
    }
  }

  Future<void> _showMovieActions(
    BuildContext context,
    WidgetRef ref,
    MovieListItemDto movie,
    Offset globalPosition,
  ) async {
    final action = await showAppActionMenu<_BlacklistedMovieAction>(
      context: context,
      globalPosition: globalPosition,
      items: const <AppMenuItem<_BlacklistedMovieAction>>[
        AppMenuItem(
          value: _BlacklistedMovieAction.unblacklist,
          label: '取消屏蔽',
        ),
      ],
    );
    if (action == _BlacklistedMovieAction.unblacklist && context.mounted) {
      await _unblacklistMovie(context, ref, movie);
    }
  }
}
