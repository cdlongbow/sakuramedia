import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_menu_widgets.dart';

const double _qualityComparisonDividerWidth = 1.5;

/// 擦除节奏：扫到中间 → 停顿 1.5 秒（左右对比最清晰的一刻）→ 扫到右侧。
const Duration _qualityComparisonSweepDuration = Duration(milliseconds: 600);
const Duration _qualityComparisonHoldDuration = Duration(milliseconds: 1500);
const Duration _qualityComparisonDuration =
    Duration(milliseconds: 2700); // 600 + 1500 + 600

const double _qualityComparisonLabelFadeInEnd = 0.08;

/// 标签在分割线扫到两侧之前淡出，避免分割线穿过标签造成误读。
const double _qualityComparisonLabelFadeOutStart = 0.9;
const double _qualityComparisonLabelFadeOutEnd = 1.0;

/// 画质增强开启时的「增强 / 原始」对比擦除动画。
///
/// 左侧透出下方实时增强画面（本组件自身透明），右侧叠加开启前抓取的原始帧，
/// 分割线从左扫到右；动画结束回调 [onCompleted]，由调用方收起本组件并恢复播放。
class MoviePlayerQualityComparisonOverlay extends StatefulWidget {
  const MoviePlayerQualityComparisonOverlay({
    super.key,
    required this.originalFrame,
    required this.onCompleted,
    this.fit = BoxFit.fitWidth,
  });

  final Uint8List originalFrame;
  final VoidCallback onCompleted;

  /// 与视频画面一致的填充方式，保证原始帧和实时画面重合。
  final BoxFit fit;

  @override
  State<MoviePlayerQualityComparisonOverlay> createState() =>
      _MoviePlayerQualityComparisonOverlayState();
}

class _MoviePlayerQualityComparisonOverlayState
    extends State<MoviePlayerQualityComparisonOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dividerProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _qualityComparisonDuration,
    )..addStatusListener(_handleStatusChanged);
    // 前半段扫到中间 → 停顿 → 后半段扫到右侧。
    _dividerProgress = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _qualityComparisonSweepDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.5),
        weight: _qualityComparisonHoldDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.5,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: _qualityComparisonSweepDuration.inMilliseconds.toDouble(),
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted();
    }
  }

  double get _labelOpacity {
    final value = _controller.value;
    if (value <= _qualityComparisonLabelFadeInEnd) {
      return value / _qualityComparisonLabelFadeInEnd;
    }
    if (value >= _qualityComparisonLabelFadeOutEnd) {
      return 0;
    }
    if (value >= _qualityComparisonLabelFadeOutStart) {
      return 1 -
          (value - _qualityComparisonLabelFadeOutStart) /
              (_qualityComparisonLabelFadeOutEnd -
                  _qualityComparisonLabelFadeOutStart);
    }
    return 1;
  }

  /// 分割线贯穿整段擦除，只在最开头淡入。
  double get _dividerOpacity {
    const fadeInEnd = 0.04;
    final value = _controller.value;
    if (value >= fadeInEnd) {
      return 1;
    }
    return value / fadeInEnd;
  }

  @override
  Widget build(BuildContext context) {
    final overlayTokens = context.appOverlayTokens;
    return IgnorePointer(
      key: const Key('movie-player-quality-comparison'),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _dividerProgress.value;
            final labelOpacity = _labelOpacity.clamp(0.0, 1.0);
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerRight,
                        widthFactor: (1 - progress).clamp(0.0, 1.0),
                        child: Image.memory(
                          widget.originalFrame,
                          key: const Key(
                            'movie-player-quality-comparison-original',
                          ),
                          fit: widget.fit,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    if (labelOpacity > 0) ...[
                      _buildLabel(
                        context,
                        label: '增强',
                        alignment: Alignment.centerLeft,
                        opacity: labelOpacity,
                        labelKey: const Key(
                          'movie-player-quality-comparison-enhanced-label',
                        ),
                      ),
                      _buildLabel(
                        context,
                        label: '原始',
                        alignment: Alignment.centerRight,
                        opacity: labelOpacity,
                        labelKey: const Key(
                          'movie-player-quality-comparison-original-label',
                        ),
                      ),
                    ],
                    Positioned(
                      left:
                          (constraints.maxWidth * progress) -
                          (_qualityComparisonDividerWidth / 2),
                      top: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: _dividerOpacity,
                        child: Container(
                          key: const Key(
                            'movie-player-quality-comparison-divider',
                          ),
                          width: _qualityComparisonDividerWidth,
                          color: context.appTextPalette.onMedia.withValues(
                            alpha: overlayTokens.primaryLabelAlpha,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context, {
    required String label,
    required Alignment alignment,
    required double opacity,
    required Key labelKey,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.appSpacing.xl),
        child: Opacity(
          opacity: opacity,
          child: MoviePlayerGlassSurface(
            borderRadius: context.appRadius.pillBorder,
            padding: EdgeInsets.symmetric(
              horizontal: context.appSpacing.sm,
              vertical: context.appSpacing.xs,
            ),
            child: Text(
              label,
              key: labelKey,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.onMedia,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
