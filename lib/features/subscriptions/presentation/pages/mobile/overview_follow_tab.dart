import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_collection_type_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_state.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/domain/movies/mobile_follow_movie_card.dart';

class MobileOverviewFollowTab extends ConsumerStatefulWidget {
  const MobileOverviewFollowTab({super.key});

  @override
  ConsumerState<MobileOverviewFollowTab> createState() =>
      _MobileOverviewFollowTabState();
}

class _MobileOverviewFollowTabState
    extends ConsumerState<MobileOverviewFollowTab> {
  static const int _detailConcurrentLimit = 1;
  static const int _detailStillImageLimit = 8;
  static const _scope = MovieSummaryScope.subscribedActorsLatest(pageSize: 20);

  late final ScrollController _scrollController;
  final Map<String, _FollowMovieDetailState> _movieDetailStates =
      <String, _FollowMovieDetailState>{};
  final Queue<String> _detailQueue = Queue<String>();
  final Set<String> _queuedMovieNumbers = <String>{};
  int _activeDetailRequests = 0;

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

  Future<void> _toggleMovieSubscription(String movieNumber) async {
    final result = await ref
        .read(movieSummaryProvider(_scope).notifier)
        .toggleSubscription(movieNumber);
    if (!mounted) {
      return;
    }
    showMovieSubscriptionFeedback(result);
  }

  void _ensureMovieDetailLoaded(String movieNumber) {
    if (_movieDetailStates.containsKey(movieNumber)) {
      return;
    }
    _movieDetailStates[movieNumber] = const _FollowMovieDetailState.loading();
    if (mounted) {
      setState(() {});
    }
    if (_activeDetailRequests < _detailConcurrentLimit) {
      unawaited(_loadMovieDetail(movieNumber));
      return;
    }
    if (_queuedMovieNumbers.add(movieNumber)) {
      _detailQueue.add(movieNumber);
    }
  }

  Future<void> _loadMovieDetail(String movieNumber) async {
    _activeDetailRequests += 1;
    try {
      final detail = await ref
          .read(moviesApiProvider)
          .getMovieDetail(movieNumber: movieNumber);
      if (!mounted) {
        return;
      }
      setState(() {
        _movieDetailStates[movieNumber] = _FollowMovieDetailState.success(
          detail: detail,
          stillImageLimit: _detailStillImageLimit,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _movieDetailStates[movieNumber] = const _FollowMovieDetailState.error();
      });
    } finally {
      _activeDetailRequests -= 1;
      _drainDetailQueue();
    }
  }

  void _drainDetailQueue() {
    if (!mounted) {
      _detailQueue.clear();
      _queuedMovieNumbers.clear();
      return;
    }
    while (_activeDetailRequests < _detailConcurrentLimit &&
        _detailQueue.isNotEmpty) {
      final movieNumber = _detailQueue.removeFirst();
      _queuedMovieNumbers.remove(movieNumber);
      unawaited(_loadMovieDetail(movieNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(movieSummaryProvider(_scope));
    ref.listen(movieCollectionTypeEventsProvider, (_, next) {
      final change = next.value;
      if (change == null ||
          change.targetType != MovieCollectionType.collection) {
        return;
      }
      if (_movieDetailStates.containsKey(change.movieNumber) && mounted) {
        _movieDetailStates.remove(change.movieNumber);
        setState(() {});
      }
    });
    return ColoredBox(
      color: context.appColors.surfaceCard,
      child: AppAdaptiveRefreshScrollView(
        onRefresh: _handleRefresh,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[_buildContentSliver(context, moviesAsync)],
      ),
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    AsyncValue<MovieSummaryState> moviesAsync,
  ) {
    final summary = moviesAsync.value;
    final paged = summary?.paged;
    if (moviesAsync.isLoading && summary == null) {
      return const SliverToBoxAdapter(child: _FollowTabLoadingState());
    }

    if (moviesAsync.hasError && summary == null) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            AppEmptyState(
              message: _scope.initialLoadErrorText,
              onRetry:
                  () =>
                      ref.read(movieSummaryProvider(_scope).notifier).reload(),
            ),
          ],
        ),
      );
    }

    if (paged == null || paged.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(child: AppEmptyState(message: '暂无关注影片')),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        top: context.appSpacing.sm,
        bottom: context.appSpacing.md,
      ),
      sliver: SliverList(
        key: const Key('mobile-overview-follow-list'),
        delegate: SliverChildListDelegate(
          _buildFollowListChildren(context, summary),
        ),
      ),
    );
  }

  List<Widget> _buildFollowListChildren(
    BuildContext context,
    MovieSummaryState? summary,
  ) {
    final paged = summary?.paged;
    if (paged == null) {
      return const <Widget>[];
    }
    final children = <Widget>[];
    final showFooter =
        paged.isLoadingMore || paged.loadMoreErrorMessage != null;

    for (var index = 0; index < paged.items.length; index += 1) {
      if (index > 0) {
        children.add(SizedBox(height: context.appSpacing.sm));
      }

      final movie = paged.items[index];
      final detailState = _movieDetailStates[movie.movieNumber];
      children.add(
        MobileFollowMovieCard(
          movie: movie,
          onTap:
              () => MobileMovieDetailRouteData(
                movieNumber: movie.movieNumber,
              ).push(context),
          onSubscriptionTap: () => _toggleMovieSubscription(movie.movieNumber),
          isSubscriptionUpdating:
              summary?.isSubscriptionUpdating(movie.movieNumber) ?? false,
          isDetailLoading:
              detailState == null ||
              detailState.status == _FollowMovieDetailStatus.loading,
          detailStillImageUrls: detailState?.stillImageUrls ?? const [],
          detailSummary: detailState?.summary,
          detailThinCoverUrl: detailState?.thinCoverUrl,
          detailCoverUrl: detailState?.coverUrl,
          onVisible: () => _ensureMovieDetailLoaded(movie.movieNumber),
        ),
      );
    }

    if (showFooter) {
      children.add(SizedBox(height: context.appSpacing.sm));
      children.add(
        AppPagedLoadMoreFooter(
          isLoading: paged.isLoadingMore,
          errorMessage: paged.loadMoreErrorMessage,
          onRetry:
              () => ref.read(movieSummaryProvider(_scope).notifier).loadMore(),
        ),
      );
    }

    return children;
  }

  Future<void> _handleRefresh() async {
    try {
      _movieDetailStates.clear();
      _detailQueue.clear();
      _queuedMovieNumbers.clear();
      _activeDetailRequests = 0;
      await ref.read(movieSummaryProvider(_scope).notifier).refresh();
    } catch (_) {
      if (mounted) {
        showToast('刷新失败');
      }
    }
  }
}

