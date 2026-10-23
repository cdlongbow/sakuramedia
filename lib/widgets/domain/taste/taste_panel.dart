import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 口味画像的渐变外壳：品牌色光晕 + 斜向底色 + 头部。
///
/// 只负责视觉，不持有业务 DTO；发现页和女优页共用同一套语言。
class TastePanel extends StatelessWidget {
  const TastePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.sampleMovieCount,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// 参与画像计算的影片数；null/0 时只展示来源说明。
  final int? sampleMovieCount;

  /// 女优页的窄版：收紧内边距，缩小水印。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius.lgBorder;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                appColors.surfaceCard,
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.10),
                  appColors.surfaceCard,
                ),
                Color.alphaBlend(
                  colors.secondary.withValues(alpha: 0.16),
                  appColors.surfaceCard,
                ),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -spacing.xxl,
                right: -spacing.xl,
                child: _TasteGlow(
                  color: colors.primary,
                  size: spacing.xxxl * 4,
                ),
              ),
              Positioned(
                bottom: -spacing.xxl,
                left: -spacing.xl,
                child: _TasteGlow(
                  color: colors.secondary,
                  size: spacing.xxxl * 3,
                ),
              ),
              Positioned(
                top: spacing.sm,
                right: spacing.lg,
                child: Icon(
                  icon,
                  size: compact ? spacing.xxxl * 2 : spacing.xxxl * 3,
                  color: colors.primary.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? spacing.md : spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TastePanelHeader(
                      title: title,
                      icon: icon,
                      sampleMovieCount: sampleMovieCount,
                    ),
                    SizedBox(height: compact ? spacing.md : spacing.lg),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TastePanelHeader extends StatelessWidget {
  const _TastePanelHeader({
    required this.title,
    required this.icon,
    this.sampleMovieCount,
  });

  final String title;
  final IconData icon;
  final int? sampleMovieCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final count = sampleMovieCount ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: spacing.xxxl,
          height: spacing.xxxl,
          decoration: BoxDecoration(
            borderRadius: context.appRadius.mdBorder,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[colors.primary, colors.secondary],
            ),
          ),
          child: Icon(icon, size: tokens.iconSizeMd, color: colors.onPrimary),
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s16,
                  weight: AppTextWeight.semibold,
                ),
              ),
              SizedBox(height: spacing.xs / 2),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    if (count > 0) ...<InlineSpan>[
                      TextSpan(
                        text: '基于 ',
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                      TextSpan(
                        text: '$count',
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s16,
                          weight: AppTextWeight.semibold,
                        ).copyWith(color: colors.primary),
                      ),
                      TextSpan(
                        text: ' 部影片的播放与收藏',
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                    ] else
                      TextSpan(
                        text: '来自你的播放、收藏与片单',
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TasteGlow extends StatelessWidget {
  const _TasteGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
