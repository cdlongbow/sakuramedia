// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_reviews_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// hot_reviews 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<HotReviewsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(hotReviewsApi)
final hotReviewsApiProvider = HotReviewsApiProvider._();

/// hot_reviews 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<HotReviewsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class HotReviewsApiProvider
    extends $FunctionalProvider<HotReviewsApi, HotReviewsApi, HotReviewsApi>
    with $Provider<HotReviewsApi> {
  /// hot_reviews 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<HotReviewsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  HotReviewsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotReviewsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotReviewsApiHash();

  @$internal
  @override
  $ProviderElement<HotReviewsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HotReviewsApi create(Ref ref) {
    return hotReviewsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HotReviewsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HotReviewsApi>(value),
    );
  }
}

String _$hotReviewsApiHash() => r'8b836efd0ccb990885e8c0d80c7c2a4d94486eb4';
