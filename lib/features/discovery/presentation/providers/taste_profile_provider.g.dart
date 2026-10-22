// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 口味画像：发现页与女优页共用一份，订阅变更由事件广播就地补丁。

@ProviderFor(TasteProfile)
final tasteProfileProvider = TasteProfileProvider._();

/// 口味画像：发现页与女优页共用一份，订阅变更由事件广播就地补丁。
final class TasteProfileProvider
    extends $AsyncNotifierProvider<TasteProfile, TasteProfileDto> {
  /// 口味画像：发现页与女优页共用一份，订阅变更由事件广播就地补丁。
  TasteProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'tasteProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasteProfileHash();

  @$internal
  @override
  TasteProfile create() => TasteProfile();
}

String _$tasteProfileHash() => r'1c8202c1e283d87c1c38a084d3aecd2f259fa6e0';

/// 口味画像：发现页与女优页共用一份，订阅变更由事件广播就地补丁。

abstract class _$TasteProfile extends $AsyncNotifier<TasteProfileDto> {
  FutureOr<TasteProfileDto> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TasteProfileDto>, TasteProfileDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TasteProfileDto>, TasteProfileDto>,
              AsyncValue<TasteProfileDto>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
