import 'package:sakuramedia/features/shared/data/sort_direction.dart';

// SortDirection 已抬到 lib/features/shared/data/sort_direction.dart，
// 这里 re-export 保持 movies 域现有 import 路径不变。
export 'package:sakuramedia/features/shared/data/sort_direction.dart'
    show SortDirection, SortDirectionX;

enum MovieStatusFilter { all, subscribed, playable }

extension MovieStatusFilterX on MovieStatusFilter {
  String get apiValue => switch (this) {
    MovieStatusFilter.all => 'all',
    MovieStatusFilter.subscribed => 'subscribed',
    MovieStatusFilter.playable => 'playable',
  };

  String get label => switch (this) {
    MovieStatusFilter.all => '全部',
    MovieStatusFilter.subscribed => '已订阅',
    MovieStatusFilter.playable => '可播放',
  };
}

enum MovieNumberSourceFilter { all, regular, fc2 }

extension MovieNumberSourceFilterX on MovieNumberSourceFilter {
  String get apiValue => switch (this) {
    MovieNumberSourceFilter.all => 'all',
    MovieNumberSourceFilter.regular => 'regular',
    MovieNumberSourceFilter.fc2 => 'fc2',
  };

  String get label => switch (this) {
    MovieNumberSourceFilter.all => '全部',
    MovieNumberSourceFilter.regular => '常规',
    MovieNumberSourceFilter.fc2 => 'FC2',
  };
}

enum MovieCollectionTypeFilter { all, single }

extension MovieCollectionTypeFilterX on MovieCollectionTypeFilter {
  String get apiValue => switch (this) {
    MovieCollectionTypeFilter.all => 'all',
    MovieCollectionTypeFilter.single => 'single',
  };

  String get label => switch (this) {
    MovieCollectionTypeFilter.all => '全部',
    MovieCollectionTypeFilter.single => '单体',
  };
}

enum TagMatchMode { or, and }

extension TagMatchModeX on TagMatchMode {
  String get apiValue => switch (this) {
    TagMatchMode.or => 'or',
    TagMatchMode.and => 'and',
  };

  String get label => switch (this) {
    TagMatchMode.or => '任一',
    TagMatchMode.and => '全部',
  };
}

enum MovieSortField {
  releaseDate,
  addedAt,
  subscribedAt,
  commentCount,
  scoreNumber,
  wantWatchCount,
  heat,
}

extension MovieSortFieldX on MovieSortField {
  String get apiValue => switch (this) {
    MovieSortField.releaseDate => 'release_date',
    MovieSortField.addedAt => 'added_at',
    MovieSortField.subscribedAt => 'subscribed_at',
    MovieSortField.commentCount => 'comment_count',
    MovieSortField.scoreNumber => 'score_number',
    MovieSortField.wantWatchCount => 'want_watch_count',
    MovieSortField.heat => 'heat',
  };

  String get label => switch (this) {
    MovieSortField.releaseDate => '发行时间',
    MovieSortField.addedAt => '最近入库',
    MovieSortField.subscribedAt => '订阅时间',
    MovieSortField.commentCount => '评论人数',
    MovieSortField.scoreNumber => '评分人数',
    MovieSortField.wantWatchCount => '想看人数',
    MovieSortField.heat => '热度',
  };
}

const Object _movieFilterUnset = Object();

/// 普通影片库的年份筛选不依赖后端聚合：范围固定为 2008 年至当前年。
///
/// 女优详情会显式传入服务端返回的年份和数量，因此仍可保持「年份(影片数)」
/// 的精确展示。
const int movieFilterEarliestYear = 2008;

List<MovieFilterYearOption> buildDefaultMovieFilterYearOptions({
  int? currentYear,
}) {
  final latestYear = currentYear ?? DateTime.now().year;
  if (latestYear < movieFilterEarliestYear) {
    return const <MovieFilterYearOption>[];
  }
  return <MovieFilterYearOption>[
    for (var year = latestYear; year >= movieFilterEarliestYear; year--)
      MovieFilterYearOption(year: year),
  ];
}

class MovieFilterYearOption {
  const MovieFilterYearOption({required this.year, this.movieCount});

  final int year;
  final int? movieCount;

  String get label => movieCount == null ? '$year' : '$year($movieCount)';
}

class MovieFilterState {
  const MovieFilterState({
    this.status = MovieStatusFilter.all,
    this.collectionType = MovieCollectionTypeFilter.single,
    this.numberSource = MovieNumberSourceFilter.all,
    this.sortField = MovieSortField.releaseDate,
    this.sortDirection = SortDirection.desc,
    this.year,
  });

  final MovieStatusFilter status;
  final MovieCollectionTypeFilter collectionType;
  final MovieNumberSourceFilter numberSource;
  final MovieSortField sortField;
  final SortDirection sortDirection;
  final int? year;

  static const MovieFilterState initial = MovieFilterState();

  bool get isDefault =>
      status == MovieStatusFilter.all &&
      collectionType == MovieCollectionTypeFilter.single &&
      numberSource == MovieNumberSourceFilter.all &&
      sortField == MovieSortField.releaseDate &&
      sortDirection == SortDirection.desc &&
      year == null;

  String get sortExpression =>
      '${sortField.apiValue}:${sortDirection.apiValue}';

  /// 筛选入口上显示的当前筛选摘要。**只反映一个主维度**——筛了年份就报年份，
  /// 否则报状态；番号来源、排序等有独立分节，不堆在入口上避免文字变长。
  /// 语义对齐 `MediaBrowseFilterState.triggerLabel`，桌面移动共用一份。
  String get triggerLabel => year?.toString() ?? status.label;

  bool matches(MovieFilterState other) =>
      status == other.status &&
      collectionType == other.collectionType &&
      numberSource == other.numberSource &&
      sortField == other.sortField &&
      sortDirection == other.sortDirection &&
      year == other.year;

  MovieFilterState copyWith({
    MovieStatusFilter? status,
    MovieCollectionTypeFilter? collectionType,
    MovieNumberSourceFilter? numberSource,
    MovieSortField? sortField,
    SortDirection? sortDirection,
    Object? year = _movieFilterUnset,
  }) {
    return MovieFilterState(
      status: status ?? this.status,
      collectionType: collectionType ?? this.collectionType,
      numberSource: numberSource ?? this.numberSource,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      year: identical(year, _movieFilterUnset) ? this.year : year as int?,
    );
  }
}
