import 'package:sakuramedia/core/json/json_parse.dart';

/// 单个下载任务的实时进度帧（`snapshot.items[i]` 与 `download_task_updated`）。
///
/// 注意键名易踩：任务级上传速度用 **`uploaded_speed_bytes`（带 d）**，
/// 而客户端级传输帧用 `upload_speed_bytes`（不带 d）—— 两者不同，
/// 见 [DownloadClientTransferDto]。
class DownloadTaskProgressDto {
  const DownloadTaskProgressDto({
    required this.taskId,
    required this.clientId,
    required this.movieNumber,
    required this.name,
    required this.infoHash,
    required this.progress,
    required this.rawState,
    required this.downloadState,
    required this.downloadSpeedBytes,
    required this.uploadedSpeedBytes,
    required this.downloadedBytes,
    required this.totalSizeBytes,
    required this.etaSeconds,
  });

  final int taskId;
  final int clientId;
  final String? movieNumber;
  final String name;
  final String infoHash;
  final double progress;
  final String rawState;
  final String downloadState;
  final int downloadSpeedBytes;
  final int uploadedSpeedBytes;
  final int downloadedBytes;
  final int totalSizeBytes;
  final int? etaSeconds;

  factory DownloadTaskProgressDto.fromJson(Map<String, dynamic> json) {
    return DownloadTaskProgressDto(
      taskId: asInt(json['task_id']),
      clientId: asInt(json['client_id']),
      movieNumber: asStringOrNull(json['movie_number']),
      name: json['name'] as String? ?? '',
      infoHash: json['info_hash'] as String? ?? '',
      progress: asDoubleOrNull(json['progress']) ?? 0,
      rawState: json['raw_state'] as String? ?? '',
      downloadState: json['download_state'] as String? ?? '',
      downloadSpeedBytes: asInt(json['download_speed_bytes']),
      uploadedSpeedBytes: asInt(json['uploaded_speed_bytes']),
      downloadedBytes: asInt(json['downloaded_bytes']),
      totalSizeBytes: asInt(json['total_size_bytes']),
      etaSeconds: asIntOrNull(json['eta_seconds']),
    );
  }
}

/// 客户端级传输帧（`download_client_status` 中不含 `status` 字段的形态）。
///
/// 注意：这里的上传字段是 **`upload_speed_bytes`（不带 d）**，与
/// [DownloadTaskProgressDto.uploadedSpeedBytes] 不同。
class DownloadClientTransferDto {
  const DownloadClientTransferDto({
    required this.clientId,
    required this.downloadSpeedBytes,
    required this.uploadSpeedBytes,
    required this.connectionStatus,
  });

  final int clientId;
  final int downloadSpeedBytes;
  final int uploadSpeedBytes;
  final String? connectionStatus;

  factory DownloadClientTransferDto.fromJson(Map<String, dynamic> json) {
    return DownloadClientTransferDto(
      clientId: asInt(json['client_id']),
      downloadSpeedBytes: asInt(json['download_speed_bytes']),
      uploadSpeedBytes: asInt(json['upload_speed_bytes']),
      connectionStatus: asStringOrNull(json['connection_status'], trim: true),
    );
  }
}

/// 客户端健康帧（`download_client_status` 中带 `status` 字段的形态）。
class DownloadClientHealthDto {
  const DownloadClientHealthDto({
    required this.clientId,
    required this.status,
    required this.message,
  });

  final int clientId;
  final String status;
  final String? message;

  bool get isAvailable => status == 'available';

  factory DownloadClientHealthDto.fromJson(Map<String, dynamic> json) {
    return DownloadClientHealthDto(
      clientId: asInt(json['client_id']),
      status: json['status'] as String? ?? '',
      message: asStringOrNull(json['message'], trim: true),
    );
  }
}

/// 任务移除帧 `download_task_removed`。
class DownloadTaskRemovedDto {
  const DownloadTaskRemovedDto({
    required this.taskId,
    required this.clientId,
    required this.movieNumber,
    required this.infoHash,
  });

