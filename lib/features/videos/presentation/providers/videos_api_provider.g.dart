// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'videos_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// videos 域三个 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<...>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(videosApi)
final videosApiProvider = VideosApiProvider._();

/// videos 域三个 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<...>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class VideosApiProvider
    extends $FunctionalProvider<VideosApi, VideosApi, VideosApi>
    with $Provider<VideosApi> {
  /// videos 域三个 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<...>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  VideosApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videosApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videosApiHash();

  @$internal
  @override
  $ProviderElement<VideosApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideosApi create(Ref ref) {
    return videosApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideosApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideosApi>(value),
    );
  }
}

String _$videosApiHash() => r'629b63c4a902db9b5880f1c30b64dcba3876ad0d';

@ProviderFor(videoCollectionsApi)
final videoCollectionsApiProvider = VideoCollectionsApiProvider._();

final class VideoCollectionsApiProvider
    extends
        $FunctionalProvider<
          VideoCollectionsApi,
          VideoCollectionsApi,
          VideoCollectionsApi
        >
    with $Provider<VideoCollectionsApi> {
  VideoCollectionsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoCollectionsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoCollectionsApiHash();

  @$internal
  @override
  $ProviderElement<VideoCollectionsApi> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoCollectionsApi create(Ref ref) {
    return videoCollectionsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoCollectionsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoCollectionsApi>(value),
    );
  }
}

String _$videoCollectionsApiHash() =>
    r'187f1a5aea700b9be17f542bc8faf04a2f4b306d';

@ProviderFor(videoImportsApi)
final videoImportsApiProvider = VideoImportsApiProvider._();

final class VideoImportsApiProvider
    extends
        $FunctionalProvider<VideoImportsApi, VideoImportsApi, VideoImportsApi>
    with $Provider<VideoImportsApi> {
  VideoImportsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoImportsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoImportsApiHash();

  @$internal
  @override
  $ProviderElement<VideoImportsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideoImportsApi create(Ref ref) {
    return videoImportsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoImportsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoImportsApi>(value),
    );
  }
}

String _$videoImportsApiHash() => r'd7c4f8451f699066eb5a4e2d2ae274700e704bfb';
