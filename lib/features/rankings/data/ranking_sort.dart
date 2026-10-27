import 'package:sakuramedia/l10n/app_localizations.dart';

export 'package:sakuramedia/features/shared/data/sort_direction.dart'
    show SortDirection, SortDirectionX;

enum RankingSortField {
  rank,
  heat,
  score,
  scoreNumber,
  watchedCount,
  wantWatchCount,
  commentCount,
}

extension RankingSortFieldX on RankingSortField {
  String get apiValue => switch (this) {
    RankingSortField.rank => 'rank',
    RankingSortField.heat => 'heat',
    RankingSortField.score => 'score',
    RankingSortField.scoreNumber => 'score_number',
    RankingSortField.watchedCount => 'watched_count',
    RankingSortField.wantWatchCount => 'want_watch_count',
    RankingSortField.commentCount => 'comment_count',
  };

  /// 排序字段的展示文案，按当前语言渲染。
  String label(AppLocalizations l10n) => switch (this) {
    RankingSortField.rank => l10n.rankingSortFieldRank,
    RankingSortField.heat => l10n.sharedInteractionHeat,
    RankingSortField.score => l10n.sharedInteractionScore,
    RankingSortField.scoreNumber => l10n.sharedInteractionScoreNumber,
    RankingSortField.watchedCount => l10n.sharedInteractionWatchedCount,
    RankingSortField.wantWatchCount => l10n.sharedInteractionWantWatchCount,
    RankingSortField.commentCount => l10n.rankingSortFieldCommentCount,
  };
}
