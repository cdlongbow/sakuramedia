import 'package:material_ui/material_ui.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/video/video_loading_indicator.dart';

/// 「层级二」轻量播放器的控制主题 / 控件 builder 构建函数。
///
/// 原本定义在 `movie_player_surface.dart`,现抽到 base 层——供 [ThemedVideoPlayer]
/// (`base/media/video/themed_video_player.dart`)与 `MoviePlayerSurface`
/// (`domain/movies/player/movie_player_surface.dart`)共用,断开 base→domain 的
/// 反向依赖。改控制条样式 / 按钮只改这里,一处生效(进度条 / 全屏 / 音量样式一致)。

@visibleForTesting
Widget buildMoviePlayerMobileVideoControls(VideoState state) {
  return MaterialVideoControls(state);
}

@visibleForTesting
Widget buildMoviePlayerDesktopVideoControls(VideoState state) {
  return MaterialDesktopVideoControls(state);
}

Widget Function(VideoState state) resolveMoviePlayerVideoControlsBuilder({
  required bool useTouchOptimizedControls,
}) {
  return useTouchOptimizedControls
      ? buildMoviePlayerMobileVideoControls
      : buildMoviePlayerDesktopVideoControls;
}

@visibleForTesting
Widget buildMoviePlayerBufferingIndicator(BuildContext context) {
  return const VideoLoadingIndicator(label: '正在缓冲…');
}

MaterialVideoControlsThemeData buildMoviePlayerMobileControlsThemeData({
  required ThemeData theme,
  required List<Widget> topControls,
  required List<Widget> bottomControls,
  bool displaySeekBar = true,
  bool seekEnabled = true,
  bool showBufferingIndicator = true,
}) {
  final overlayTokens = theme.appOverlayTokens;
  return MaterialVideoControlsThemeData(
    horizontalGestureSensitivity: 3000,
    seekOnDoubleTap: seekEnabled,
    seekBarMargin: EdgeInsets.fromLTRB(
      overlayTokens.playerSeekBarHorizontalInset,
      0,
      overlayTokens.playerSeekBarHorizontalInset,
      overlayTokens.playerSeekBarBottomInset,
    ),
    seekGesture: seekEnabled,
    volumeGesture: true,
    speedUpOnLongPress: true,
    brightnessGesture: true,
    bufferingIndicatorBuilder: showBufferingIndicator
        ? buildMoviePlayerBufferingIndicator
        : (_) => const SizedBox.shrink(),
    seekBarThumbColor: theme.colorScheme.primary,
    seekBarPositionColor: theme.colorScheme.primary,
    seekBarHeight: 6,
    seekBarThumbSize: 14,
    // 初始化 seek 保护期只禁用交互，不隐藏进度条，避免完整媒体看起来没有进度。
    displaySeekBar: displaySeekBar,
    topButtonBar: topControls,
    topButtonBarMargin: EdgeInsets.fromLTRB(
      overlayTokens.playerControlBarHorizontalInset,
      overlayTokens.playerControlBarTopInset,
      overlayTokens.playerControlBarHorizontalInset,
      0,
    ),
    bottomButtonBar: bottomControls,
  );
}

MaterialDesktopVideoControlsThemeData buildMoviePlayerDesktopControlsThemeData({
  required ThemeData theme,
  required List<Widget> topControls,
  required List<Widget> bottomControls,
  bool displaySeekBar = true,
  bool showBufferingIndicator = true,
  Widget? bottomSeekBar,
}) {
  final overlayTokens = theme.appOverlayTokens;
  return MaterialDesktopVideoControlsThemeData(
    bufferingIndicatorBuilder: showBufferingIndicator
        ? buildMoviePlayerBufferingIndicator
        : (_) => const SizedBox.shrink(),
    seekBarThumbColor: theme.colorScheme.primary,
    seekBarPositionColor: theme.colorScheme.primary,
    seekBarHeight: 6,
    seekBarThumbSize: 14,
    // media_kit_video 的 MaterialDesktopVolumeButton 内部用 AnimatedSwitcher 做
    // 音量图标切换动画；Flutter 有个已知 bug（flutter/flutter#121336）：动画过渡期间
    // 若同 key 的 widget 被快速再次触发切换，会在内部 Stack 里堆出两份相同 key，
    // 触发 "Duplicate keys found" 断言并连带炸出一串 layout 错误。触发场景是拖动
    // seek bar 造成的高频状态更新，音量图标切换本身不需要过渡动画（用户感知不到），
    // 直接设为 0 让切换在单帧内完成，从根上避开这条过渡期叠加窗口。
    volumeBarTransitionDuration: Duration.zero,
    displaySeekBar: bottomSeekBar == null && displaySeekBar,
    // 自定义进度条自带横向内边距（由 bottomButtonBarMargin 提供），
    // 这里清零避免与 media_kit 默认的 seekBarMargin 叠加。
    seekBarMargin: bottomSeekBar == null
        ? EdgeInsets.symmetric(horizontal: theme.appSpacing.lg)
        : EdgeInsets.zero,
    topButtonBar: bottomSeekBar == null
        ? topControls
        : <Widget>[
            Expanded(
              // 底栏集群把 buttonBarHeight 撑高后，用固定 56 高的贴顶行
              // 保持顶栏控件的原有纵向位置。
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: _moviePlayerDesktopButtonBarHeight,
                  child: Row(children: topControls),
                ),
              ),
            ),
          ],
    topButtonBarMargin: EdgeInsets.fromLTRB(
      overlayTokens.playerControlBarHorizontalInset,
      overlayTokens.playerControlBarTopInset,
      overlayTokens.playerControlBarHorizontalInset,
      0,
    ),
    bottomButtonBar: bottomSeekBar == null
        ? bottomControls
        : <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  bottomSeekBar,
                  SizedBox(
                    height: _moviePlayerDesktopButtonBarHeight,
                    child: Row(children: bottomControls),
                  ),
                ],
              ),
            ),
          ],
    buttonBarHeight: bottomSeekBar == null
        ? _moviePlayerDesktopButtonBarHeight
        : _moviePlayerDesktopSeekBarClusterHeight,
  );
}

const double _moviePlayerDesktopButtonBarHeight = 56;

/// 自定义底栏 = 进度条容器（36）+ 按钮行（56）。
const double _moviePlayerDesktopSeekBarClusterHeight =
    _moviePlayerDesktopButtonBarHeight + 36;
