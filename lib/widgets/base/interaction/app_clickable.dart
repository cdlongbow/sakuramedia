import 'package:material_ui/material_ui.dart';

/// 为没有内置鼠标指针的项目自定义点击区域提供统一的鼠标指针。
///
/// 这个组件只负责指针，不负责点击回调，适合包在自定义
/// [GestureDetector] 外面。若交互组件本身是 [InkWell]，应直接设置它的
/// `mouseCursor`；内层 [InkWell] 的鼠标区域会覆盖外层的指针。禁用时保留
/// 系统默认箭头指针。
class AppClickable extends StatelessWidget {
  const AppClickable({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: child,
    );
  }
}
