import 'package:sakuramedia/core/json/json_parse.dart';

class ActivityNotificationDto {
  const ActivityNotificationDto({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.eventType,
    required this.dedupeKey,
    required this.resourceType,
    required this.resourceId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.relatedTaskRunId,
    required this.relatedResourceType,
    required this.relatedResourceId,
  });

  final int id;
  final String category;
  final String title;
  final String content;
  final String? eventType;
  final String? dedupeKey;
  final String? resourceType;
  final int? resourceId;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? relatedTaskRunId;
  final String? relatedResourceType;
  final int? relatedResourceId;

  ActivityNotificationDto copyWith({
    String? category,
    String? title,
    String? content,
    Object? eventType = _sentinel,
    Object? dedupeKey = _sentinel,
    Object? resourceType = _sentinel,
    Object? resourceId = _sentinel,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? relatedTaskRunId = _sentinel,
    Object? relatedResourceType = _sentinel,
    Object? relatedResourceId = _sentinel,
  }) {
    return ActivityNotificationDto(
      id: id,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      eventType: identical(eventType, _sentinel)
          ? this.eventType
          : eventType as String?,
      dedupeKey: identical(dedupeKey, _sentinel)
          ? this.dedupeKey
          : dedupeKey as String?,
      resourceType: identical(resourceType, _sentinel)
          ? this.resourceType
          : resourceType as String?,
      resourceId: identical(resourceId, _sentinel)
          ? this.resourceId
          : resourceId as int?,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      relatedTaskRunId:
          identical(relatedTaskRunId, _sentinel)
              ? this.relatedTaskRunId
              : relatedTaskRunId as int?,
      relatedResourceType:
          identical(relatedResourceType, _sentinel)
              ? this.relatedResourceType
              : relatedResourceType as String?,
      relatedResourceId:
          identical(relatedResourceId, _sentinel)
              ? this.relatedResourceId
              : relatedResourceId as int?,
    );
  }

  ActivityNotificationDto mergeFromServer(ActivityNotificationDto next) {
    return copyWith(
      category: next.category,
      title: next.title,
      content: next.content,
      eventType: next.eventType,
      dedupeKey: next.dedupeKey,
      resourceType: next.resourceType,
      resourceId: next.resourceId,
      isRead: next.isRead,
      createdAt: next.createdAt,
      updatedAt: next.updatedAt,
      relatedTaskRunId: next.relatedTaskRunId,
      relatedResourceType: next.relatedResourceType,
      relatedResourceId: next.relatedResourceId,
    );
  }

  factory ActivityNotificationDto.fromJson(Map<String, dynamic> json) {
    return ActivityNotificationDto(
      id: asInt(json['id']),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      eventType: json['event_type'] as String?,
      dedupeKey: json['dedupe_key'] as String?,
      resourceType: json['resource_type'] as String?,
      resourceId: asIntOrNull(json['resource_id']),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
      relatedTaskRunId: asIntOrNull(json['related_task_run_id']),
      relatedResourceType: json['related_resource_type'] as String?,
      relatedResourceId: asIntOrNull(json['related_resource_id']),
    );
  }

  /// 值相等：轮询/已读回写用它判断是否实质变化，未变则跳过写回，
  /// 避免定时 tick 凭空重建订阅者。
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityNotificationDto &&
        other.id == id &&
        other.category == category &&
        other.title == title &&
        other.content == content &&
        other.eventType == eventType &&
        other.dedupeKey == dedupeKey &&
        other.resourceType == resourceType &&
        other.resourceId == resourceId &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.relatedTaskRunId == relatedTaskRunId &&
        other.relatedResourceType == relatedResourceType &&
        other.relatedResourceId == relatedResourceId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    title,
    content,
    eventType,
    dedupeKey,
    resourceType,
    resourceId,
    isRead,
    createdAt,
    updatedAt,
    relatedTaskRunId,
    relatedResourceType,
    relatedResourceId,
  );
}

const Object _sentinel = Object();
