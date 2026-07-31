import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_collection_type_change_notifier.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_subscription_change_notifier.dart';

part 'mutation_events_provider.g.dart';

/// 跨页订阅变更广播源（legacy `ChangeNotifier`）的桥。
///
/// 过渡期方案 B：Provider 侧与 Riverpod 侧共用**同一个**
/// [MovieSubscriptionChangeNotifier] 实例，保持「单一广播源」。发起方无论在哪一
/// 侧，都 `reportChange` / `reportBatch` 到它；消费方在 Riverpod 侧走
/// [movieSubscriptionEventsProvider]，**不 `context.read`**。
///
/// 原生装配：body 直接构造 + `ref.onDispose` 配对销毁，组合根不再 override。
///
/// 命名注意：函数名不要以 `Notifier` 结尾——riverpod_generator 会把它从生成的
/// provider 变量名里剥掉，导致 `xxxNotifier` 生成出 `xxxProvider`。
@Riverpod(keepAlive: true)
MovieSubscriptionChangeNotifier movieSubscriptionBroadcaster(Ref ref) {
  final notifier = MovieSubscriptionChangeNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
}

/// 订阅变更事件流：把 [MovieSubscriptionChangeNotifier] 的 `notifyListeners`
/// 翻译成一条条「本次广播的变更列表」。
///
/// 消费方 `ref.listen(movieSubscriptionEventsProvider, ...)` 后对自己的列表做
/// **就地补丁**（移除 / 改字段），语义与 Provider 侧监听方一致——不要
/// `invalidate` 触发整页重拉。
///
/// 单条 `reportChange` 与批量 `reportBatch` 在这里被统一成列表形式（复用
/// notifier 自己的 `consumePendingChanges` 分派），下游不必再区分两条路径。
@Riverpod(keepAlive: true)
Stream<List<MovieSubscriptionChange>> movieSubscriptionEvents(Ref ref) {
  final notifier = ref.watch(movieSubscriptionBroadcasterProvider);
  // 单订阅 controller 足够：只有本 provider 自己监听，下游共享的是 provider 的
  // AsyncValue 而非 stream 本身。
  final controller = StreamController<List<MovieSubscriptionChange>>();
  void onChanged() => notifier.consumePendingChanges(controller.add);
  notifier.addListener(onChanged);
  ref.onDispose(() {
    notifier.removeListener(onChanged);
    unawaited(controller.close());
  });
  return controller.stream;
}

/// 跨页合集类型（单体/合集）变更广播源的桥——与
/// [movieSubscriptionBroadcasterProvider] 同一范式：两侧共用同一实例，
/// 保持「单一广播源」。原生装配，组合根不再 override。
@Riverpod(keepAlive: true)
MovieCollectionTypeChangeNotifier collectionTypeBroadcaster(Ref ref) {
  final notifier = MovieCollectionTypeChangeNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
}

/// 合集类型变更事件流：把 `notifyListeners` 翻译成一条条 [MovieCollectionTypeChange]。
///
/// 消费方 `ref.listen(movieCollectionTypeEventsProvider, ...)` 后做就地补丁，
/// 语义与 Provider 侧监听方一致，不 invalidate 整页重拉。
@Riverpod(keepAlive: true)
Stream<MovieCollectionTypeChange> movieCollectionTypeEvents(Ref ref) {
  final notifier = ref.watch(collectionTypeBroadcasterProvider);
  final controller = StreamController<MovieCollectionTypeChange>();
  void onChanged() {
    final change = notifier.lastChange;
    if (change != null) {
      controller.add(change);
    }
  }

  notifier.addListener(onChanged);
  ref.onDispose(() {
    notifier.removeListener(onChanged);
    unawaited(controller.close());
  });
  return controller.stream;
}
