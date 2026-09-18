// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_played_playlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 系统维护的「最近播放」播放列表。
///
/// 后端在首次产生播放记录时才建这个列表，所以从未播放过影片时返回 null，
/// 概览页据此隐藏「最近播放」分区。列表条目按最近触达时间倒序。

@ProviderFor(recentlyPlayedPlaylist)
final recentlyPlayedPlaylistProvider = RecentlyPlayedPlaylistProvider._();

/// 系统维护的「最近播放」播放列表。
///
/// 后端在首次产生播放记录时才建这个列表，所以从未播放过影片时返回 null，
/// 概览页据此隐藏「最近播放」分区。列表条目按最近触达时间倒序。

final class RecentlyPlayedPlaylistProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlaylistDto?>,
          PlaylistDto?,
          FutureOr<PlaylistDto?>
        >
    with $FutureModifier<PlaylistDto?>, $FutureProvider<PlaylistDto?> {
  /// 系统维护的「最近播放」播放列表。
  ///
  /// 后端在首次产生播放记录时才建这个列表，所以从未播放过影片时返回 null，
  /// 概览页据此隐藏「最近播放」分区。列表条目按最近触达时间倒序。
  RecentlyPlayedPlaylistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentlyPlayedPlaylistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentlyPlayedPlaylistHash();

  @$internal
  @override
  $FutureProviderElement<PlaylistDto?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlaylistDto?> create(Ref ref) {
    return recentlyPlayedPlaylist(ref);
  }
}

String _$recentlyPlayedPlaylistHash() =>
    r'464564dfff14256955ec4bf8c979df24fcb7d3d1';
