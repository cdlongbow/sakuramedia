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

  String get label => switch (this) {
    RankingSortField.rank => '榜单名次',
    RankingSortField.heat => '热度',
    RankingSortField.score => '评分',
    RankingSortField.scoreNumber => '评分人数',
    RankingSortField.watchedCount => '看过人数',
    RankingSortField.wantWatchCount => '想看人数',
    RankingSortField.commentCount => '评论人数',
  };
}
