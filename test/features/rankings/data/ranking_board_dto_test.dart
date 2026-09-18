import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/rankings/data/ranking_board_dto.dart';

void main() {
  test('ranking period labels cover board periods and TOP250 sub periods', () {
    expect(rankingPeriodLabel('daily'), '日榜');
    expect(rankingPeriodLabel('weekly'), '周榜');
    expect(rankingPeriodLabel('monthly'), '月榜');
    expect(rankingPeriodLabel('all'), '总榜');
    expect(rankingPeriodLabel('censored'), '有码');
    expect(rankingPeriodLabel('uncensored'), '无码');
    expect(rankingPeriodLabel('fc2'), 'FC2');
    expect(rankingPeriodLabel('2026'), '2026年');
    expect(rankingPeriodLabel(''), '');
    expect(rankingPeriodLabel('custom'), 'custom');
  });
}
