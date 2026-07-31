// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// discovery 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<DiscoveryApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(discoveryApi)
final discoveryApiProvider = DiscoveryApiProvider._();

/// discovery 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<DiscoveryApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class DiscoveryApiProvider
    extends $FunctionalProvider<DiscoveryApi, DiscoveryApi, DiscoveryApi>
    with $Provider<DiscoveryApi> {
  /// discovery 域 API 的 Riverpod 入口。
  ///
  /// 原生装配（组合根反转后）。测试用
  /// `overrideWithValue(context.read<DiscoveryApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  DiscoveryApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryApiHash();

  @$internal
  @override
  $ProviderElement<DiscoveryApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiscoveryApi create(Ref ref) {
    return discoveryApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiscoveryApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiscoveryApi>(value),
    );
  }
}

String _$discoveryApiHash() => r'e9d76186fa7039393fb9b6939cff3519ae54ca3c';
