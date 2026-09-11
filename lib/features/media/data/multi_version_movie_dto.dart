import 'package:sakuramedia/core/json/json_parse.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';

class MultiVersionMovieDto {
  const MultiVersionMovieDto({
    required this.movieNumber,
    required this.mediaCount,
    required this.mediaItems,
  });

  final String movieNumber;
  final int mediaCount;
  final List<MediaListItemDto> mediaItems;

  factory MultiVersionMovieDto.fromJson(
    Map<String, dynamic> json,
  ) => MultiVersionMovieDto(
    movieNumber: json['movie_number'] as String,
    mediaCount: asInt(json['media_count']),
    mediaItems: (json['media_items'] as List)
        .map(
          (item) =>
              MediaListItemDto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}
