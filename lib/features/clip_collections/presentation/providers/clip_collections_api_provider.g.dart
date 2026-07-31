// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_collections_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// clip_collections 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(clipCollectionsApi)
final clipCollectionsApiProvider = ClipCollectionsApiProvider._();

/// clip_collections 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
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
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
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
    r'd2cfdb00a9521e4c2a2a9a2a2e4f87d64adec54c';
