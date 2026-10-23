import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';

/// 玻璃材质的圆形图标按钮：默认用于沉浸/媒体内容上的返回键。
///
/// 尺寸、图标和颜色由调用方按场景传入；容器统一走 [AppGlassSurface] 的
/// `chrome` 档，避免移动子页与桌面沉浸顶栏各写一份 Tooltip + 交互表面 + 玻璃。
class AppGlassIconButton extends StatelessWidget {
  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.dimension,
    this.iconSize,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;

  /// 圆形按钮直径；默认 `buttonHeightSm`。
  final double? dimension;

  /// 图标尺寸；默认 `iconSizeSm`。
  final double? iconSize;

  /// 图标颜色；默认 `onMedia`。
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedDimension =
        dimension ?? context.appComponentTokens.buttonHeightSm;
    final resolvedIconSize = iconSize ?? context.appComponentTokens.iconSizeSm;
    final content = AppInteractiveSurface(
      onTap: onPressed,
      semanticLabel: semanticLabel ?? tooltip,
      child: AppGlassSurface(
        tone: AppGlassTone.chrome,
        borderRadius: context.appRadius.pillBorder,
        child: SizedBox.square(
          dimension: resolvedDimension,
          child: Center(
            child: Icon(
              icon,
              size: resolvedIconSize,
              color: iconColor ?? context.appTextPalette.onMedia,
            ),
          ),
        ),
      ),
    );
    final message = tooltip;
    if (message == null) {
      return content;
    }
    return Tooltip(message: message, child: content);
  }
}
