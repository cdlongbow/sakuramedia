// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_import_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// media_import 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MediaImportApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(mediaImportApi)
final mediaImportApiProvider = MediaImportApiProvider._();

/// media_import 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MediaImportApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class MediaImportApiProvider
    extends $FunctionalProvider<MediaImportApi, MediaImportApi, MediaImportApi>
    with $Provider<MediaImportApi> {
  /// media_import 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<MediaImportApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  MediaImportApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaImportApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaImportApiHash();

  @$internal
  @override
  $ProviderElement<MediaImportApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaImportApi create(Ref ref) {
    return mediaImportApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaImportApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaImportApi>(value),
    );
  }
}

String _$mediaImportApiHash() => r'84111bad84b77a64541abcf95d9d6c7eb927c95a';
