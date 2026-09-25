import 'package:sakuramedia/features/rankings/data/ranked_movie_list_item_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 排行榜加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片同形的静态骨架。
List<RankedMovieListItemDto> rankedMoviePlaceholders({int count = 8}) {
  return List<RankedMovieListItemDto>.generate(
    count,
    (index) => RankedMovieListItemDto(
      rank: index + 1,
      javdbId: 'rank-placeholder-${index + 1}',
      movieNumber: 'ABC-${(index + 1).toString().padLeft(3, '0')}',
      title: BoneMock.words(3),
      coverImage: null,
      releaseDate: null,
      durationMinutes: 120,
      heat: 0,
      isSubscribed: false,
      canPlay: false,
    ),
    growable: false,
  );
}
