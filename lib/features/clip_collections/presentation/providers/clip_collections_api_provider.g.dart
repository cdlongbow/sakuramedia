// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_collections_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// clip_collections 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(clipCollectionsApi)
final clipCollectionsApiProvider = ClipCollectionsApiProvider._();

/// clip_collections 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ClipCollectionsApiProvider
    extends
        $FunctionalProvider<
          ClipCollectionsApi,
          ClipCollectionsApi,
          ClipCollectionsApi
        >
    with $Provider<ClipCollectionsApi> {
  /// clip_collections 域 API 的 Riverpod 入口。
  ///
  /// 原生装配（组合根反转后）。测试用
  /// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ClipCollectionsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipCollectionsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipCollectionsApiHash();

  @$internal
  @override
  $ProviderElement<ClipCollectionsApi> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClipCollectionsApi create(Ref ref) {
    return clipCollectionsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipCollectionsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipCollectionsApi>(value),
    );
  }
}

String _$clipCollectionsApiHash() =>
    r'05c77987796ac9d1636618718916677ae079b520';
