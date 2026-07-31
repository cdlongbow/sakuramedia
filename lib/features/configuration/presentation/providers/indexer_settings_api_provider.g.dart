// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indexer_settings_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// configuration 域 IndexerSettingsApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<IndexerSettingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(indexerSettingsApi)
final indexerSettingsApiProvider = IndexerSettingsApiProvider._();

/// configuration 域 IndexerSettingsApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<IndexerSettingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class IndexerSettingsApiProvider
    extends
        $FunctionalProvider<
          IndexerSettingsApi,
          IndexerSettingsApi,
          IndexerSettingsApi
        >
    with $Provider<IndexerSettingsApi> {
  /// configuration 域 IndexerSettingsApi 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<IndexerSettingsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  IndexerSettingsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexerSettingsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexerSettingsApiHash();

  @$internal
  @override
  $ProviderElement<IndexerSettingsApi> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IndexerSettingsApi create(Ref ref) {
    return indexerSettingsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IndexerSettingsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IndexerSettingsApi>(value),
    );
  }
}

String _$indexerSettingsApiHash() =>
    r'b9e943f5ca9d2fe3acd72a15520f513aaf4b3957';
