import 'package:sakuramedia/core/json/json_parse.dart';

/// 批量设置已读状态接口的返回体。
///
/// 后端 `PATCH /system/notifications`（`ids` 或 `all` 指定目标）
/// 返回 `{ updated_count, unread_count }`，前端直接拿 [unreadCount] 刷新角标。
class NotificationReadResultDto {
  const NotificationReadResultDto({
    required this.updatedCount,
    required this.unreadCount,
  });

  final int updatedCount;
  final int unreadCount;

  factory NotificationReadResultDto.fromJson(Map<String, dynamic> json) {
    return NotificationReadResultDto(
      updatedCount: asInt(json['updated_count']),
      unreadCount: asInt(json['unread_count']),
    );
  }
}
