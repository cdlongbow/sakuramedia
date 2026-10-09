import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/app/app_window_fullscreen.dart';
import 'package:window_manager/window_manager.dart';

/// Transparent resize handles for the frameless Windows window.
class AppWindowsFrame extends StatefulWidget {
  const AppWindowsFrame({super.key, required this.child});

  final Widget child;

  @override
  State<AppWindowsFrame> createState() => _AppWindowsFrameState();
}

class _AppWindowsFrameState extends State<AppWindowsFrame> with WindowListener {
  bool _canResize = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refreshWindowState();
  }

  Future<void> _refreshWindowState() async {
    final states = await Future.wait([
      windowManager.isMaximized(),
      windowManager.isFullScreen(),
    ]);
    if (!mounted) return;
    setState(() => _canResize = !states.any((value) => value));
  }

  @override
  void onWindowMaximize() => _refreshWindowState();

  @override
  void onWindowUnmaximize() => _refreshWindowState();

  @override
  void onWindowEnterFullScreen() => _refreshWindowState();

  @override
  void onWindowLeaveFullScreen() => _refreshWindowState();

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: desktopWindowFullscreenActive,
    builder: (context, appFullscreen, child) => DragToResizeArea(
      // 应用内全屏（播放器全屏）时窗口自己铺满显示器，别再给拖拽边缘留热区，
      // 否则鼠标从屏幕边缘划过去会把窗口从全屏里拖出来。
      enableResizeEdges: appFullscreen || !_canResize ? const [] : null,
      child: child!,
    ),
    child: widget.child,
  );
}
