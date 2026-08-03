import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/shared/presentation/providers/broadcast_events_factory.dart';

/// 模拟 [MovieSubscriptionChangeNotifier] 的快照式语义：`reportBatch` /
/// `reportChange` 写「最新快照」并 notify，消费方经 [consumePendingChanges]
/// 幂等读取（不消费即不销毁，多消费方并存不重复）。
class _SnapshotNotifier extends ChangeNotifier {
  List<int>? _lastBatch;
  int? _lastChange;

  void reportBatch(List<int> changes) {
    if (changes.isEmpty) {
      return;
    }
    _lastBatch = List<int>.unmodifiable(changes);
    _lastChange = changes.last;
    notifyListeners();
  }

  void reportChange(int change) {
    _lastBatch = null;
    _lastChange = change;
    notifyListeners();
  }

  void consumePendingChanges(void Function(List<int>) apply) {
    final batch = _lastBatch;
    if (batch != null) {
      apply(batch);
      return;
    }
    final change = _lastChange;
    if (change == null) {
      return;
    }
    apply(<int>[change]);
  }
}

final _broadcasterProvider = Provider<_SnapshotNotifier>((ref) {
  return _SnapshotNotifier();
});

final _eventsProvider = StreamProvider<List<int>>((ref) {
  return createBroadcastEventStream<_SnapshotNotifier, List<int>>(
    ref: ref,
    resolveNotifier: (r) => r.read(_broadcasterProvider),
    drain: (n, emit) => n.consumePendingChanges(emit),
  );
});

/// 给流式事件一个 flush 窗口（StreamController 是异步投递）。
Future<void> pumpMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late ProviderContainer container;
  late _SnapshotNotifier broadcaster;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    broadcaster = container.read(_broadcasterProvider);
  });

  test('reportChange → 快照投递到事件流', () async {
    final events = <List<int>>[];
    container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        events.add(v);
      }
    });
    await pumpMicrotasks();

    broadcaster.reportChange(1);
    await pumpMicrotasks();
    expect(events, [
      <int>[1],
    ]);
  });

  test('reportBatch → 批量快照原样投递（单条字段退化路径一致）', () async {
    final events = <List<int>>[];
    container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        events.add(v);
      }
    });
    await pumpMicrotasks();

    broadcaster.reportBatch(const <int>[1, 2, 3]);
    await pumpMicrotasks();
    expect(events, [
      <int>[1, 2, 3],
    ]);
  });

  test('同 broadcaster 双监听者并存：事件流与直挂 addListener 都收到且幂等不重复', () async {
    final viaStream = <List<int>>[];
    final viaDirect = <List<int>>[];
    container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        viaStream.add(v);
      }
    });
    // 过渡期消费方直接挂 notifier 的监听——与「events 流消费方」并存。
    broadcaster.addListener(() {
      broadcaster.consumePendingChanges(viaDirect.add);
    });
    await pumpMicrotasks();

    broadcaster.reportBatch(const <int>[1, 2]);
    broadcaster.reportChange(3);
    await pumpMicrotasks();

    // 双方都按「本次广播的快照」各自消费一遍；快照式语义下没有队列可重复消费。
    expect(viaStream, [
      <int>[1, 2],
      <int>[3],
    ]);
    expect(viaDirect, [
      <int>[1, 2],
      <int>[3],
    ]);
  });

  test('多次 reportBatch 快速触发：顺序正确、不丢', () async {
    final events = <List<int>>[];
    container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        events.add(v);
      }
    });
    await pumpMicrotasks();

    broadcaster.reportBatch(const <int>[1, 2]);
    broadcaster.reportBatch(const <int>[3]);
    broadcaster.reportBatch(const <int>[4, 5]);
    await pumpMicrotasks();

    expect(events, [
      <int>[1, 2],
      <int>[3],
      <int>[4, 5],
    ]);
  });

  test('消费方 detach → 入站流 pause；resume 时缓冲补投', () async {
    final events = <List<int>>[];
    final sub = container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        events.add(v);
      }
    });
    await pumpMicrotasks();

    broadcaster.reportBatch(const <int>[1]);
    await pumpMicrotasks();
    expect(events, [
      <int>[1],
    ]);

    // detach：无监听者 → Riverpod pause 入站流，事件被缓冲。
    sub.close();
    await pumpMicrotasks();
    broadcaster.reportBatch(const <int>[2]);
    broadcaster.reportBatch(const <int>[3]);
    await pumpMicrotasks();
    expect(events, [
      <int>[1],
    ]);

    // resume：补投缓冲中的事件（顺序保持）。
    container.listen(_eventsProvider, (_, next) {
      final v = next.value;
      if (v != null) {
        events.add(v);
      }
    });
    await pumpMicrotasks();
    expect(events, [
      <int>[1],
      <int>[2],
      <int>[3],
    ]);
  });
}
