import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_section_error.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

enum _BlacklistedMovieAction { unblacklist }

class BlacklistedMoviesSection extends ConsumerStatefulWidget {
  const BlacklistedMoviesSection({super.key, required this.active});

  final bool active;

  @override
  ConsumerState<BlacklistedMoviesSection> createState() =>
      _BlacklistedMoviesSectionState();
}

class _BlacklistedMoviesSectionState
    extends ConsumerState<BlacklistedMoviesSection> {
  static const _scope = MovieSummaryScope.blacklisted();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tryLoadIfActive();
  }

  @override
  void didUpdateWidget(covariant BlacklistedMoviesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryLoadIfActive();
  }

  void _tryLoadIfActive() {
    if (!widget.active || _initialized) {
      return;
    }
    _initialized = true;
  }

  Future<void> _unblacklistMovie(MovieListItemDto movie) async {
    try {
      await ref
          .read(movieSummaryProvider(_scope).notifier)
          .unblacklistMovie(movieNumber: movie.movieNumber);
    } catch (error) {
      if (mounted) {
        showToast(apiErrorMessage(error, fallback: '取消屏蔽影片失败'));
      }
      return;
    }
    if (mounted) {
      showToast('已取消屏蔽影片');
    }
  }

  Future<void> _refresh() {
    return ref.read(movieSummaryProvider(_scope).notifier).reload();
  }

  Future<void> _showMovieActions(
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
    if (action == _BlacklistedMovieAction.unblacklist && mounted) {
      await _unblacklistMovie(movie);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized && !widget.active) {
      return const SizedBox.shrink();
    }

    final content = _buildContent(context);
    return widget.active
        ? AppPageRefreshScope(onRefresh: _refresh, child: content)
        : content;
  }

  Widget _buildContent(BuildContext context) {
    final async = ref.watch(movieSummaryProvider(_scope));
    if (async.hasError) {
      return AppSectionError(
        title: '屏蔽影片加载失败',
        message: apiErrorMessage(async.error!, fallback: '屏蔽影片加载失败，请稍后重试。'),
        onRetry: () => ref.read(movieSummaryProvider(_scope).notifier).reload(),
      );
    }
    final isLoading = async.value == null;
    // loading 用占位影片渲染真实海报网格，由 [AppSkeletonizer] 灰化。
    final paged = isLoading
        ? PagedListState<MovieListItemDto>(items: movieListItemPlaceholders())
        : async.value!.paged;
    return AppSkeletonizer(
      enabled: isLoading,
      child: _buildLoaded(context, paged),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    PagedListState<MovieListItemDto> paged,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已屏蔽的影片不会出现在普通列表和推荐中。右键影片可取消屏蔽。',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(height: spacing.lg),
        MovieSummaryGrid(
          items: paged.items,
          isLoading: false,
          emptyMessage: '还没有屏蔽任何影片',
          onMovieTap: (movie) => context.pushDesktopMovieDetail(
            movieNumber: movie.movieNumber,
            fallbackPath: desktopMoviesPath,
          ),
          onMovieMenuRequest: _showMovieActions,
        ),
        if (paged.hasMore ||
            paged.isLoadingMore ||
            paged.loadMoreErrorMessage != null) ...[
          SizedBox(height: spacing.lg),
          if (paged.isLoadingMore || paged.loadMoreErrorMessage != null)
            AppPagedLoadMoreFooter(
              isLoading: paged.isLoadingMore,
              errorMessage: paged.loadMoreErrorMessage,
              onRetry: () => unawaited(
                ref.read(movieSummaryProvider(_scope).notifier).loadMore(),
              ),
            )
          else
            Center(
              child: AppButton(
                key: const Key('blacklisted-movies-load-more-button'),
                label: '加载更多',
                onPressed: () => unawaited(
                  ref.read(movieSummaryProvider(_scope).notifier).loadMore(),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
