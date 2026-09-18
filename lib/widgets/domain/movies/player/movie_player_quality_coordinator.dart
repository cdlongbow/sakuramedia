import 'package:flutter/foundation.dart';
import 'package:sakuramedia/widgets/base/media/video/mpv_video_quality_settings.dart';

typedef MoviePlayerQualityCaptureFrame = Future<Uint8List?> Function();

typedef MoviePlayerQualityIsPlaying = bool Function();

typedef MoviePlayerQualityAction = Future<void> Function();

/// 「画质增强」开关的会话内状态与开启流程。
///
/// 开启：暂停 → 抓一帧开启前的画面 → 写入 mpv 增强属性 → 播放器区域播放
/// 「增强 / 原始」对比擦除动画 → 动画结束后恢复播放。
/// 关闭：立即恢复原属性并切回实时画面（不做反向动画）。
///
/// 状态不持久化：随播放器实例创建、销毁，下次播放默认关闭。
///
/// 同时实现 [ValueListenable]：控制条按钮挂在 media_kit 的控制条主题数据上，
/// 而该主题的 `updateShouldNotify` 判断写反（media_kit 的 bug），状态变化不会
/// 触发控制条重建，因此按钮必须自己监听本对象才能可靠刷新。
class MoviePlayerQualityCoordinator extends ChangeNotifier
    implements ValueListenable<bool> {
  MoviePlayerQualityCoordinator({
    required MoviePlayerQualityIsPlaying isPlaying,
    required MoviePlayerQualityAction pause,
    required MoviePlayerQualityAction play,
    required MoviePlayerQualityCaptureFrame captureFrame,
    required MpvPropertyReader readProperty,
    required MpvPropertyWriter writeProperty,
  }) : _isPlaying = isPlaying,
       _pause = pause,
       _play = play,
       _captureFrame = captureFrame,
       _readProperty = readProperty,
       _writeProperty = writeProperty;

  final MoviePlayerQualityIsPlaying _isPlaying;
  final MoviePlayerQualityAction _pause;
  final MoviePlayerQualityAction _play;
  final MoviePlayerQualityCaptureFrame _captureFrame;
  final MpvPropertyReader _readProperty;
  final MpvPropertyWriter _writeProperty;

  bool _enabled = false;
  bool _pausedForComparison = false;
  Uint8List? _originalFrame;
  Map<String, String> _snapshot = const <String, String>{};

  /// 每次开启 / 关闭自增，用于丢弃中途被关闭的在途开启流程。
  int _generation = 0;

  bool get enabled => _enabled;

  @override
  bool get value => _enabled;

  /// 开启前的原始帧；非空表示对比擦除动画应该展示。
  Uint8List? get originalFrame => _originalFrame;

  Future<void> toggle() async {
    if (_enabled) {
      await _disable();
    } else {
      await _enable();
    }
  }

  /// 对比擦除动画播完：收起原始帧并恢复播放。
  Future<void> finishComparison() async {
    if (_originalFrame == null) {
      return;
    }
    _originalFrame = null;
    notifyListeners();
    await _resumeIfPaused();
  }

  Future<void> _enable() async {
    final generation = ++_generation;

    // 开关状态立即反馈：暂停 / 截图 / 写属性都在后面异步完成。
    _enabled = true;
    _originalFrame = null;
    notifyListeners();

    _pausedForComparison = _isPlaying();
    if (_pausedForComparison) {
      await _pause();
    }
    if (generation != _generation) {
      await _resumeIfPaused();
      return;
    }

    Uint8List? frame;
    try {
      frame = await _captureFrame();
    } catch (_) {
      frame = null;
    }
    if (generation != _generation) {
      await _resumeIfPaused();
      return;
    }

    _snapshot = await MpvVideoQualitySettings.captureCurrent(_readProperty);
    if (generation != _generation) {
      await _resumeIfPaused();
      return;
    }
    await MpvVideoQualitySettings.enable(_writeProperty);
    if (generation != _generation) {
      // 期间被关闭：把刚写入的增强属性恢复回去。
      await MpvVideoQualitySettings.disable(_writeProperty, _snapshot);
      return;
    }

    _originalFrame = frame;
    debugPrint(
      '[player-debug] quality_enabled hasFrame=${frame != null} pausedForComparison=$_pausedForComparison',
    );
    notifyListeners();

    if (frame == null) {
      // 抓帧失败：没有对比素材，直接回到播放状态，不影响增强本身。
      await _resumeIfPaused();
    }
  }

  Future<void> _disable() async {
    _generation++;
    _enabled = false;
    _originalFrame = null;
    debugPrint('[player-debug] quality_disabled');
    notifyListeners();

    await MpvVideoQualitySettings.disable(_writeProperty, _snapshot);
    _snapshot = const <String, String>{};
    await _resumeIfPaused();
  }

  Future<void> _resumeIfPaused() async {
    if (!_pausedForComparison) {
      return;
    }
    _pausedForComparison = false;
    await _play();
  }
}
