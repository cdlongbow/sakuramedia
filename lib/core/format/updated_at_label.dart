import 'package:intl/intl.dart';

/// 复用同一实例：`DateFormat` 构造要解析 pattern，列表行高频调用下应避免重建。
final DateFormat _updatedAtDateFormat = DateFormat('yyyy-MM-dd HH:mm');

/// 将「更新时间 / 最后修改时间」格式化为「yyyy-MM-dd HH:mm」本地时间标签。
/// 无数据时返回 `null`。
String? formatUpdatedAtLabel(DateTime? updatedAt) {
  if (updatedAt == null) {
    return null;
  }
  return _updatedAtDateFormat.format(updatedAt.toLocal());
}
