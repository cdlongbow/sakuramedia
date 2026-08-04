import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_review_dto.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';

part 'movie_detail_review_provider.g.dart';

/// 影片评论区状态（自写分页，非 `PagedAsyncNotifierMixin`——热度排序切换
/// 会重置分页，且没有筛选值对象）。迁移前对应
/// `MovieDetailReviewController extends ChangeNotifier with DisposeSafeNotifier`,
/// 由 `movie_detail_inspector_panel.dart` initState 里 new 出。
@immutable
class MovieDetailReviewState {
  const MovieDetailReviewState({
    this.sort = MovieReviewSort.hotly,
    this.items = const <MovieReviewDto>[],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasNextPage = true,
    this.loadedPage = 0,
    this.initialErrorMessage,
    this.loadMoreErrorMessage,
  });

  static const MovieDetailReviewState initial = MovieDetailReviewState();

  final MovieReviewSort sort;
  final List<MovieReviewDto> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final int loadedPage;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;

  MovieDetailReviewState copyWith({
    MovieReviewSort? sort,
    List<MovieReviewDto>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasNextPage,
    int? loadedPage,
    Object? initialErrorMessage = _sentinel,
    Object? loadMoreErrorMessage = _sentinel,
  }) {
    return MovieDetailReviewState(
      sort: sort ?? this.sort,
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      loadedPage: loadedPage ?? this.loadedPage,
      initialErrorMessage: identical(initialErrorMessage, _sentinel)
          ? this.initialErrorMessage
          : initialErrorMessage as String?,
      loadMoreErrorMessage: identical(loadMoreErrorMessage, _sentinel)
          ? this.loadMoreErrorMessage
          : loadMoreErrorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

@riverpod
class MovieDetailReview extends _$MovieDetailReview {
  static const int _pageSize = 20;

  bool _isDisposed = false;
  KeepAliveLink? _cacheLink;

  @override
  MovieDetailReviewState build(String movieNumber) {
    ref.onDispose(() {
      _isDisposed = true;
      _cacheLink?.close();
      _cacheLink = null;
    });
    _cacheLink ??= ref.keepAlive();
    return MovieDetailReviewState.initial;
  }

  KeepAliveLink? get cacheLink => _cacheLink;

  Future<void> loadInitial() async {
    if (_isDisposed || state.isInitialLoading) return;

    state = state.copyWith(
      isInitialLoading: true,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    try {
      final reviews = await ref
          .read(moviesApiProvider)
          .getMovieReviews(
            movieNumber: movieNumber,
            page: 1,
            pageSize: _pageSize,
            sort: state.sort,
          );
      if (_isDisposed) return;
      state = state.copyWith(
        items: reviews,
        loadedPage: 1,
        hasNextPage: reviews.length >= _pageSize,
        initialErrorMessage: null,
      );
    } catch (error) {
      if (_isDisposed) return;
      state = state.copyWith(
        items: const <MovieReviewDto>[],
        loadedPage: 0,
        hasNextPage: true,
        initialErrorMessage: apiErrorMessage(error, fallback: '评论加载失败，请稍后重试。'),
      );
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(isInitialLoading: false);
      }
    }
  }

  Future<void> setSort(MovieReviewSort nextSort) async {
    if (_isDisposed || state.sort == nextSort) return;
    state = state.copyWith(sort: nextSort);
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (_isDisposed ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasNextPage ||
        state.items.isEmpty) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      loadMoreErrorMessage: null,
    );

    final nextPage = state.loadedPage + 1;
    try {
      final reviews = await ref
          .read(moviesApiProvider)
          .getMovieReviews(
            movieNumber: movieNumber,
            page: nextPage,
            pageSize: _pageSize,
            sort: state.sort,
          );
      if (_isDisposed) return;
      if (reviews.isEmpty) {
        state = state.copyWith(hasNextPage: false);
      } else {
        state = state.copyWith(
          items: <MovieReviewDto>[...state.items, ...reviews],
          loadedPage: nextPage,
          hasNextPage: reviews.length >= _pageSize,
          loadMoreErrorMessage: null,
        );
      }
    } catch (error) {
      if (_isDisposed) return;
      state = state.copyWith(
        loadMoreErrorMessage: apiErrorMessage(
          error,
          fallback: '评论加载更多失败，请稍后重试。',
        ),
      );
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }
}
