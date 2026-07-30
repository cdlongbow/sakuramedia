class PlaylistResolutionOptionDto {
  const PlaylistResolutionOptionDto({
    required this.resolution,
    required this.count,
  });

  final String resolution;
  final int count;

  factory PlaylistResolutionOptionDto.fromJson(Map<String, dynamic> json) {
    return PlaylistResolutionOptionDto(
      resolution: json['resolution'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}
