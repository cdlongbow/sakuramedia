import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/grids/grid_column_resolver.dart';

/// 自然高度卡片网格：按全站统一列数规格切列宽，卡片保持自身内容高度。
///
/// 用于「卡片高度由内容决定、套固定比例 cell 会在标题下方留白」的合集列表；
/// 固定比例网格仍用 `AppAdaptiveCardGrid` / `AppAdaptiveCardSliver`。列数走
/// [resolveAppCardGridColumnCount]，[orientation] 必传（合集卡为横图封面 +
/// 标题行，传 [AppCardGridOrientation.landscape]）。
///
/// 不做滚动容器：调用方按页面结构自行套 `SingleChildScrollView` / sliver。
class AppAdaptiveCardWrap<T> extends StatelessWidget {
  const AppAdaptiveCardWrap({
    super.key,
    required this.items,
    required this.orientation,
    required this.itemBuilder,
    this.minColumns = 2,
    this.maxColumns,
  });

  final List<T> items;
  final AppCardGridOrientation orientation;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int minColumns;
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = resolveGridColumnCount(
          width: constraints.maxWidth,
          spacing: spacing,
          targetWidth: resolveAppCardGridTargetWidth(context, orientation),
          minColumns: minColumns,
          maxColumns:
              maxColumns ?? context.appComponentTokens.cardGridMaxColumns,
        );
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: cardWidth,
                child: itemBuilder(context, items[index], index),
              ),
          ],
        );
      },
    );
  }
}
