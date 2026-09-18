import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';

part 'recently_played_playlist_provider.g.dart';

/// 系统维护的「最近播放」播放列表。
///
/// 后端在首次产生播放记录时才建这个列表，所以从未播放过影片时返回 null，
/// 概览页据此隐藏「最近播放」分区。列表条目按最近触达时间倒序。
@riverpod
Future<PlaylistDto?> recentlyPlayedPlaylist(Ref ref) async {
  final playlists = await ref
      .watch(playlistsApiProvider)
      .getPlaylists(includeSystem: true);
  for (final playlist in playlists) {
    if (playlist.kind == PlaylistKind.recentlyPlayed) {
      return playlist;
    }
  }
  return null;
}
