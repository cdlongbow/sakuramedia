import 'package:flutter/foundation.dart';

/// 视频列表页面的缓存身份。
///
/// 桌面 PornBox 与移动 Pornbox 原先各自持有缓存 entry；family 保持两个独立
/// scope，避免筛选和分页进度在两个宿主之间串用。
@immutable
class VideoSummaryScope {
  const VideoSummaryScope._(this.cacheKey);

  const VideoSummaryScope.desktop() : this._('desktop:videos:list');
  const VideoSummaryScope.mobile() : this._('mobile:pornbox:list');

  final String cacheKey;

  @override
  bool operator ==(Object other) =>
      other is VideoSummaryScope && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}
