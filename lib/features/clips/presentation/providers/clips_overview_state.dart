import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_filter.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';

/// 我的切片首页 State：分页段 + 当前筛选 + 「筛选切换正在拉新数据」标志位。
///
/// [isReloading] 由 `FilterablePagedAsyncNotifierMixin` 的 preserveList 策略
/// 在 `copyWithReloading` 中写入，页面可据此显示行内薄进度条；当前不消费。
@immutable
class ClipsOverviewState {
  const ClipsOverviewState({
    this.paged = const PagedListState<MediaClipDto>(),
    this.filter = const ClipsFilter(),
    this.isReloading = false,
  });

  final PagedListState<MediaClipDto> paged;
  final ClipsFilter filter;
  final bool isReloading;

  ClipsOverviewState copyWith({
    PagedListState<MediaClipDto>? paged,
    ClipsFilter? filter,
    bool? isReloading,
  }) {
    return ClipsOverviewState(
      paged: paged ?? this.paged,
      filter: filter ?? this.filter,
      isReloading: isReloading ?? this.isReloading,
    );
  }
}
