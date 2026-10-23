import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 玻璃材质的两档语义：
/// - [chrome]：浮在媒体内容上的窗口级控件（顶栏、浮动返回键）；
/// - [control]：页面内的次级控件与信息 chip（动作组、eyebrow、评分条）。
///
/// 内容卡和正文不使用玻璃，保持可读性；主操作仍用实色品牌色。
enum AppGlassTone { chrome, control }

/// 统一玻璃表面。
///
/// 配方固定在这里，业务页面只选 tone / 圆角 / 内边距，不再各自拼
/// `BackdropFilter + 半透明色 + 边框`：
/// - 外圈 1px 渐变描边；左上亮、右下暗，模拟玻璃边缘折射；
/// - 内部顶部叠一层很轻的高光带；
/// - 小面积背景模糊；
/// - chrome 档位带浮层阴影，control 档位不带阴影。
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.tone = AppGlassTone.control,
    this.borderRadius,
    this.padding,
    this.blur = true,
  });

  final Widget child;
  final AppGlassTone tone;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;

  static const double _borderWidth = 1;
  static const double _blurSigma = 18;
  static const double _highlightHeight = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? context.appRadius.mdBorder;
    final isChrome = tone == AppGlassTone.chrome;
    final tint = isChrome
        ? colors.mediaOverlayStrong.withValues(alpha: 0.42)
        : colors.surfaceElevated.withValues(alpha: 0.50);
    final highlight = context.appTextPalette.onMedia;
    final edgeHighlightAlpha = isChrome ? 0.45 : 0.62;

    final surface = Container(
      decoration: BoxDecoration(color: tint),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _highlightHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      highlight.withValues(alpha: isChrome ? 0.14 : 0.22),
                      highlight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight.withValues(alpha: edgeHighlightAlpha),
            Colors.transparent,
          ],
        ),
        boxShadow: isChrome ? context.appShadows.panel : null,
      ),
      padding: const EdgeInsets.all(_borderWidth),
      child: ClipRRect(
        borderRadius: radius,
        child: blur
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
