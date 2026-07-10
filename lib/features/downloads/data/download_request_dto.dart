import 'package:sakuramedia/core/json/json_parse.dart';

class DownloadTaskDto {
  const DownloadTaskDto({
    required this.id,
    required this.clientId,
    required this.movieNumber,
    required this.name,
    required this.infoHash,
    required this.savePath,
    required this.progress,
    required this.downloadState,
    required this.importStatus,
    required this.importStatusLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int clientId;
  final String? movieNumber;
  final String name;
  final String infoHash;
  final String savePath;
  final double progress;
  final String downloadState;
  final String importStatus;
  final String importStatusLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DownloadTaskDto.fromJson(Map<String, dynamic> json) {
    return DownloadTaskDto(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      movieNumber: json['movie_number'] as String?,
      name: json['name'] as String? ?? '',
      infoHash: json['info_hash'] as String? ?? '',
      savePath: json['save_path'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      downloadState: json['download_state'] as String? ?? '',
      importStatus: json['import_status'] as String? ?? '',
      importStatusLabel: json['import_status_label'] as String? ?? '',
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }

  DownloadTaskDto copyWith({
    int? id,
    int? clientId,
    Object? movieNumber = _sentinel,
    String? name,
    String? infoHash,
    String? savePath,
    double? progress,
    String? downloadState,
    String? importStatus,
    String? importStatusLabel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return DownloadTaskDto(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      movieNumber: identical(movieNumber, _sentinel)
          ? this.movieNumber
          : movieNumber as String?,
      name: name ?? this.name,
      infoHash: infoHash ?? this.infoHash,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      downloadState: downloadState ?? this.downloadState,
      importStatus: importStatus ?? this.importStatus,
      importStatusLabel: importStatusLabel ?? this.importStatusLabel,
      createdAt: identical(createdAt, _sentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();

class DownloadRequestResponseDto {
  const DownloadRequestResponseDto({required this.task, required this.created});

  final DownloadTaskDto task;
  final bool created;

  factory DownloadRequestResponseDto.fromJson(Map<String, dynamic> json) {
    return DownloadRequestResponseDto(
      task: DownloadTaskDto.fromJson(asMap(json['task'])),
      created: json['created'] as bool? ?? false,
    );
  }
}
