// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// configuration 域 ConfigApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ConfigApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(configApi)
final configApiProvider = ConfigApiProvider._();

/// configuration 域 ConfigApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ConfigApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ConfigApiProvider
    extends $FunctionalProvider<ConfigApi, ConfigApi, ConfigApi>
    with $Provider<ConfigApi> {
  /// configuration 域 ConfigApi 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ConfigApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ConfigApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configApiHash();

  @$internal
  @override
  $ProviderElement<ConfigApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfigApi create(Ref ref) {
    return configApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigApi>(value),
    );
  }
}

String _$configApiHash() => r'c2e479622bd11509651a23204a75cc40934aee8e';
