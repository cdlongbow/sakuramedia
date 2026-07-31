import 'package:sakuramedia/features/playlists/data/playlist_resolution_filter.dart';
import 'package:sakuramedia/features/shared/data/sort_direction.dart';

export 'package:sakuramedia/features/playlists/data/playlist_resolution_filter.dart'
    show PlaylistResolutionFilter, PlaylistResolutionFilterX;
export 'package:sakuramedia/features/shared/data/sort_direction.dart'
    show SortDirection, SortDirectionX;

/// 播放列表影片的排序字段，对齐后端 `sort` 参数的 `field:direction`。
enum PlaylistSortField { heat, bitrate, addedAt, releaseDate }

extension PlaylistSortFieldX on PlaylistSortField {
  String get apiValue => switch (this) {
    PlaylistSortField.heat => 'heat',
    PlaylistSortField.bitrate => 'bitrate',
    PlaylistSortField.addedAt => 'added_at',
    PlaylistSortField.releaseDate => 'release_date',
  };

  String get label => switch (this) {
    PlaylistSortField.heat => '热度',
    PlaylistSortField.bitrate => '码率',
    PlaylistSortField.addedAt => '最近入库',
    PlaylistSortField.releaseDate => '发布时间',
  };
}

const Object _playlistFilterUnset = Object();

/// 播放列表影片列表的筛选状态。
///
/// 语义对齐 `MovieFilterState` / `VideoFilterState`：
/// - `sortField` 为 null 表示不传 `sort`，走后端默认（最近触达/入库倒序）
/// - `resolution` 为 null 表示不筛分辨率（全部档位）
class PlaylistFilterState {
  const PlaylistFilterState({
    this.sortField,
    this.sortDirection = SortDirection.desc,
    this.resolution,
  });

  final PlaylistSortField? sortField;
  final SortDirection sortDirection;
  final PlaylistResolutionFilter? resolution;

  static const PlaylistFilterState initial = PlaylistFilterState();

  bool get isDefault =>
      sortField == null &&
      sortDirection == SortDirection.desc &&
      resolution == null;

  String? get sortExpression =>
      sortField == null
          ? null
          : '${sortField!.apiValue}:${sortDirection.apiValue}';

  /// 筛选入口上显示的当前筛选摘要。
  /// - 两维度都非默认 → `4K · 码率`（分辨率在前，排序在后，用 `·` 分隔）；
  /// - 单维度非默认 → 报该维度；
  /// - 全部默认 → `全部`。
  ///
  /// 这条比「只反映一个主维度」多一步，是为了避免用户在同时叠了排序时
  /// 看到只有分辨率的按钮，误以为排序没生效。
  String get triggerLabel {
    final parts = <String>[
      if (resolution != null) resolution!.label,
      if (sortField != null) sortField!.label,
    ];
    if (parts.isEmpty) {
      return '全部';
    }
    return parts.join(' · ');
  }

  bool matches(PlaylistFilterState other) =>
      sortField == other.sortField &&
      sortDirection == other.sortDirection &&
      resolution == other.resolution;

  PlaylistFilterState copyWith({
    Object? sortField = _playlistFilterUnset,
    SortDirection? sortDirection,
    Object? resolution = _playlistFilterUnset,
  }) {
    return PlaylistFilterState(
      sortField:
          identical(sortField, _playlistFilterUnset)
              ? this.sortField
              : sortField as PlaylistSortField?,
      sortDirection: sortDirection ?? this.sortDirection,
      resolution:
          identical(resolution, _playlistFilterUnset)
              ? this.resolution
              : resolution as PlaylistResolutionFilter?,
    );
  }
}
