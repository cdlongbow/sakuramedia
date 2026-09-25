import 'package:flutter/services.dart';

/// 移动端播放器的方向与系统 UI 统一入口（「层级二」共享实现）。
///
/// 桌面端不使用这些函数：桌面全屏是 media_kit 的原生窗口全屏（method channel），
/// 方向由窗口系统决定。移动端播放页进入时锁横屏；点全屏交回系统传感器
/// （自动旋转开启时转手机即切换横竖屏）；退出全屏恢复页面横屏，
/// 避免 media_kit 的默认退出回调把页面方向锁与沉浸态一起清掉。

/// 进入全屏：跟随系统传感器。
///
/// Android 上该组合映射为 `user`（尊重系统自动旋转开关）；iOS 上放开
/// 竖屏 + 两个横屏，由系统旋转锁决定实际朝向。
Future<void> enterPlayerFullscreenOrientation() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// 播放页默认方向：锁横屏 + 沉浸。
///
/// Android 上 `[landscapeLeft, landscapeRight]` 映射为 `userLandscape`，
/// 不受系统自动旋转开关影响，保证分栏布局始终横屏可用。
Future<void> lockPlayerPageLandscape() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}
