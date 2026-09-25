import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 女优相关加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片同形的静态骨架。
List<ActorListItemDto> actorListItemPlaceholders({int count = 8}) {
  return List<ActorListItemDto>.generate(
    count,
    (index) => ActorListItemDto(
      id: -1 - index,
      javdbId: 'actor-placeholder-${index + 1}',
      name: BoneMock.words(2),
      aliasName: '',
      profileImage: null,
      isSubscribed: false,
    ),
    growable: false,
  );
}
