import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

/// 列表顶栏最左侧的**筛选入口**：图标 + 当前筛选摘要 + 下拉箭头。
///
/// 桌面与移动共用同一份外观：桌面点开就地浮层（`AppFilterPopover` 的
/// `triggerBuilder`），移动点开底部抽屉。**只有容器不同，按钮长得一样。**
///
/// 三条设计约束，改之前先读：
///
/// 1. **常驻态无底色。** 按下反馈由 [AppInteractiveSurface] 统一提供
///    （整体变淡，无 hover/按下底色），不再有常驻浅灰底。
/// 2. **外观恒定，不随「当前有没有筛选生效」变色。** 它是常驻操作，变色会让同
///    一个按钮在两个状态下像两个控件；当前筛选值由 [label] 本身表达（「全部」
///    / 「已订阅」），信息没有丢失。
/// 3. **命中区撑满父级高度。** 视觉区只有 `buttonHeightXs` 高，但手势区
///    吃满整行（顶栏 44），达到 iOS HIG 的 44×44 / 对齐 Material 的 touch
///    target 扩展做法。反馈由同一个 [AppInteractiveSurface] 提供，撑满高度的
///    空白处透明、变淡不可见，视觉上只作用在胶囊上。
class AppFilterEntryButton extends StatelessWidget {
  const AppFilterEntryButton({
    super.key,
    required this.onTap,
    this.icon = Icons.tune_rounded,
    this.label,
    this.tooltip,
    this.trailingIcon = Icons.expand_more_rounded,
  });

  final VoidCallback? onTap;
  final IconData icon;

  /// 当前筛选摘要；为空时退化成纯图标入口（也就不显示下拉箭头）。
  final String? label;

  final String? tooltip;

  /// 尾部箭头；浮层展开时调用方可换成 `Icons.expand_less_rounded`。
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final componentTokens = context.appComponentTokens;
    final resolvedLabel = label;
    const tone = AppTextTone.secondary;
    final foreground = resolveAppTextToneColor(context, tone);

    Widget entry = Semantics(
      button: true,
      label: tooltip,
      child: AppInteractiveSurface(
        // 命中区撑满父级高度（见类文档约束 3）：反馈整体变淡，视觉区只有
        // 中间那颗胶囊，空白处透明、变淡也看不出来，等价于只反馈在胶囊上。
        enabled: onTap != null,
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: Container(
              height: componentTokens.buttonHeightXs,
              padding: EdgeInsets.symmetric(
                horizontal: resolvedLabel == null ? spacing.sm : spacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: componentTokens.iconSizeXs,
                    color: foreground,
                  ),
                  if (resolvedLabel != null) ...[
                    SizedBox(width: spacing.xs),
                    ConstrainedBox(
                      // 摘要可能很长，给个上限免得把信息槽 / 操作槽挤没。
                      constraints: BoxConstraints(
                        maxWidth: componentTokens.mobileFilterEntryMaxLabelWidth,
                      ),
                      child: Text(
                        resolvedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          weight: AppTextWeight.regular,
                          tone: tone,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.xs),
                    Icon(
                      trailingIcon,
                      size: componentTokens.iconSizeXs,
                      color: foreground,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final resolvedTooltip = tooltip;
    if (resolvedTooltip != null && resolvedTooltip.isNotEmpty) {
      entry = Tooltip(message: resolvedTooltip, child: entry);
    }
    return entry;
  }
}
