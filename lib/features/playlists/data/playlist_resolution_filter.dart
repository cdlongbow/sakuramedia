/// 播放列表影片的分辨率筛选档位。
///
/// 精确档位匹配：按影片最高分辨率媒体归入唯一档位（8K / 4K 互斥）。
///
/// 放在 data 层是因为它既表达后端 `resolution` 参数的取值，也定义了展示顺序，
/// data 层的 API/DTO 需要按此顺序稳定排序返回值；presentation 层通过
/// [`playlist_filter_state.dart`] 的 re-export 引用。
enum PlaylistResolutionFilter { k8k, k4k, k2k, f1080p, f720p, f480p, f360p }

extension PlaylistResolutionFilterX on PlaylistResolutionFilter {
  String get apiValue => switch (this) {
    PlaylistResolutionFilter.k8k => '8K',
    PlaylistResolutionFilter.k4k => '4K',
    PlaylistResolutionFilter.k2k => '2K',
    PlaylistResolutionFilter.f1080p => '1080P',
    PlaylistResolutionFilter.f720p => '720P',
    PlaylistResolutionFilter.f480p => '480P',
    PlaylistResolutionFilter.f360p => '360P',
  };

  String get label => apiValue;

  static PlaylistResolutionFilter? fromApiValue(String value) {
    for (final filter in PlaylistResolutionFilter.values) {
      if (filter.apiValue == value) {
        return filter;
      }
    }
    return null;
  }
}
