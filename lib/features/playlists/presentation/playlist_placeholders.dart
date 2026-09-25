import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 播放列表加载态占位：真实 [PlaylistDto] + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实管理卡同形的静态骨架。
List<PlaylistDto> playlistPlaceholders({int count = 3}) {
  return List<PlaylistDto>.generate(
    count,
    (index) => PlaylistDto(
      id: -1 - index,
      name: BoneMock.words(2),
      kind: 'custom',
      description: BoneMock.words(6),
      isSystem: false,
      isMutable: true,
      isDeletable: true,
      movieCount: 12,
      createdAt: null,
      updatedAt: null,
    ),
    growable: false,
  );
}
