import 'package:sakuramedia/core/json/json_parse.dart';

/// 人工匹配用的元数据候选。`cover_url` 是后端已缓存的签名图片地址。
class ImportMetadataCandidateDto {
  const ImportMetadataCandidateDto({
    required this.candidateId,
    required this.source,
    required this.sourceName,
    required this.movieNumber,
    required this.title,
    required this.coverUrl,
    required this.releaseDate,
    required this.durationMinutes,
  });

  final String candidateId;

  /// `javdb` 或 `plugin`，用于区分来源标签的强调程度。
  final String source;
  final String sourceName;
  final String movieNumber;
  final String title;
  final String? coverUrl;
  final String? releaseDate;
  final int durationMinutes;

  factory ImportMetadataCandidateDto.fromJson(Map<String, dynamic> json) {
    return ImportMetadataCandidateDto(
      candidateId: json['candidate_id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      movieNumber: json['movie_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      releaseDate: json['release_date'] as String?,
      durationMinutes: asInt(json['duration_minutes']),
    );
  }
}

/// 单个元数据来源查询失败的信息；其余来源的候选仍然可用。
class ImportMetadataSourceErrorDto {
  const ImportMetadataSourceErrorDto({required this.sourceName});

  final String sourceName;

  factory ImportMetadataSourceErrorDto.fromJson(Map<String, dynamic> json) {
    return ImportMetadataSourceErrorDto(
      sourceName: json['source_name'] as String? ?? '',
    );
  }
}

/// `POST /imports/{task_run_id}/failed-items/{item_id}/search` 的响应。
class ImportMetadataSearchResponseDto {
  const ImportMetadataSearchResponseDto({
    required this.movieNumber,
    required this.candidates,
    required this.sourceErrors,
  });

  final String movieNumber;
  final List<ImportMetadataCandidateDto> candidates;
  final List<ImportMetadataSourceErrorDto> sourceErrors;

  factory ImportMetadataSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final rawCandidates = json['candidates'];
    final rawErrors = json['source_errors'];
    return ImportMetadataSearchResponseDto(
      movieNumber: json['movie_number'] as String? ?? '',
      candidates: rawCandidates is List
          ? rawCandidates
                .map(
                  (item) => ImportMetadataCandidateDto.fromJson(asMap(item)),
                )
                .toList(growable: false)
          : const <ImportMetadataCandidateDto>[],
      sourceErrors: rawErrors is List
          ? rawErrors
                .map(
                  (item) => ImportMetadataSourceErrorDto.fromJson(asMap(item)),
                )
                .toList(growable: false)
          : const <ImportMetadataSourceErrorDto>[],
    );
  }
}
