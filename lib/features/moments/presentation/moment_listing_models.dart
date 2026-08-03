import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';

/// moments 列表的值类型集合(原与 `PagedMomentController` 同文件,控制器迁
/// Riverpod 后独立成文件):排序/内容类型枚举、筛选值对象、列表项 ViewModel。
/// `MomentListItem` 被 discovery 域与 `widgets/domain/moments/` 复用。

enum MomentSortOrder {
  latest(label: '最新', apiValue: 'created_at:desc'),
  earliest(label: '最早', apiValue: 'created_at:asc');

  const MomentSortOrder({required this.label, required this.apiValue});

  final String label;
  final String apiValue;
}

enum MomentKindFilter {
  jav(label: 'JAV', apiValue: 'jav'),
  video(label: '视频', apiValue: 'video');

  const MomentKindFilter({required this.label, required this.apiValue});

  final String label;
  final String apiValue;
}

/// 时刻列表筛选值对象:`==` 即「筛选未变」,驱动
/// `FilterablePagedAsyncNotifierMixin.applyFilterState` 的短路语义。
@immutable
class MomentsFilter {
  const MomentsFilter({
    this.sortOrder = MomentSortOrder.latest,
    this.kindFilter = MomentKindFilter.jav,
  });

  static const MomentsFilter initial = MomentsFilter();

  final MomentSortOrder sortOrder;
  final MomentKindFilter kindFilter;

  MomentsFilter copyWith({
    MomentSortOrder? sortOrder,
    MomentKindFilter? kindFilter,
  }) {
    return MomentsFilter(
      sortOrder: sortOrder ?? this.sortOrder,
      kindFilter: kindFilter ?? this.kindFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentsFilter &&
        other.sortOrder == sortOrder &&
        other.kindFilter == kindFilter;
  }

  @override
  int get hashCode => Object.hash(sortOrder, kindFilter);
}

class MomentListItem {
  const MomentListItem({
    required this.pointId,
    required this.mediaId,
    required this.movieNumber,
    this.videoItemId,
    required this.thumbnailId,
    required this.offsetSeconds,
    required this.image,
  });

  final int pointId;
  final int mediaId;
  // JAV 时刻带番号；视频时刻为 null（用 videoItemId 区分归属）。
  final String? movieNumber;
  final int? videoItemId;
  final int thumbnailId;
  final int offsetSeconds;
  final MovieImageDto? image;

  bool get isVideo => videoItemId != null && videoItemId! > 0;

  // 卡片标签 / 播放器标题 / 副标题统一走这里，避免三处各拼一遍导致 pointId / videoItemId 不一致。
  String get displayLabel {
    final number = movieNumber;
    if (number != null && number.isNotEmpty) {
      return number;
    }
    final videoId = videoItemId;
    if (videoId != null && videoId > 0) {
      return '视频 #$videoId';
    }
    return '时刻 #$pointId';
  }
}
