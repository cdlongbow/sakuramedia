import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sakuramedia/widgets/base/media/video/player_screen_orientation.dart';

/// 播放页横屏沉浸式的页面级 SystemUI 生命周期：进入锁横屏并隐藏系统栏，
/// 退出恢复系统栏并解除方向锁定。
///
/// 由影片播放页（`MobileMoviePlayerPage`）、单切片播放页（`MobileClipPlayerPage`）、
/// 切片合集连播页、单视频播放页与视频合集连播页共用，保证各处进出播放页的行为
/// 一致，避免各自维护一份逻辑造成漂移。
///
/// 页面内的 media_kit 全屏按钮不再走 media_kit 的默认回调：全屏进/退由
/// `ThemedVideoPlayer` / `MoviePlayerSurface` 接到回调后调用
/// [enterPlayerFullscreenOrientation] / [lockPlayerPageLandscape]，
/// 避免默认回调把页面方向锁与沉浸态一起清掉。

/// 进入播放页：锁横屏并隐藏系统栏。
Future<void> enterLandscapePlayerSystemUi() => lockPlayerPageLandscape();

/// 退出播放页：恢复系统栏并解除方向锁定，交给系统默认。
Future<void> restoreSystemUiAfterLandscapePlayer() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
  });
}
