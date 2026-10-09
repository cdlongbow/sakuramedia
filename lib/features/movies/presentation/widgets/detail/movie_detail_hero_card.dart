import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

/// 整页模糊底座的共享配方（页面背景引用，底边相接无分割）：
/// 模糊强度 / 底色罩浓度 / 模糊放大倍数。
abstract final class MovieDetailVeil {
  static const double backgroundBlurSigma = 28;
  static const double veilAlpha = 0.82;
  static const double backgroundScale = 1.15;
}

/// 影片详情封面 Hero：纯照片，底部化开后把舞台
/// 交给页面背景与照片下方的信息块。这里不画任何文字和按钮，
/// 自身透明（底座就是页面的整页模糊背景，连续一层、无边缘回透）。
///
/// 填充方式由 [heroFit] 决定：桌面保持 [BoxFit.contain] 完整显示不裁切，
/// 移动沉浸全幅传 [BoxFit.cover] 铺满裁切（由 [ClipRect] 裁到框内）。
class MovieDetailHeroCard extends StatelessWidget {
  const MovieDetailHeroCard({
    super.key,
    required this.height,
    required this.mainImageKey,
    required this.mainImageUrl,
    required this.veilColor,
    this.heroFit = BoxFit.contain,
  });

  final double height;
  final String mainImageKey;
  final String? mainImageUrl;

  /// 前景图的填充方式：默认 [BoxFit.contain]，移动端传 [BoxFit.cover]。
  final BoxFit heroFit;

  /// 无封面占位块与图片占位的纯底色：与页面背景回退色一致，不断层。
  /// 桌面传 surfaceElevated、移动传 surfaceCard，因此由调用方决定。
  final Color veilColor;

  /// 底部过渡带占 Hero 高的比例：清晰图在带内化开。
  static const double meltBandFactor = 0.28;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    // 清晰图化开起点：过渡带顶部再往上一个羽化宽度。
    final feather = spacing.xxxl + spacing.lg;
    final fadeStart =
        (1.0 - meltBandFactor - feather / height).clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      // 前景图裁到框内（cover 时图片会超出框）。
      child: ClipRect(
        child: Stack(
          children: [
            if (mainImageUrl != null && mainImageUrl!.isNotEmpty)
              // 前景图底部过渡带内化开，化开处露出页面背景（同一张图的模糊，无缝）。
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.white, Colors.transparent],
                    stops: [fadeStart, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: MaskedImage(
                    url: mainImageUrl!,
                    fit: heroFit,
                    alignment: Alignment.center,
                    // 占位与无封面块同色（veil 色）：骨架 → 占位 → 图片只剩一次淡入。
                    placeholderColor: veilColor,
                  ),
                ),
              )
            else
              _HeroImageFrame(
                imageKey: mainImageKey,
                veilColor: veilColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroImageFrame extends StatelessWidget {
  const _HeroImageFrame({required this.imageKey, required this.veilColor});

  final String imageKey;

  /// 无封面时的纯底色：与页面背景回退色一致，不断层。
  final Color veilColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('movie-detail-main-image-$imageKey'),
      width: double.infinity,
      height: double.infinity,
      child: DecoratedBox(decoration: BoxDecoration(color: veilColor)),
    );
  }
}
