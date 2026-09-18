import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 播放器浮层统一的深色毛玻璃面:模糊 + 染色 + 描边 + 投影。
///
/// 播放信息面板、移动端右侧抽屉、桌面倍速/字幕菜单共用同一份透明度与
/// 模糊半径, 避免各浮层透明度漂移。抽屉类传左圆角与无限高, 菜单用默认
/// 全圆角并随内容收缩。
class MoviePlayerGlassSurface extends StatelessWidget {
  const MoviePlayerGlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overlayTokens = context.appOverlayTokens;
    final radius = borderRadius ?? overlayTokens.surfaceBorderRadius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: overlayTokens.surfaceShadowAlpha,
            ),
            blurRadius: overlayTokens.surfaceShadowBlur,
            offset: Offset(0, overlayTokens.surfaceShadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: overlayTokens.glassBlurSigma,
            sigmaY: overlayTokens.glassBlurSigma,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: colors.movieDetailHeroBackgroundStart.withValues(
                alpha: overlayTokens.glassSurfaceAlpha,
              ),
              borderRadius: radius,
              border: Border.all(
                color: context.appTextPalette.onMedia.withValues(
                  alpha: overlayTokens.surfaceBorderAlpha,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 播放器菜单 / 抽屉里的一行:左侧 label + 右侧勾选槽。
///
/// 四处逐字相同的骨架合并到此:
///   - 桌面 speed 菜单项 (movie_player_speed_button)
///   - 桌面 subtitle 菜单项 (movie_player_subtitle_button)
///   - 移动 speed 抽屉项 (movie_player_surface)
///   - 移动 subtitle 抽屉项 (movie_player_surface)
///
/// hover 背景 / label overflow / 勾选色由参数保真:
///   - 桌面版有 hover 背景, 移动无。
///   - subtitle 需 `overflow: ellipsis`; speed 无。
///   - 移动 subtitle 用 `Theme.colorScheme.primary`, 其余用
///     `resolveAppTextToneColor(context, AppTextTone.accent)`。
class MoviePlayerMenuItemRow extends StatelessWidget {
  const MoviePlayerMenuItemRow({
    super.key,
    required this.label,
    required this.selected,
    required this.checkColor,
    this.labelKey,
    this.checkKey,
    this.checkSlotKey,
    this.overflow,
    this.maxLines,
    this.background,
  });

  final String label;
  final bool selected;

  /// 选中时勾选 icon 与文字 accent 色。
  final Color checkColor;

  final Key? labelKey;
  final Key? checkKey;
  final Key? checkSlotKey;

  /// subtitle 传 [TextOverflow.ellipsis]。
  final TextOverflow? overflow;

  /// subtitle 传 1。
  final int? maxLines;

  /// hover 状态背景色。桌面菜单项 hover 时传半透明 onMedia,
  /// 移动抽屉传 null。
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final overlayTokens = context.appOverlayTokens;
    return SizedBox(
      height: overlayTokens.menuItemHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: Row(
          children: [
            SizedBox(width: overlayTokens.controlSideGap),
            Expanded(
              child: Text(
                label,
                key: labelKey,
                overflow: overflow,
                maxLines: maxLines,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  tone: selected ? AppTextTone.accent : AppTextTone.onMedia,
                ),
              ),
            ),
            SizedBox(
              width: overlayTokens.controlCheckSlotWidth,
              child: Center(
                child:
                    selected
                        ? Icon(
                          Icons.check_rounded,
                          key: checkKey,
                          size: overlayTokens.controlCheckIconSize,
                          color: checkColor,
                        )
                        : SizedBox(
                          key: checkSlotKey,
                          width: overlayTokens.controlCheckIconSize,
                          height: overlayTokens.controlCheckIconSize,
                        ),
              ),
            ),
            SizedBox(width: overlayTokens.controlTrailingGap),
          ],
        ),
      ),
    );
  }
}
