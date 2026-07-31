// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 [ApiClient] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ApiClient>())` 注入——迁移过渡期 Provider
/// 侧是真源，组合根反转后改为原生装配。

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// 全局 [ApiClient] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ApiClient>())` 注入——迁移过渡期 Provider
/// 侧是真源，组合根反转后改为原生装配。

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// 全局 [ApiClient] 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ApiClient>())` 注入——迁移过渡期 Provider
  /// 侧是真源，组合根反转后改为原生装配。
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'5aa2af31962c8f4383a2875e4ac316038a928b56';
