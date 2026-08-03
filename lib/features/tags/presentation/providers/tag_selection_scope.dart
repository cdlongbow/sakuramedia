import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';

/// 标签页选择区的 family 身份。
///
/// 根页面沿用旧缓存 key；从影片详情跳入的预选标签页保留独立、离开即释放的
/// 生命周期，避免将其临时选择覆盖一级入口。
@immutable
class TagSelectionScope {
  const TagSelectionScope._({
    required this.instanceKey,
    required this.popularLimit,
    this.cacheKey,
    this.initialSelectedTagIds = const <int>[],
    this.initialMatchMode = TagMatchMode.or,
  });

  const TagSelectionScope.desktopRoot()
    : this._(
        instanceKey: 'desktop:tags:list',
        cacheKey: 'desktop:tags:list',
        popularLimit: 15,
      );

  const TagSelectionScope.mobileRoot()
    : this._(
        instanceKey: 'mobile:tags:list',
        cacheKey: 'mobile:tags:list',
        popularLimit: 5,
      );

  const TagSelectionScope.custom({
    required String instanceKey,
    int popularLimit = 60,
    List<int> initialSelectedTagIds = const <int>[],
    TagMatchMode initialMatchMode = TagMatchMode.or,
  }) : this._(
         instanceKey: instanceKey,
         popularLimit: popularLimit,
         initialSelectedTagIds: initialSelectedTagIds,
         initialMatchMode: initialMatchMode,
       );

  TagSelectionScope.desktopDetail({required int initialTagId})
    : this._(
        instanceKey: 'desktop:tags:detail:$initialTagId',
        popularLimit: 15,
        initialSelectedTagIds: <int>[initialTagId],
      );

  TagSelectionScope.mobileDetail({required int initialTagId})
    : this._(
        instanceKey: 'mobile:tags:detail:$initialTagId',
        popularLimit: 5,
        initialSelectedTagIds: <int>[initialTagId],
      );

  final String instanceKey;
  final String? cacheKey;
  final int popularLimit;
  final List<int> initialSelectedTagIds;
  final TagMatchMode initialMatchMode;

  @override
  bool operator ==(Object other) {
    return other is TagSelectionScope &&
        other.instanceKey == instanceKey &&
        other.cacheKey == cacheKey &&
        other.popularLimit == popularLimit &&
        listEquals(other.initialSelectedTagIds, initialSelectedTagIds) &&
        other.initialMatchMode == initialMatchMode;
  }

  @override
  int get hashCode => Object.hash(
    instanceKey,
    cacheKey,
    popularLimit,
    Object.hashAll(initialSelectedTagIds),
    initialMatchMode,
  );
}
