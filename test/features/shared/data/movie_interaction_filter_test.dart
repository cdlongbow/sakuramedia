import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/shared/data/movie_interaction_filter.dart';
import 'package:sakuramedia/l10n/app_localizations_zh.dart';

void main() {
  test('withRange 支持设置、覆盖和清空单个指标', () {
    final filter = MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.heat, min: 1000)
        .withRange(MovieInteractionMetric.score, min: 8.0, max: 9.5);

    expect(filter.rangeFor(MovieInteractionMetric.heat)?.min, 1000);
    expect(filter.rangeFor(MovieInteractionMetric.score)?.max, 9.5);
    expect(filter.activeMetricCount, 2);
    expect(filter.isDefault, isFalse);

    final cleared = filter.withRange(MovieInteractionMetric.heat);
    expect(cleared.rangeFor(MovieInteractionMetric.heat), isNull);
    expect(cleared.activeMetricCount, 1);

    expect(cleared.clear().isDefault, isTrue);
  });

  test('addQueryParameters 按字段写入 min/max，未设置的方向不发送', () {
    final parameters = <String, dynamic>{};
    MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.heat, min: 1000, max: 5000)
        .withRange(MovieInteractionMetric.score, min: 8.0)
        .addQueryParameters(parameters);

    expect(parameters, <String, dynamic>{
      'heat_min': 1000,
      'heat_max': 5000,
      'score_min': 8.0,
    });
  });

  test('matches 按字段和范围比较，与插入顺序无关', () {
    final first = MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.heat, min: 1000)
        .withRange(MovieInteractionMetric.commentCount, min: 10);
    final second = MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.commentCount, min: 10)
        .withRange(MovieInteractionMetric.heat, min: 1000);

    expect(first.matches(second), isTrue);
    expect(
      first.matches(
        MovieInteractionFilter.initial.withRange(
          MovieInteractionMetric.heat,
          min: 1001,
        ),
      ),
      isFalse,
    );
  });

  test('localizedSummaryLabel 单指标显示范围，多指标折叠为数量', () {
    final l10n = AppLocalizationsZh();
    final single = MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.score, min: 8.0)
        .localizedSummaryLabel(l10n);
    expect(single, contains('8.0'));

    final multiple = MovieInteractionFilter.initial
        .withRange(MovieInteractionMetric.heat, min: 1000)
        .withRange(MovieInteractionMetric.score, min: 8.0)
        .localizedSummaryLabel(l10n);
    expect(multiple, isNot(contains('8.0')));
    expect(multiple, contains('2'));
  });
}
