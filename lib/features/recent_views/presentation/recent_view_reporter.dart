import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/recent_views/data/dto/recent_view_dto.dart';
import 'package:sakuramedia/features/recent_views/presentation/providers/recent_views_api_provider.dart';

/// 详情页浏览上报：fire-and-forget，失败静默。
///
/// 浏览记录不是关键路径，只由页面驱动的详情加载 / 手势刷新成功路径触发；
/// 播放器、检查器、订阅切换等不经过详情页的路径不触发。
void reportRecentView(
  Ref ref, {
  required RecentViewEntityType entityType,
  required int entityId,
}) {
  if (entityId <= 0) {
    return;
  }
  ref
      .read(recentViewsApiProvider)
      .record(entityType: entityType, entityId: entityId)
      .ignore();
}
