import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_stat_row.dart';

enum MovieDetailBottomInfoBarVariant { desktopCard, mobileFullWidth }

class MovieDetailBottomInfoBar extends StatelessWidget {
  const MovieDetailBottomInfoBar({
    super.key,
    required this.items,
    required this.onTap,
    this.variant = MovieDetailBottomInfoBarVariant.desktopCard,
  });

  final List<MovieDetailStatItem> items;
  final VoidCallback onTap;
  final MovieDetailBottomInfoBarVariant variant;

  @override
  Widget build(BuildContext context) {
    // 沉浸背景上只留一层透明行：去卡片底/边框/阴影，靠页面模糊罩保证可读。
    final borderRadius = variant == MovieDetailBottomInfoBarVariant.mobileFullWidth
        ? BorderRadius.vertical(top: context.appRadius.smBorder.topLeft)
        : context.appRadius.xsBorder;

    return Material(
      key: const Key('movie-detail-fixed-info-bar'),
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: AppInteractiveSurface(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: context.appComponentTokens.movieDetailBottomBarMinHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.sm,
            vertical: 0,
          ),
          child: Row(
            children: [
              Expanded(child: MovieDetailStatRow(items: items)),
              SizedBox(width: context.appSpacing.sm),
              Container(
                width: 1,
                height: context.appComponentTokens.iconSizeXs,
                color: context.appColors.borderSubtle,
              ),
              SizedBox(width: context.appSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
