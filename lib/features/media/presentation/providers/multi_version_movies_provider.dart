import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/data/multi_version_movie_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/duplicate_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/invalid_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_browse_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_provider.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/providers/session_scoped_invalidation.dart';

part 'multi_version_movies_provider.g.dart';

@Riverpod(retry: kNoAsyncNotifierRetry)
class MultiVersionMovies extends _$MultiVersionMovies
    with
        PagedAsyncNotifierMixin<
          PagedListState<MultiVersionMovieDto>,
          MultiVersionMovieDto
        > {
  @override
  int get pageSize => 20;
  @override
  String get initialLoadErrorText => '多版本影片加载失败，请稍后重试';
  @override
  String get loadMoreErrorText => '加载更多影片失败，请点击重试';
  @override
  PagedListState<MultiVersionMovieDto> pagedOf(
    PagedListState<MultiVersionMovieDto> state,
  ) => state;
  @override
  PagedListState<MultiVersionMovieDto> applyPaged(
    PagedListState<MultiVersionMovieDto> state,
    PagedListState<MultiVersionMovieDto> paged,
  ) => paged;
  @override
  Future<PaginatedResponseDto<MultiVersionMovieDto>> fetchPage(
    int page,
    int pageSize,
  ) => ref
      .read(mediaApiProvider)
      .getMultiVersionMovies(page: page, pageSize: pageSize);
  @override
  Future<PagedListState<MultiVersionMovieDto>> build() async {
    attachDisposeGuard();
    invalidateOnSignOut(ref);
    return loadInitialPage();
  }

  Future<String?>? _refreshRequest;
  bool _deleting = false;

  @override
  Future<String?> refresh() async {
    if (_deleting) return null;
    if (_refreshRequest != null) return _refreshRequest;
    _refreshRequest = super.refresh();
    try {
      return await _refreshRequest;
    } finally {
      _refreshRequest = null;
    }
  }

  Future<void> deleteVersion(MediaListItemDto item) async {
    // 切换 Tab 时也要等删除结果完成跨页同步。
    final link = ref.keepAlive();
    _deleting = true;
    try {
      // 先收完旧刷新，避免其在删除后回写过期列表。
      await _refreshRequest;
      if (isDisposed) return;
      await ref.read(mediaApiProvider).deleteMedia(mediaId: item.id);
      if (isDisposed) return;
      ref.read(mediaBrowseProvider.notifier).removeItemsByIds([item.id]);
      final duplicates = duplicateMediaProvider(MediaListItemKind.jav);
      final detail = movieDetailProvider(item.movieNumber!);
      // 删除会改变分组数量及排序，从首页重新分页。
      await Future.wait([
        reload(),
        if (ref.exists(duplicates)) ref.read(duplicates.notifier).reload(),
        if (ref.exists(invalidMediaProvider))
          ref.read(invalidMediaProvider.notifier).reload(),
        if (ref.exists(detail))
          ref.read(detail.notifier).refresh().catchError((Object _) {
            // 删除已成功，详情刷新失败不应提示删除失败。
          }),
      ]);
    } finally {
      _deleting = false;
      link.close();
    }
  }
}
