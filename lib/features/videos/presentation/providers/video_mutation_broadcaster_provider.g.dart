// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_mutation_broadcaster_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// videos 域跨页变更广播源（legacy [VideoMutationChangeNotifier] 桥）。
///
/// 与 clips 的 `clipMutationBroadcasterProvider` 同构：clip / video / movie
/// 三域广播源现在都用 `@Riverpod(keepAlive: true)` 原生装配（本文件是最后一个
/// 从 legacy `ChangeNotifierProvider` 迁过来的样板，也是压轴批 8「三大广播源
/// 本体 Notifier 化」的探路：先把 broadcaster provider 装配统一，本体真正
/// Notifier 化留批 8）。
///
/// 消费方 `ref.read(...)` 拿实例后仍走 addListener（未收敛的消费点）或
/// `ref.listen(videoMutationEventsProvider, ...)`（已单轨化的消费点）。

@ProviderFor(videoMutationBroadcaster)
final videoMutationBroadcasterProvider = VideoMutationBroadcasterProvider._();

/// videos 域跨页变更广播源（legacy [VideoMutationChangeNotifier] 桥）。
///
/// 与 clips 的 `clipMutationBroadcasterProvider` 同构：clip / video / movie
/// 三域广播源现在都用 `@Riverpod(keepAlive: true)` 原生装配（本文件是最后一个
/// 从 legacy `ChangeNotifierProvider` 迁过来的样板，也是压轴批 8「三大广播源
/// 本体 Notifier 化」的探路：先把 broadcaster provider 装配统一，本体真正
/// Notifier 化留批 8）。
///
/// 消费方 `ref.read(...)` 拿实例后仍走 addListener（未收敛的消费点）或
/// `ref.listen(videoMutationEventsProvider, ...)`（已单轨化的消费点）。

final class VideoMutationBroadcasterProvider
    extends
        $FunctionalProvider<
          VideoMutationChangeNotifier,
          VideoMutationChangeNotifier,
          VideoMutationChangeNotifier
        >
    with $Provider<VideoMutationChangeNotifier> {
  /// videos 域跨页变更广播源（legacy [VideoMutationChangeNotifier] 桥）。
  ///
  /// 与 clips 的 `clipMutationBroadcasterProvider` 同构：clip / video / movie
  /// 三域广播源现在都用 `@Riverpod(keepAlive: true)` 原生装配（本文件是最后一个
  /// 从 legacy `ChangeNotifierProvider` 迁过来的样板，也是压轴批 8「三大广播源
  /// 本体 Notifier 化」的探路：先把 broadcaster provider 装配统一，本体真正
  /// Notifier 化留批 8）。
  ///
  /// 消费方 `ref.read(...)` 拿实例后仍走 addListener（未收敛的消费点）或
  /// `ref.listen(videoMutationEventsProvider, ...)`（已单轨化的消费点）。
  VideoMutationBroadcasterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoMutationBroadcasterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoMutationBroadcasterHash();

  @$internal
  @override
  $ProviderElement<VideoMutationChangeNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoMutationChangeNotifier create(Ref ref) {
    return videoMutationBroadcaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoMutationChangeNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoMutationChangeNotifier>(value),
    );
  }
}

String _$videoMutationBroadcasterHash() =>
    r'cf9a0c443ea030e8a7a4c153d9877df2d734e61b';
