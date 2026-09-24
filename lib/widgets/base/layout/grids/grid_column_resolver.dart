import 'dart:math' as math;

/// 网格列数公式：按目标列宽算出能容纳的列数，并夹在 `[minColumns, maxColumns]`。
///
/// 缩略图面板、切片 / 视频 / 时刻合集详情的网格都用同一套公式，差别只在
/// `targetWidth` 与列数上限；本函数是唯一实现，避免每页各抄一份魔数。
int resolveGridColumnCount({
  required double width,
  required double spacing,
  required double targetWidth,
  int minColumns = 2,
  int maxColumns = 5,
}) {
  final columns = ((width + spacing) / (targetWidth + spacing)).floor();
  return math.max(minColumns, math.min(maxColumns, columns));
}
