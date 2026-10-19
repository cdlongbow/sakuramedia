import 'package:sakuramedia/features/shared/data/movie_interaction_filter.dart';

class MovieInteractionDistributionDto {
  const MovieInteractionDistributionDto({this.p999, this.max});

  final num? p999;
  final num? max;

  factory MovieInteractionDistributionDto.fromJson(Object? value) {
    if (value is! Map) {
      return const MovieInteractionDistributionDto();
    }
    final json = value.map(
      (dynamic key, dynamic data) => MapEntry(key.toString(), data),
    );
    return MovieInteractionDistributionDto(
      p999: json['p999'] as num?,
      max: json['max'] as num?,
    );
  }
}

class MovieInteractionFilterOptionsDto {
  const MovieInteractionFilterOptionsDto({
    required this.movieCount,
    required this.heat,
    required this.score,
    required this.scoreNumber,
    required this.watchedCount,
    required this.wantWatchCount,
    required this.commentCount,
  });

  final int movieCount;
  final MovieInteractionDistributionDto heat;
  final MovieInteractionDistributionDto score;
  final MovieInteractionDistributionDto scoreNumber;
  final MovieInteractionDistributionDto watchedCount;
  final MovieInteractionDistributionDto wantWatchCount;
  final MovieInteractionDistributionDto commentCount;

  factory MovieInteractionFilterOptionsDto.fromJson(Map<String, dynamic> json) {
    return MovieInteractionFilterOptionsDto(
      movieCount: json['movie_count'] as int? ?? 0,
      heat: MovieInteractionDistributionDto.fromJson(json['heat']),
      score: MovieInteractionDistributionDto.fromJson(json['score']),
      scoreNumber: MovieInteractionDistributionDto.fromJson(
        json['score_number'],
      ),
      watchedCount: MovieInteractionDistributionDto.fromJson(
        json['watched_count'],
      ),
      wantWatchCount: MovieInteractionDistributionDto.fromJson(
        json['want_watch_count'],
      ),
      commentCount: MovieInteractionDistributionDto.fromJson(
        json['comment_count'],
      ),
    );
  }

  /// 各字段的滑块上限：评分用库内最大分，其余用 P99.9（缺失时退回 MAX）。
  num? sliderMaxFor(MovieInteractionMetric metric) {
    final distribution = switch (metric) {
      MovieInteractionMetric.heat => heat,
      MovieInteractionMetric.score => score,
      MovieInteractionMetric.scoreNumber => scoreNumber,
      MovieInteractionMetric.watchedCount => watchedCount,
      MovieInteractionMetric.wantWatchCount => wantWatchCount,
      MovieInteractionMetric.commentCount => commentCount,
    };
    final candidate = metric == MovieInteractionMetric.score
        ? distribution.max
        : _positive(distribution.p999) ?? distribution.max;
    return _positive(candidate);
  }

  static num? _positive(num? value) =>
      value != null && value > 0 ? value : null;
}
