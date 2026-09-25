import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/player/movie_subtitle_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 影片相关加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片 / 药丸同形的静态骨架。

List<MovieListItemDto> movieListItemPlaceholders({int count = 8}) {
  return List<MovieListItemDto>.generate(
    count,
    (index) => MovieListItemDto(
      movieNumber: 'ABC-000',
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
