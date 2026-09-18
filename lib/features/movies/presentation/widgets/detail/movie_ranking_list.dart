import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/theme.dart';

/// 影片详情「榜单」区块：每条上榜记录一枚紧凑的荣誉徽章（奖杯 + 名次 + 榜单 · 周期），
/// 徽章按流式排列，不占整行。
class MovieRankingList extends StatelessWidget {
  const MovieRankingList({super.key, required this.rankings});

  final List<MovieRankingDto> rankings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('movie-ranking-list'),
      spacing: context.appComponentTokens.movieDetailPillGap,
      runSpacing: context.appComponentTokens.movieDetailPillGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final ranking in rankings) _MovieRankingChip(ranking: ranking),
      ],
    );
  }
}

class _MovieRankingChip extends StatelessWidget {
  const _MovieRankingChip({required this.ranking});

  final MovieRankingDto ranking;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final label = [
      ranking.boardName.trim(),
      ranking.periodLabel.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.movieDetailPillHorizontalPadding,
        vertical: tokens.movieDetailPillVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: colors.warningSurface,
        borderRadius: context.appRadius.xsBorder,
        border: Border.all(
          color: resolveAppTextToneColor(
            context,
            AppTextTone.warning,
          ).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: tokens.iconSize3xs,
            color: colors.movieDetailScoreIcon,
          ),
          SizedBox(width: spacing.xs),
          Text(
            '#${ranking.rank}',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.warning,
            ),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(width: spacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  tone: AppTextTone.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
