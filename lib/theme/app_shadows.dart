import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.color,
    required this.cardBlur,
    required this.panelBlur,
    required this.offsetY,
    this.cardSpread = _cardSpread,
  });

  const AppShadows.defaults()
    : color = const Color(0x142B1816),
      cardBlur = 10,
      panelBlur = 24,
      offsetY = 8,
      cardSpread = _cardSpread;

  const AppShadows.dark()
    : color = const Color(0x40000000),
      cardBlur = 10,
      panelBlur = 24,
      offsetY = 8,
      cardSpread = _cardSpread;

  /// 卡片阴影内缩量：负的 `spreadRadius` 让阴影矩形比卡片小一圈，
  /// 圆角半径（`appRadius.lg` = 16）才能主导阴影轮廓。
  ///
  /// 取值约束见 [card] 的注释，默认 `-3`。
  static const double _cardSpread = -3;

  final Color color;
  final double cardBlur;
  final double panelBlur;
  final double offsetY;

  /// 卡片阴影的 `spreadRadius`（通常为负）。
  final double cardSpread;

  /// 卡片阴影：必须让阴影轮廓跟着卡片圆角走。
  ///
  /// 坑：`blurRadius` 一旦与卡片圆角（`appRadius.lg` = 16）同量级甚至更大，
  /// 模糊会把圆角轮廓糊平，阴影在四个角上退化成「带方角的灰色底板」，
  /// 视觉上就是「圆角后面垫了一块底色」。所以这里用「小模糊 + 负 spread」
  /// 收紧阴影：亮部贴近卡片边缘、圆角保持可读，模糊半径不超过圆角半径的 2/3。
  List<BoxShadow> get card => [
    BoxShadow(
      color: color,
      blurRadius: cardBlur,
      spreadRadius: cardSpread,
      offset: Offset(0, offsetY / 2),
    ),
  ];

  List<BoxShadow> get panel => [
    BoxShadow(color: color, blurRadius: panelBlur, offset: Offset(0, offsetY)),
  ];

  @override
  AppShadows copyWith({
    Color? color,
    double? cardBlur,
    double? panelBlur,
    double? offsetY,
    double? cardSpread,
  }) {
    return AppShadows(
      color: color ?? this.color,
      cardBlur: cardBlur ?? this.cardBlur,
      panelBlur: panelBlur ?? this.panelBlur,
      offsetY: offsetY ?? this.offsetY,
      cardSpread: cardSpread ?? this.cardSpread,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) {
      return this;
    }
    return AppShadows(
      color: Color.lerp(color, other.color, t)!,
      cardBlur: lerpDouble(cardBlur, other.cardBlur, t)!,
      panelBlur: lerpDouble(panelBlur, other.panelBlur, t)!,
      offsetY: lerpDouble(offsetY, other.offsetY, t)!,
      cardSpread: lerpDouble(cardSpread, other.cardSpread, t)!,
    );
  }
}

extension AppShadowsThemeDataX on ThemeData {
  AppShadows get appShadows =>
      extension<AppShadows>() ?? const AppShadows.defaults();
}

extension AppShadowsBuildContextX on BuildContext {
  AppShadows get appShadows => Theme.of(this).appShadows;
}
