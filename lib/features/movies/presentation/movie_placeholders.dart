import 'package:sakuramedia/features/movies/data/dto/detail/movie_review_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/player/movie_subtitle_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 影片相关加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片 / 药丸同形的静态骨架。

List<MovieListItemDto> movieListItemPlaceholders({int count = 8}) {
  return List<MovieListItemDto>.generate(
    count,
    (index) => MovieListItemDto(
      // 卡片 key 由 movieNumber 派生，占位项必须彼此唯一。
      id: -1 - index,
      movieNumber: 'ABC-${(index + 1).toString().padLeft(3, '0')}',
      title: BoneMock.words(3),
      coverImage: null,
      releaseDate: DateTime(2026, 1, 1),
      durationMinutes: 120,
      heat: 100,
      isSubscribed: false,
      canPlay: false,
      javdbId: null,
    ),
    growable: false,
  );
}

List<MovieReviewDto> movieReviewPlaceholders({int count = 3}) {
  return List<MovieReviewDto>.generate(
    count,
    (index) => MovieReviewDto(
      id: -1 - index,
      score: 4,
      content: BoneMock.paragraph,
      createdAt: DateTime(2026, 1, 1),
      username: BoneMock.words(1),
      likeCount: 3,
      watchCount: 12,
    ),
    growable: false,
  );
}

List<MovieSubtitleItemDto> movieSubtitlePlaceholders({int count = 3}) {
  return List<MovieSubtitleItemDto>.generate(
    count,
    (index) => MovieSubtitleItemDto(
      subtitleId: -1 - index,
      fileName: BoneMock.words(2),
      createdAt: null,
      url: '',
    ),
    growable: false,
  );
}
