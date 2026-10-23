import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 概览页次级卡片的标题图标：中性底 + 品牌色图标。
///
/// 主卡「媒体资产」使用渐变图标块，不在这个层级里重复。
class OverviewCardIcon extends StatelessWidget {
  const OverviewCardIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.appSpacing.xl,
      height: context.appSpacing.xl,
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Icon(
        icon,
        size: context.appComponentTokens.iconSizeSm,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
