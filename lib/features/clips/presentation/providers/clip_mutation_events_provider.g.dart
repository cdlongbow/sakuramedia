// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_mutation_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 切片跨页变更广播源（legacy [ClipMutationChangeNotifier]）的桥。
///
/// 与 `movieSubscriptionBroadcasterProvider` 同一范式：过渡期 Provider 侧与
/// Riverpod 侧共用**同一个**实例，保持「单一广播源」（clips / clip_collections /
/// movies 三域的 report 方与 listen 方彼此可见）。实例由组合根 override 注入。

@ProviderFor(clipMutationBroadcaster)
final clipMutationBroadcasterProvider = ClipMutationBroadcasterProvider._();

/// 切片跨页变更广播源（legacy [ClipMutationChangeNotifier]）的桥。
///
/// 与 `movieSubscriptionBroadcasterProvider` 同一范式：过渡期 Provider 侧与
/// Riverpod 侧共用**同一个**实例，保持「单一广播源」（clips / clip_collections /
/// movies 三域的 report 方与 listen 方彼此可见）。实例由组合根 override 注入。

final class ClipMutationBroadcasterProvider
    extends
        $FunctionalProvider<
          ClipMutationChangeNotifier,
          ClipMutationChangeNotifier,
          ClipMutationChangeNotifier
        >
    with $Provider<ClipMutationChangeNotifier> {
  /// 切片跨页变更广播源（legacy [ClipMutationChangeNotifier]）的桥。
  ///
  /// 与 `movieSubscriptionBroadcasterProvider` 同一范式：过渡期 Provider 侧与
  /// Riverpod 侧共用**同一个**实例，保持「单一广播源」（clips / clip_collections /
  /// movies 三域的 report 方与 listen 方彼此可见）。实例由组合根 override 注入。
  ClipMutationBroadcasterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipMutationBroadcasterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipMutationBroadcasterHash();

  @$internal
  @override
  $ProviderElement<ClipMutationChangeNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClipMutationChangeNotifier create(Ref ref) {
    return clipMutationBroadcaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipMutationChangeNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipMutationChangeNotifier>(value),
    );
  }
}

String _$clipMutationBroadcasterHash() =>
    r'7558c20d61eac04ffc00d0f74b986a1f0464af9f';

/// 切片变更事件流：把 `notifyListeners` 翻译成一条条 [ClipMutationChange]。
///
/// 消费方 `ref.listen(clipMutationEventsProvider, ...)` 后做就地补丁
/// （删除→移出网格；合集成员变化→重拉合集列表），不 invalidate 整页重拉。

@ProviderFor(clipMutationEvents)
final clipMutationEventsProvider = ClipMutationEventsProvider._();

/// 切片变更事件流：把 `notifyListeners` 翻译成一条条 [ClipMutationChange]。
///
/// 消费方 `ref.listen(clipMutationEventsProvider, ...)` 后做就地补丁
/// （删除→移出网格；合集成员变化→重拉合集列表），不 invalidate 整页重拉。

final class ClipMutationEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipMutationChange>,
          ClipMutationChange,
          Stream<ClipMutationChange>
        >
    with
        $FutureModifier<ClipMutationChange>,
        $StreamProvider<ClipMutationChange> {
  /// 切片变更事件流：把 `notifyListeners` 翻译成一条条 [ClipMutationChange]。
  ///
  /// 消费方 `ref.listen(clipMutationEventsProvider, ...)` 后做就地补丁
  /// （删除→移出网格；合集成员变化→重拉合集列表），不 invalidate 整页重拉。
  ClipMutationEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipMutationEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipMutationEventsHash();

  @$internal
  @override
  $StreamProviderElement<ClipMutationChange> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ClipMutationChange> create(Ref ref) {
    return clipMutationEvents(ref);
  }
}

String _$clipMutationEventsHash() =>
    r'87dc03982b15d4d80135a2eb6dc65c44e843b6c4';
