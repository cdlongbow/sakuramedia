import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/shared/data/sort_direction.dart';

enum ActorSubscriptionStatus { all, subscribed, unsubscribed }

extension ActorSubscriptionStatusX on ActorSubscriptionStatus {
  String get apiValue => switch (this) {
    ActorSubscriptionStatus.all => 'all',
    ActorSubscriptionStatus.subscribed => 'subscribed',
    ActorSubscriptionStatus.unsubscribed => 'unsubscribed',
  };

  String get label => switch (this) {
    ActorSubscriptionStatus.all => '全部',
    ActorSubscriptionStatus.subscribed => '已订阅',
    ActorSubscriptionStatus.unsubscribed => '未订阅',
  };
}

enum ActorGender { all, female, male }

extension ActorGenderX on ActorGender {
  String get apiValue => switch (this) {
    ActorGender.all => 'all',
    ActorGender.female => 'female',
    ActorGender.male => 'male',
  };

  String get label => switch (this) {
    ActorGender.all => '全部',
    ActorGender.female => '女优',
    ActorGender.male => '男优',
  };
}

enum ActorSortField {
  subscribedAt,
  name,
  movieCount,
  playableMovieCount,
  age,
  heightCm,
  bustCm,
  waistCm,
  hipsCm,
  waistHipRatio,
  cup,
}

extension ActorSortFieldX on ActorSortField {
  String get apiValue => switch (this) {
    ActorSortField.subscribedAt => 'subscribed_at',
    ActorSortField.name => 'name',
    ActorSortField.movieCount => 'movie_count',
    ActorSortField.playableMovieCount => 'playable_movie_count',
    ActorSortField.age => 'age',
    ActorSortField.heightCm => 'height_cm',
    ActorSortField.bustCm => 'bust_cm',
    ActorSortField.waistCm => 'waist_cm',
    ActorSortField.hipsCm => 'hips_cm',
    ActorSortField.waistHipRatio => 'waist_hip_ratio',
    ActorSortField.cup => 'cup',
  };

  String get label => switch (this) {
    ActorSortField.subscribedAt => '最近订阅',
    ActorSortField.name => '名称',
    ActorSortField.movieCount => '影片数',
    ActorSortField.playableMovieCount => '可播放影片数',
    ActorSortField.age => '年龄',
    ActorSortField.heightCm => '身高',
    ActorSortField.bustCm => '胸围',
    ActorSortField.waistCm => '腰围',
    ActorSortField.hipsCm => '臀围',
    ActorSortField.waistHipRatio => '腰臀比',
    ActorSortField.cup => '罩杯',
  };
}

@immutable
class ActorFilterState {
  const ActorFilterState({
    this.subscriptionStatus = ActorSubscriptionStatus.subscribed,
    this.gender = ActorGender.all,
    this.hasPlayableMovies = false,
    this.query,
    this.sortField = ActorSortField.subscribedAt,
    this.sortDirection = SortDirection.desc,
    this.ageMin,
    this.ageMax,
    this.heightMin,
    this.heightMax,
    this.cups = const <String>[],
  });

  final ActorSubscriptionStatus subscriptionStatus;
  final ActorGender gender;

  /// 只看存在可播放影片的女优；接口参数 `has_playable_movies`。
  final bool hasPlayableMovies;

  /// 关键词搜索；`null` 表示不搜索。调用方保证已去空白。
  final String? query;
  final ActorSortField sortField;
  final SortDirection sortDirection;
  final int? ageMin;
  final int? ageMax;
  final int? heightMin;
  final int? heightMax;
  final List<String> cups;

  static const ActorFilterState initial = ActorFilterState();

  bool get isDefault =>
      subscriptionStatus == ActorSubscriptionStatus.subscribed &&
      gender == ActorGender.all &&
      !hasPlayableMovies &&
      query == null &&
      sortField == ActorSortField.subscribedAt &&
      sortDirection == SortDirection.desc &&
      ageMin == null &&
      ageMax == null &&
      heightMin == null &&
      heightMax == null &&
      cups.isEmpty;

  String get sortExpression =>
      '${sortField.apiValue}:${sortDirection.apiValue}';

  /// 只反映订阅状态这一主维度；性别 / 排序有独立分节，不堆在入口上。
  /// 语义对齐 `MovieFilterState.triggerLabel`。
  String get triggerLabel => subscriptionStatus.label;

  /// 女优搜索入口专用：从无关键词开始搜索时把默认的「已订阅」放宽为「全部」，
  /// 避免在订阅视图下搜不到未订阅女优；搜索过程中继续输入不覆盖用户改过的筛选。
  ActorFilterState withSearchQuery(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return copyWith(query: null);
    }
    final isStartingSearch = (query ?? '').isEmpty;
    return copyWith(
      query: trimmed,
      subscriptionStatus:
          isStartingSearch &&
              subscriptionStatus == ActorSubscriptionStatus.subscribed
          ? ActorSubscriptionStatus.all
          : subscriptionStatus,
    );
  }

  ActorFilterState copyWith({
    ActorSubscriptionStatus? subscriptionStatus,
    ActorGender? gender,
    bool? hasPlayableMovies,
    Object? query = _unset,
    ActorSortField? sortField,
    SortDirection? sortDirection,
    Object? ageMin = _unset,
    Object? ageMax = _unset,
    Object? heightMin = _unset,
    Object? heightMax = _unset,
    List<String>? cups,
  }) {
    return ActorFilterState(
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      gender: gender ?? this.gender,
      hasPlayableMovies: hasPlayableMovies ?? this.hasPlayableMovies,
      query: identical(query, _unset) ? this.query : query as String?,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      ageMin: identical(ageMin, _unset) ? this.ageMin : ageMin as int?,
      ageMax: identical(ageMax, _unset) ? this.ageMax : ageMax as int?,
      heightMin: identical(heightMin, _unset)
          ? this.heightMin
          : heightMin as int?,
      heightMax: identical(heightMax, _unset)
          ? this.heightMax
          : heightMax as int?,
      cups: cups ?? this.cups,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActorFilterState &&
        other.subscriptionStatus == subscriptionStatus &&
        other.gender == gender &&
        other.hasPlayableMovies == hasPlayableMovies &&
        other.query == query &&
        other.sortField == sortField &&
        other.sortDirection == sortDirection &&
        other.ageMin == ageMin &&
        other.ageMax == ageMax &&
        other.heightMin == heightMin &&
        other.heightMax == heightMax &&
        listEquals(other.cups, cups);
  }

  @override
  int get hashCode => Object.hash(
    subscriptionStatus,
    gender,
    hasPlayableMovies,
    query,
    sortField,
    sortDirection,
    ageMin,
    ageMax,
    heightMin,
    heightMax,
    Object.hashAll(cups),
  );
}

const Object _unset = Object();
