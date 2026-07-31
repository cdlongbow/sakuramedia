// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// playlists 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<PlaylistsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(playlistsApi)
final playlistsApiProvider = PlaylistsApiProvider._();

/// playlists 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<PlaylistsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class PlaylistsApiProvider
    extends $FunctionalProvider<PlaylistsApi, PlaylistsApi, PlaylistsApi>
    with $Provider<PlaylistsApi> {
  /// playlists 域 API 的 Riverpod 入口。
  ///
  /// 原生装配（组合根反转后）。测试用
  /// `overrideWithValue(context.read<PlaylistsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  PlaylistsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistsApiHash();

  @$internal
  @override
  $ProviderElement<PlaylistsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaylistsApi create(Ref ref) {
    return playlistsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistsApi>(value),
    );
  }
}

String _$playlistsApiHash() => r'187c4ca7849a7e9314d6d7fb62b8c71ad1ed76fe';