enum _FollowMovieDetailStatus { loading, success, error }

class _FollowMovieDetailState {
  const _FollowMovieDetailState._({
    required this.status,
    required this.summary,
    required this.thinCoverUrl,
    required this.coverUrl,
    required this.stillImageUrls,
  });

  const _FollowMovieDetailState.loading()
    : this._(
        status: _FollowMovieDetailStatus.loading,
        summary: null,
        thinCoverUrl: null,
        coverUrl: null,
        stillImageUrls: const <String>[],
      );

  const _FollowMovieDetailState.error()
    : this._(
        status: _FollowMovieDetailStatus.error,
        summary: null,
        thinCoverUrl: null,
        coverUrl: null,
        stillImageUrls: const <String>[],
      );

  factory _FollowMovieDetailState.success({
    required MovieDetailDto detail,
    required int stillImageLimit,
  }) {
    final stillImageUrls = detail.plotImages
        .map((image) => image.bestAvailableUrl.trim())
        .where((url) => url.isNotEmpty)
        .skip(1)
        .take(stillImageLimit)
        .toList(growable: false);
    final summary =
        detail.summary.trim().isEmpty ? detail.title : detail.summary;
    final thinCoverUrl = _resolveMovieImageUrl(detail.thinCoverImage);
    final coverUrl = _resolveMovieImageUrl(detail.coverImage);
    return _FollowMovieDetailState._(
      status: _FollowMovieDetailStatus.success,
      summary: summary,
      thinCoverUrl: thinCoverUrl,
      coverUrl: coverUrl,
      stillImageUrls: stillImageUrls,
    );
  }

  final _FollowMovieDetailStatus status;
  final String? summary;
  final String? thinCoverUrl;
  final String? coverUrl;
  final List<String> stillImageUrls;
}

String? _resolveMovieImageUrl(MovieImageDto? image) {
  final url = image?.bestAvailableUrl.trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  return url;
}

class _FollowTabLoadingState extends StatelessWidget {
  const _FollowTabLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(
        top: context.appSpacing.sm,
        bottom: context.appSpacing.md,
      ),
      child: Column(
        children: List<Widget>.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == 3 ? 0 : context.appSpacing.sm,
            ),
            child: Container(
              key: Key('mobile-overview-follow-skeleton-$index'),
              height: 216,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: context.appRadius.mdBorder,
              ),
            ),
          );
        }),
      ),
    );
  }
}
