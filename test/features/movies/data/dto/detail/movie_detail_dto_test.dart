import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';

void main() {
  test('movie detail parses ranking placements', () {
    final detail = MovieDetailDto.fromJson(<String, dynamic>{
      'rankings': <dynamic>[
        <String, dynamic>{
          'source_key': 'javdb',
          'source_name': 'JavDB',
          'board_key': 'playback_all',
          'board_name': '热播',
          'period': 'daily',
          'rank': 3,
        },
        <String, dynamic>{
          'source_key': 'javdb',
          'source_name': 'JavDB',
          'board_key': 'top250',
          'board_name': 'TOP250',
          'period': '2026',
          'rank': 28,
        },
      ],
    });

    expect(detail.rankings, hasLength(2));
    final daily = detail.rankings.first;
    expect(daily.sourceKey, 'javdb');
    expect(daily.sourceName, 'JavDB');
    expect(daily.boardKey, 'playback_all');
    expect(daily.boardName, '热播');
    expect(daily.period, 'daily');
    expect(daily.periodLabel, '日榜');
    expect(daily.rank, 3);
    expect(detail.rankings.last.periodLabel, '2026年');
  });

  test('movie detail without rankings yields an empty list', () {
    final detail = MovieDetailDto.fromJson(<String, dynamic>{});

    expect(detail.rankings, isEmpty);
  });
}
