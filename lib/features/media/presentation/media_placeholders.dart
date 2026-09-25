import 'package:sakuramedia/features/media/data/media_point_list_item_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 媒体相关加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片 / 选项行同形的静态骨架。
List<MediaPointListItemDto> mediaPointListItemPlaceholders({int count = 6}) {
  return List<MediaPointListItemDto>.generate(
    count,
    (index) => MediaPointListItemDto(
      pointId: -1 - index,
      mediaId: -1 - index,
      movieNumber: 'ABC-${(index + 1).toString().padLeft(3, '0')}',
      thumbnailId: -1 - index,
      offsetSeconds: 90,
      image: null,
      createdAt: null,
    ),
    growable: false,
  );
}
