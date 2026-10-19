class RatingDimensionDto {
  const RatingDimensionDto({
    required this.id,
    required this.name,
    required this.minValue,
    required this.maxValue,
    this.weight = 1,
  });

  final int id;
  final String name;
  final int minValue;
  final int maxValue;

  /// 初版界面不开放权重编辑，保留字段以便与后端约定一致。
  final double weight;

  factory RatingDimensionDto.fromJson(Map<String, dynamic> json) {
    return RatingDimensionDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      minValue: json['min_value'] as int? ?? 0,
      maxValue: json['max_value'] as int? ?? 10,
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
    );
  }
}
