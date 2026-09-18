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

String rankingPeriodLabel(String period) {
  switch (period) {
    case 'daily':
      return '日榜';
    case 'weekly':
      return '周榜';
    case 'monthly':
      return '月榜';
    // JavDB TOP250 用固定子榜和年份作为周期。
    case 'all':
      return '总榜';
    case 'censored':
      return '有码';
    case 'uncensored':
      return '无码';
    case 'fc2':
      return 'FC2';
  }
  if (period.length == 4 && int.tryParse(period) != null) {
    return '$period年';
  }
  return period;
}
