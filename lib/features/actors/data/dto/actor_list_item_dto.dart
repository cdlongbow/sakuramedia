import 'package:sakuramedia/core/json/json_parse.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';

class ActorListItemDto {
  const ActorListItemDto({
    required this.id,
    required this.javdbId,
    required this.name,
    required this.aliasName,
    required this.profileImage,
    required this.isSubscribed,
    this.apiDisplayName,
    this.movieCount = 0,
    this.age,
    this.birthday,
    this.heightCm,
    this.bustCm,
    this.waistCm,
    this.hipsCm,
    this.cup,
  });

  final int id;
  final String javdbId;
  final String name;
  final String aliasName;
  final MovieImageDto? profileImage;
  final bool isSubscribed;
  final String? apiDisplayName;
  final int movieCount;
  final int? age;
  final DateTime? birthday;
  final int? heightCm;
  final int? bustCm;
  final int? waistCm;
  final int? hipsCm;
  final String? cup;

  String get displayName {
    final normalized = apiDisplayName?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return aliasName.trim().isNotEmpty ? aliasName : name;
  }

  ActorListItemDto copyWith({
    int? id,
    String? javdbId,
    String? name,
    String? aliasName,
    MovieImageDto? profileImage,
    bool? isSubscribed,
    String? apiDisplayName,
  }) {
    return ActorListItemDto(
      id: id ?? this.id,
      javdbId: javdbId ?? this.javdbId,
      name: name ?? this.name,
      aliasName: aliasName ?? this.aliasName,
      profileImage: profileImage ?? this.profileImage,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      apiDisplayName: apiDisplayName ?? this.apiDisplayName,
      movieCount: this.movieCount,
      age: this.age,
      birthday: this.birthday,
      heightCm: this.heightCm,
      bustCm: this.bustCm,
      waistCm: this.waistCm,
      hipsCm: this.hipsCm,
      cup: this.cup,
    );
  }

  factory ActorListItemDto.fromJson(Map<String, dynamic> json) {
    return ActorListItemDto(
      id: json['id'] as int? ?? 0,
      javdbId: json['javdb_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      aliasName: json['alias_name'] as String? ?? '',
      profileImage: _imageFromJson(json['profile_image']),
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      apiDisplayName: json['display_name'] as String?,
      movieCount: asIntOrNull(json['movie_count']) ?? 0,
      age: asIntOrNull(json['age']),
      birthday: asDateTime(json['birthday']),
      heightCm: asIntOrNull(json['height_cm']),
      bustCm: asIntOrNull(json['bust_cm']),
      waistCm: asIntOrNull(json['waist_cm']),
      hipsCm: asIntOrNull(json['hips_cm']),
      cup: asStringOrNull(json['cup'], trim: true),
    );
  }

  static MovieImageDto? _imageFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MovieImageDto.fromJson(value);
    }
    if (value is Map) {
      return MovieImageDto.fromJson(
        value.map(
          (dynamic key, dynamic data) => MapEntry(key.toString(), data),
        ),
      );
    }
    return null;
  }
}
