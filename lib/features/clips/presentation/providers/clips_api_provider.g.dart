// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clips_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// clips 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ClipsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(clipsApi)
final clipsApiProvider = ClipsApiProvider._();

/// clips 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ClipsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ClipsApiProvider
    extends $FunctionalProvider<ClipsApi, ClipsApi, ClipsApi>
    with $Provider<ClipsApi> {
  /// clips 域 API 的 Riverpod 入口。
  ///
  /// 原生装配（组合根反转后）。测试用
  /// `overrideWithValue(context.read<ClipsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ClipsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipsApiHash();

  @$internal
  @override
  $ProviderElement<ClipsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClipsApi create(Ref ref) {
    return clipsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipsApi>(value),
    );
  }
}

String _$clipsApiHash() => r'0cc500587c13a3c11ba17732491588c43295dbcf';
