// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_sse_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 导入双子星共用的 SSE 状态机工厂。
///
/// 工厂 provider 让 notifier 直接单测可注入 [FakeSseChannel]，生产参数固定锁定
/// `[2,5,10,30]s`、逐事件下发、bootstrap 失败退避，以及 unsupported 放弃。

@ProviderFor(importSseChannelFactory)
final importSseChannelFactoryProvider = ImportSseChannelFactoryProvider._();

/// 导入双子星共用的 SSE 状态机工厂。
///
/// 工厂 provider 让 notifier 直接单测可注入 [FakeSseChannel]，生产参数固定锁定
/// `[2,5,10,30]s`、逐事件下发、bootstrap 失败退避，以及 unsupported 放弃。

final class ImportSseChannelFactoryProvider
    extends
        $FunctionalProvider<
          ImportSseChannelFactory,
          ImportSseChannelFactory,
          ImportSseChannelFactory
        >
    with $Provider<ImportSseChannelFactory> {
  /// 导入双子星共用的 SSE 状态机工厂。
  ///
  /// 工厂 provider 让 notifier 直接单测可注入 [FakeSseChannel]，生产参数固定锁定
  /// `[2,5,10,30]s`、逐事件下发、bootstrap 失败退避，以及 unsupported 放弃。
  ImportSseChannelFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importSseChannelFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importSseChannelFactoryHash();

  @$internal
  @override
  $ProviderElement<ImportSseChannelFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportSseChannelFactory create(Ref ref) {
    return importSseChannelFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportSseChannelFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportSseChannelFactory>(value),
    );
  }
}

String _$importSseChannelFactoryHash() =>
    r'804bfa40b9c86e384715b087d4f6374d43eb2b90';
