import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/player/movie_player_subtitle_state.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_back_overlay.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_mobile_drawers.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_button.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_speed_button.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_subtitle_button.dart';

/// 播放器窗口态顶栏:左「返回 + 番号」、右「视频信息」按钮。
/// 也被切片/视频单播与合集连播页复用(只传 onBackPressed)。
List<Widget> buildMoviePlayerTopControls({
  required String movieNumber,
  required VoidCallback? onBackPressed,
  VoidCallback? onInfoPressed,
}) {
  if (onBackPressed == null && onInfoPressed == null) {
    return const <Widget>[];
  }
  final controls = <Widget>[];
  if (onBackPressed != null) {
    controls.add(
      MoviePlayerBackWithNumberControl(
        onPressed: onBackPressed,
        movieNumber: movieNumber,
      ),
    );
  }
  if (onInfoPressed != null) {
    if (controls.isNotEmpty) {
      controls.add(const Spacer());
    }
    controls.add(MoviePlayerInfoButton(onPressed: onInfoPressed));
  }
  return controls;
}

List<Widget> buildMoviePlayerMobileBottomControls({
  required MoviePlayerMobileDrawerType? activeDrawer,
  required ValueListenable<MoviePlayerMobileSpeedDisplayState>
  speedDisplayListenable,
  required VoidCallback onSpeedButtonPressed,
  required VoidCallback onSubtitleButtonPressed,
  required ValueListenable<bool> qualityEnabledListenable,
  required VoidCallback onQualityPressed,
}) {
  return <Widget>[
    const MaterialPlayOrPauseButton(),
    const MaterialDesktopVolumeButton(),
    const MaterialPositionIndicator(),
    const Spacer(),
    ...buildMoviePlayerMobileDrawerToggleButtons(
      activeDrawer: activeDrawer,
      speedDisplayListenable: speedDisplayListenable,
      onSpeedButtonPressed: onSpeedButtonPressed,
      onSubtitleButtonPressed: onSubtitleButtonPressed,
    ),
    // 移动控制条宽度紧张：只放开关本体，不放「画质增强」标签。
    MoviePlayerQualityButton(
      enabledListenable: qualityEnabledListenable,
      onPressed: onQualityPressed,
    ),
    const MaterialFullscreenButton(),
  ];
}

List<Widget> buildMoviePlayerDesktopBottomControls({
  required double currentRate,
  required bool hasExplicitSelection,
  required Future<void> Function(double rate) onRateSelected,
  required ValueListenable<MoviePlayerSubtitleState> subtitleStateListenable,
  required ValueListenable<bool> isApplyingListenable,
  required Future<void> Function(int? subtitleId) onSubtitleSelected,
  required Future<void> Function() onSubtitleReloadRequested,
  required ValueListenable<bool> qualityEnabledListenable,
  required VoidCallback onQualityPressed,
}) {
  return <Widget>[
    const MaterialPlayOrPauseButton(),
    const MaterialDesktopVolumeButton(),
    const MaterialPositionIndicator(),
    const Spacer(),
    MoviePlayerSpeedButton(
      currentRate: currentRate,
      hasExplicitSelection: hasExplicitSelection,
      onRateSelected: onRateSelected,
    ),
    MoviePlayerSubtitleButton(
      subtitleStateListenable: subtitleStateListenable,
      isApplyingListenable: isApplyingListenable,
      onSubtitleSelected: onSubtitleSelected,
      onReloadRequested: onSubtitleReloadRequested,
    ),
    MoviePlayerQualityButton(
      label: '画质增强',
      enabledListenable: qualityEnabledListenable,
      onPressed: onQualityPressed,
    ),
    const MaterialFullscreenButton(),
  ];
}
