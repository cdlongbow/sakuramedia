/// 「多久以前」的中文相对时间标签。
///
/// 用于"这件事最近一次发生在什么时候"——系统诊断的上次检测、订阅影片的上次资源
/// 查询等。绝对时间戳走 `updated_at_label.dart` 的 `formatUpdatedAtLabel`，两者
/// 语义不同：相对时间回答"新不新鲜"，绝对时间回答"到底是哪一刻"。
library;

/// 把 [moment] 格式化成 `刚刚` / `N 分钟前` / `N 小时前` / `N 天前`。
///
/// [suffix] 追加在单位后面（如传 `'检测'` 得到 `3 天前检测`、`刚刚检测`），默认为空。
/// [now] 仅供测试注入；不传取当前时间。
///
/// 未来时间（[moment] 晚于 [now]）一律归到 `刚刚`——时钟漂移或服务端时区偏差不该
/// 显示成"-3 分钟前"这种明显是 bug 的文案。
String formatRelativeTimeLabel(
  DateTime moment, {
  String suffix = '',
  DateTime? now,
}) {
  final diff = (now ?? DateTime.now()).difference(moment);
  if (diff.inMinutes < 1) return '刚刚$suffix';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前$suffix';
  if (diff.inHours < 24) return '${diff.inHours} 小时前$suffix';
  return '${diff.inDays} 天前$suffix';
}
