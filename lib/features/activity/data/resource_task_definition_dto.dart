import 'package:sakuramedia/core/json/json_parse.dart';

class ResourceTaskStateCountsDto {
  const ResourceTaskStateCountsDto({
    required this.pending,
    required this.running,
    required this.succeeded,
    required this.failed,
    this.failedRetryable = 0,
    this.failedTerminal = 0,
    this.exhausted = 0,
  });

  static const ResourceTaskStateCountsDto empty = ResourceTaskStateCountsDto(
    pending: 0,
    running: 0,
    succeeded: 0,
    failed: 0,
  );

  final int pending;
  final int running;
  final int succeeded;
  final int failed;

  // kernel 记账任务（任务架构 Wave 2 起）的失败三分。
  final int failedRetryable;
  final int failedTerminal;
  final int exhausted;

  /// 全部失败态合计：旧 failed + kernel 三分，tab 徽标与"失败"口径统一用它。
  int get failedTotal => failed + failedRetryable + failedTerminal + exhausted;

  int get total =>
      pending + running + succeeded + failed + failedRetryable + failedTerminal + exhausted;

  factory ResourceTaskStateCountsDto.fromJson(Map<String, dynamic> json) {
    return ResourceTaskStateCountsDto(
      pending: asInt(json['pending']),
      running: asInt(json['running']),
      succeeded: asInt(json['succeeded']),
      failed: asInt(json['failed']),
      failedRetryable: asInt(json['failed_retryable']),
      failedTerminal: asInt(json['failed_terminal']),
      exhausted: asInt(json['exhausted']),
    );
  }

  ResourceTaskStateCountsDto copyWith({
    int? pending,
    int? running,
    int? succeeded,
    int? failed,
  }) {
    return ResourceTaskStateCountsDto(
      pending: pending ?? this.pending,
      running: running ?? this.running,
      succeeded: succeeded ?? this.succeeded,
      failed: failed ?? this.failed,
    );
  }
}

class ResourceTaskDefinitionDto {
  const ResourceTaskDefinitionDto({
    required this.taskKey,
    required this.resourceType,
    required this.displayName,
    required this.defaultSort,
    required this.allowReset,
    required this.stateCounts,
  });

  final String taskKey;
  final String resourceType;
  final String displayName;
  final String? defaultSort;
  final bool allowReset;
  final ResourceTaskStateCountsDto stateCounts;

  factory ResourceTaskDefinitionDto.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['state_counts'];
    return ResourceTaskDefinitionDto(
      taskKey: json['task_key'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      defaultSort: asStringOrNull(json['default_sort'], trim: true),
      allowReset: json['allow_reset'] as bool? ?? false,
      stateCounts:
          rawCounts is Map
              ? ResourceTaskStateCountsDto.fromJson(
                rawCounts.map(
                  (dynamic key, dynamic value) =>
                      MapEntry(key.toString(), value),
                ),
              )
              : ResourceTaskStateCountsDto.empty,
    );
  }

  ResourceTaskDefinitionDto copyWith({ResourceTaskStateCountsDto? stateCounts}) {
    return ResourceTaskDefinitionDto(
      taskKey: taskKey,
      resourceType: resourceType,
      displayName: displayName,
      defaultSort: defaultSort,
      allowReset: allowReset,
      stateCounts: stateCounts ?? this.stateCounts,
    );
  }
}
