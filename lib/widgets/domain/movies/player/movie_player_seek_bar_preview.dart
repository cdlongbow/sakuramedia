import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/media_timecode.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

const double _cardWidth = 176;
const double _cardHeight = _cardWidth * 9 / 16;
const double _cardGap = 6;

/// 桌面进度条的 hover 预览层。
///
/// 包裹 media_kit 的 `MaterialDesktopSeekBar`（由调用方通过 [seekBar] 注入），
/// 鼠标悬停时在光标上方显示时间轴里最近的一帧缩略图；内部不处理拖动/点击，
/// 进度条本体的交互与显隐仍由 media_kit 控件负责。
class MoviePlayerSeekBarPreview extends StatefulWidget {
  const MoviePlayerSeekBarPreview({
    super.key,
    required this.thumbnails,
    required this.readDuration,
    required this.seekBar,
  });

  /// 与右侧时间轴面板同一份缩略图列表（按 offset 升序）。
  final List<MovieMediaThumbnailDto> thumbnails;

  /// 当前媒体总时长；媒体未就绪时返回 [Duration.zero]。
  final Duration Function() readDuration;
  final Widget seekBar;

  @override
  State<MoviePlayerSeekBarPreview> createState() =>
      _MoviePlayerSeekBarPreviewState();
}

class _MoviePlayerSeekBarPreviewState extends State<MoviePlayerSeekBarPreview> {
  static const Duration _switchDelay = Duration(milliseconds: 120);

  Timer? _switchTimer;
  MovieMediaThumbnailDto? _pending;
  MovieMediaThumbnailDto? _preview;
  double _cursorX = 0;

  @override
  void dispose() {
    _switchTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MoviePlayerSeekBarPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.thumbnails, widget.thumbnails)) {
      _switchTimer?.cancel();
      _pending = null;
      _preview = null;
    }
  }

  void _handleHover(double localX, double width) {
    if (width <= 0 || widget.thumbnails.isEmpty) {
      return;
    }
    final duration = widget.readDuration();
    if (duration <= Duration.zero) {
      return;
    }
    final fraction = (localX / width).clamp(0.0, 1.0);
    final targetSeconds = duration.inMilliseconds * fraction / 1000;
    final nearest = _nearestThumbnail(targetSeconds.toDouble());
    _cursorX = localX;
    if (nearest.offsetSeconds == (_preview ?? _pending)?.offsetSeconds) {
      if (_preview != null) {
        setState(() {});
      }
      return;
    }
    _pending = nearest;
    _switchTimer?.cancel();
    _switchTimer = Timer(_switchDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _preview = _pending);
    });
    if (_preview != null) {
      setState(() {});
    }
  }

  void _handleExit() {
    _switchTimer?.cancel();
    _pending = null;
    if (_preview != null) {
      setState(() => _preview = null);
    }
  }

  MovieMediaThumbnailDto _nearestThumbnail(double targetSeconds) {
    var nearest = widget.thumbnails.first;
    var nearestDistance = (nearest.offsetSeconds - targetSeconds).abs();
    for (final thumbnail in widget.thumbnails.skip(1)) {
      final distance = (thumbnail.offsetSeconds - targetSeconds).abs();
      if (distance < nearestDistance) {
        nearest = thumbnail;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final preview = _preview;
        return MouseRegion(
          onHover: (event) => _handleHover(event.localPosition.dx, width),
          onExit: (_) => _handleExit(),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              widget.seekBar,
              if (preview != null)
                Positioned(
                  top: -(_cardHeight + _cardGap),
                  left: (_cursorX - _cardWidth / 2).clamp(
                    0.0,
                    math.max(0.0, width - _cardWidth),
                  ),
                  child: IgnorePointer(
                    child: _SeekBarPreviewCard(thumbnail: preview),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SeekBarPreviewCard extends StatelessWidget {
  const _SeekBarPreviewCard({required this.thumbnail});

  final MovieMediaThumbnailDto thumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: theme.appRadius.mdBorder,
        border: Border.all(color: Colors.white24),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black54, blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: theme.appRadius.mdBorder,
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              MaskedImage(
                url: thumbnail.image.origin,
                fit: BoxFit.cover,
                memCacheWidth: (_cardWidth * 2).round(),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.all(context.appSpacing.xs),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.appSpacing.xs,
                    vertical: context.appSpacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.66),
                    borderRadius: theme.appRadius.xsBorder,
                  ),
                  child: Text(
                    formatMediaTimecode(thumbnail.offsetSeconds),
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s10,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.onMedia,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
