// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actors_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// actors 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActorsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(actorsApi)
final actorsApiProvider = ActorsApiProvider._();

/// actors 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActorsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ActorsApiProvider
    extends $FunctionalProvider<ActorsApi, ActorsApi, ActorsApi>
    with $Provider<ActorsApi> {
  /// actors 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ActorsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ActorsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actorsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actorsApiHash();

  @$internal
  @override
  $ProviderElement<ActorsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActorsApi create(Ref ref) {
    return actorsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActorsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActorsApi>(value),
    );
  }
}

String _$actorsApiHash() => r'f1a6463f59b5ca6e12438bdafe04b801370191e3';
