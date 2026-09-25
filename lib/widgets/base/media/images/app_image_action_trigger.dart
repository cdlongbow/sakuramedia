import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/platform/haptic_feedback.dart';

/// 图片 / 封面上的「tap + 右键 / 长按菜单」触发层。
///
/// 按下时整体变淡 `0.7`（80ms，与 `AppInteractiveSurface` 一致）；[onTapAt]
/// 用于把点击位置交给调用方（如影片卡的订阅心命中区分流）。[onTap] 与
/// [onTapAt] 都为 `null` 时只承担菜单手势，不做按下反馈。
class AppImageActionTrigger extends StatefulWidget {
  const AppImageActionTrigger({
    super.key,
    required this.child,
    this.onRequestMenu,
    this.onTap,
    this.onTapAt,
    this.mouseCursor = SystemMouseCursors.click,
  });

  final Widget child;
  final ValueChanged<Offset>? onRequestMenu;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapAt;
  final MouseCursor mouseCursor;

  @override
  State<AppImageActionTrigger> createState() => _AppImageActionTriggerState();
}

class _AppImageActionTriggerState extends State<AppImageActionTrigger> {
  static const double _pressedOpacity = 0.7;

  bool _pressed = false;
  Offset? _tapPosition;

  bool get _tappable => widget.onTap != null || widget.onTapAt != null;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final onRequestMenu = widget.onRequestMenu;
    final onTapAt = widget.onTapAt;
    return MouseRegion(
      cursor: widget.mouseCursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _tappable
            ? (details) {
                if (onTapAt != null) {
                  _tapPosition = details.localPosition;
                }
                _setPressed(true);
              }
            : null,
        onTapUp: _tappable ? (_) => _setPressed(false) : null,
        onTapCancel: _tappable ? () => _setPressed(false) : null,
        onTap: onTapAt == null
            ? widget.onTap
            : () => onTapAt(_tapPosition ?? Offset.zero),
        onLongPressStart: onRequestMenu == null
            ? null
            : (details) {
                triggerSelectionHaptic();
                onRequestMenu(details.globalPosition);
              },
        onSecondaryTapDown: onRequestMenu == null
            ? null
            : (details) => onRequestMenu(details.globalPosition),
        child: AnimatedOpacity(
          opacity: _pressed ? _pressedOpacity : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
