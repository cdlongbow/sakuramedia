import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';

enum AppMediaBadgeSize { compact, prominent }

/// 视频/封面上的玻璃角标：4K/8K、热度、排名共用同一份玻璃材质。
///
/// 玻璃只负责边界和背景；文字/图标仍由这里控制，保证小尺寸下的可读性。
/// 需要固定尺寸时传 [width] / [height]（包含 1px 外圈）。
class AppMediaBadge extends StatelessWidget {
  const AppMediaBadge({
    super.key,
    required this.label,
    this.labelKey,
    this.leading,
    this.width,
    this.height,
    this.padding,
    this.size = AppMediaBadgeSize.compact,
  });

  final String label;
  final Key? labelKey;
  final Widget? leading;
  final double? width;
  final double? height;

  /// 固定尺寸角标可传 `EdgeInsets.zero`，避免默认内边距把文字挤没。
  final EdgeInsetsGeometry? padding;
  final AppMediaBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final compact = size == AppMediaBadgeSize.compact;
    final iconSize = compact ? tokens.iconSize3xs : tokens.iconSize2xs;
    final textStyle = compact
        ? resolveAppTextStyle(
            context,
            size: AppTextSize.s10,
            weight: AppTextWeight.medium,
            tone: AppTextTone.onMedia,
            height: 13 / 10,
            letterSpacing: 0.12,
          )
        : resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.onMedia,
          ).copyWith(
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
          );

    return AppGlassSurface(
      tone: AppGlassTone.badge,
      width: width,
      height: height,
      borderRadius: context.appRadius.pillBorder,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: spacing.sm,
              vertical: spacing.xs,
            ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: iconSize,
                    color: context.appTextPalette.onMedia,
                  ),
                  child: leading!,
                ),
                SizedBox(width: spacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  key: labelKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
