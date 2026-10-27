import 'package:sakuramedia/l10n/app_localizations.dart';

class RankingBoardDto {
  const RankingBoardDto({
    required this.sourceKey,
    required this.boardKey,
    required this.name,
    required this.supportedPeriods,
    required this.defaultPeriod,
  });

  final String sourceKey;
  final String boardKey;
  final String name;
  final List<String> supportedPeriods;
  final String? defaultPeriod;

  factory RankingBoardDto.fromJson(Map<String, dynamic> json) {
    final rawSupportedPeriods = json['supported_periods'];
    final supportedPeriods =
        rawSupportedPeriods is List
            ? rawSupportedPeriods
                .whereType<Object?>()
                .map((item) => item?.toString() ?? '')
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
            : const <String>[];
    final defaultPeriod = json['default_period'] as String?;
    return RankingBoardDto(
      sourceKey: json['source_key'] as String? ?? '',
      boardKey: json['board_key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      supportedPeriods: supportedPeriods,
      defaultPeriod:
          defaultPeriod != null && defaultPeriod.isNotEmpty
              ? defaultPeriod
              : null,
    );
  }
}

/// 榜单周期的展示文案。
///
/// [l10n] 传入时按当前语言渲染；未传时回退中文，供尚未接入语言包的调用方
/// （影片详情等）继续使用。
String rankingPeriodLabel(String period, {AppLocalizations? l10n}) {
  switch (period) {
    case 'daily':
      return l10n?.rankingPeriodDaily ?? '日榜';
    case 'weekly':
      return l10n?.rankingPeriodWeekly ?? '周榜';
    case 'monthly':
      return l10n?.rankingPeriodMonthly ?? '月榜';
    // JavDB TOP250 用固定子榜和年份作为周期。
    case 'all':
      return l10n?.rankingPeriodAll ?? '总榜';
    case 'censored':
      return l10n?.rankingPeriodCensored ?? '有码';
    case 'uncensored':
      return l10n?.rankingPeriodUncensored ?? '无码';
    case 'fc2':
      return 'FC2';
  }
  if (period.length == 4 && int.tryParse(period) != null) {
    return l10n?.rankingPeriodYear(period) ?? '$period年';
  }
  return period;
}
