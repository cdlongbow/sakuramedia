import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// 切换桌面窗口的系统全屏，供播放器「应用内全屏」调用。
///
/// macOS / Windows 都走 window_manager 的 `setFullScreen`（原生全屏，带系统
/// 动画）。窗口是非无边框的（`TitleBarStyle.hidden` 只藏标题栏、保留系统边框，
/// 见 `window_bootstrap_desktop.dart`），插件的全屏路径正常工作，不需要手动
/// `setBounds` 铺屏，也不需要 `alwaysOnTop` 盖任务栏。
/// 移动端 / 测试环境：没有窗口插件，异常吞掉，调用方只关心应用内布局态。
Future<void> applyDesktopWindowFullscreen(bool enabled) async {
  if (kIsWeb) {
    return;
  }
  final platform = defaultTargetPlatform;
  if (platform != TargetPlatform.macOS &&
      platform != TargetPlatform.windows) {
    return;
  }
  try {
    await windowManager.setFullScreen(enabled);
  } catch (_) {
    // 测试环境没有窗口插件：忽略，应用内布局态照常切换。
  }
}
