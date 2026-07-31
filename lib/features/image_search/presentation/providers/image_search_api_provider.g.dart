// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_search_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// image_search 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ImageSearchApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(imageSearchApi)
final imageSearchApiProvider = ImageSearchApiProvider._();

/// image_search 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ImageSearchApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ImageSearchApiProvider
    extends $FunctionalProvider<ImageSearchApi, ImageSearchApi, ImageSearchApi>
    with $Provider<ImageSearchApi> {
  /// image_search 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ImageSearchApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ImageSearchApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageSearchApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageSearchApiHash();

  @$internal
  @override
  $ProviderElement<ImageSearchApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageSearchApi create(Ref ref) {
    return imageSearchApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageSearchApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageSearchApi>(value),
    );
  }
}

String _$imageSearchApiHash() => r'e25675a3c10c18826a3b45411ec3f3cc0017bd9e';
