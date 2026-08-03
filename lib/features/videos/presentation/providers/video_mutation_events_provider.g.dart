// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_mutation_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// videos 域跨页变更事件流：把 [VideoMutationChangeNotifier] 的
/// `notifyListeners` 翻译成一条条 [VideoMutationChange]（消费方
/// `ref.listen(videoMutationEventsProvider, ...)` 后读快照做就地补丁，
/// 不 invalidate 整页重拉）。

@ProviderFor(videoMutationEvents)
final videoMutationEventsProvider = VideoMutationEventsProvider._();

/// videos 域跨页变更事件流：把 [VideoMutationChangeNotifier] 的
/// `notifyListeners` 翻译成一条条 [VideoMutationChange]（消费方
/// `ref.listen(videoMutationEventsProvider, ...)` 后读快照做就地补丁，
/// 不 invalidate 整页重拉）。

final class VideoMutationEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<VideoMutationChange>,
          VideoMutationChange,
          Stream<VideoMutationChange>
        >
    with
        $FutureModifier<VideoMutationChange>,
        $StreamProvider<VideoMutationChange> {
  /// videos 域跨页变更事件流：把 [VideoMutationChangeNotifier] 的
  /// `notifyListeners` 翻译成一条条 [VideoMutationChange]（消费方
  /// `ref.listen(videoMutationEventsProvider, ...)` 后读快照做就地补丁，
  /// 不 invalidate 整页重拉）。
  VideoMutationEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoMutationEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoMutationEventsHash();

  @$internal
  @override
  $StreamProviderElement<VideoMutationChange> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<VideoMutationChange> create(Ref ref) {
    return videoMutationEvents(ref);
  }
}

String _$videoMutationEventsHash() =>
    r'68d215cc6249716db1a310bedddbd4f8fe684362';
