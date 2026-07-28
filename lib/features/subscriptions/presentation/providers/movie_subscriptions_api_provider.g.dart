// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_subscriptions_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅管理 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MovieSubscriptionsApi>())` 注入。

@ProviderFor(movieSubscriptionsApi)
final movieSubscriptionsApiProvider = MovieSubscriptionsApiProvider._();

/// 订阅管理 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MovieSubscriptionsApi>())` 注入。

final class MovieSubscriptionsApiProvider
    extends
        $FunctionalProvider<
          MovieSubscriptionsApi,
          MovieSubscriptionsApi,
          MovieSubscriptionsApi
        >
    with $Provider<MovieSubscriptionsApi> {
  /// 订阅管理 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<MovieSubscriptionsApi>())` 注入。
  MovieSubscriptionsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'movieSubscriptionsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movieSubscriptionsApiHash();

  @$internal
  @override
  $ProviderElement<MovieSubscriptionsApi> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MovieSubscriptionsApi create(Ref ref) {
    return movieSubscriptionsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MovieSubscriptionsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MovieSubscriptionsApi>(value),
    );
  }
}

String _$movieSubscriptionsApiHash() =>
    r'949f73e72d122e619f628320716b4d545d16b8a2';