  final int taskId;
  final int clientId;
  final String? movieNumber;
  final String infoHash;

  factory DownloadTaskRemovedDto.fromJson(Map<String, dynamic> json) {
    return DownloadTaskRemovedDto(
      taskId: asInt(json['task_id']),
      clientId: asInt(json['client_id']),
      movieNumber: asStringOrNull(json['movie_number']),
      infoHash: json['info_hash'] as String? ?? '',
    );
  }
}

/// pause/resume 返回体：`{task_id, action, status}`。
class DownloadTaskActionResultDto {
  const DownloadTaskActionResultDto({
    required this.taskId,
    required this.action,
    required this.status,
  });

  final int taskId;
  final String action;
  final String status;

  factory DownloadTaskActionResultDto.fromJson(Map<String, dynamic> json) {
    return DownloadTaskActionResultDto(
      taskId: asInt(json['task_id']),
      action: json['action'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

/// 下载任务实时流事件的联合体。控制器按 kind 分流合并。
class DownloadTaskStreamEvent {
  const DownloadTaskStreamEvent._({
    required this.kind,
    this.snapshotClientId,
    this.snapshotItems = const <DownloadTaskProgressDto>[],
    this.progress,
    this.removed,
    this.clientTransfer,
    this.clientHealth,
  });

  final DownloadTaskStreamEventKind kind;
  final int? snapshotClientId;
  final List<DownloadTaskProgressDto> snapshotItems;
  final DownloadTaskProgressDto? progress;
  final DownloadTaskRemovedDto? removed;
  final DownloadClientTransferDto? clientTransfer;
  final DownloadClientHealthDto? clientHealth;

  bool get isHeartbeat => kind == DownloadTaskStreamEventKind.heartbeat;
  bool get isSnapshot => kind == DownloadTaskStreamEventKind.snapshot;
  bool get isTaskUpdated => kind == DownloadTaskStreamEventKind.taskUpdated;
  bool get isTaskRemoved => kind == DownloadTaskStreamEventKind.taskRemoved;
  bool get isClientTransfer =>
      kind == DownloadTaskStreamEventKind.clientTransfer;
  bool get isClientHealth => kind == DownloadTaskStreamEventKind.clientHealth;
  bool get isUnknown => kind == DownloadTaskStreamEventKind.unknown;

  factory DownloadTaskStreamEvent.snapshot({
    required int clientId,
    required List<DownloadTaskProgressDto> items,
  }) {
    return DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.snapshot,
      snapshotClientId: clientId,
      snapshotItems: List<DownloadTaskProgressDto>.unmodifiable(items),
    );
  }

  factory DownloadTaskStreamEvent.taskUpdated(DownloadTaskProgressDto value) {
    return DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.taskUpdated,
      progress: value,
    );
  }

  factory DownloadTaskStreamEvent.taskRemoved(DownloadTaskRemovedDto value) {
    return DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.taskRemoved,
      removed: value,
    );
  }

  factory DownloadTaskStreamEvent.clientTransfer(
    DownloadClientTransferDto value,
  ) {
    return DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.clientTransfer,
      clientTransfer: value,
    );
  }

  factory DownloadTaskStreamEvent.clientHealth(DownloadClientHealthDto value) {
    return DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.clientHealth,
      clientHealth: value,
    );
  }

  factory DownloadTaskStreamEvent.heartbeat() {
    return const DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.heartbeat,
    );
  }

  factory DownloadTaskStreamEvent.unknown() {
    return const DownloadTaskStreamEvent._(
      kind: DownloadTaskStreamEventKind.unknown,
    );
  }
}

enum DownloadTaskStreamEventKind {
  snapshot,
  taskUpdated,
  taskRemoved,
  clientTransfer,
  clientHealth,
  heartbeat,
  unknown,
}
