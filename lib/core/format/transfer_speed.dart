import 'package:sakuramedia/core/format/file_size.dart';

/// 把每秒字节数格式化为可读的传输速率（`… KB/s`）。
///
/// 复用 [formatFileSize] 的单位阶梯以保持文案一致。传 0 得 `0 B/s`。
String formatTransferSpeed(int bytesPerSecond) {
  final normalized = bytesPerSecond < 0 ? 0 : bytesPerSecond;
  return '${formatFileSize(normalized)}/s';
}
