import 'package:sakuramedia/features/actors/data/dto/actor_detail_dto.dart';
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

/// 女优详情加载态占位：详情头 + 影片网格同形渲染，由 `AppSkeletonizer` 灰化。
ActorDetailDto actorDetailPlaceholder() {
  return ActorDetailDto(summary: actorListItemPlaceholders(count: 1).single);
}
