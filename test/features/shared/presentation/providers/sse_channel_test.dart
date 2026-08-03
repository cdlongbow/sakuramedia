import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';

import '../../../../support/fake_sse_channel.dart';

void main() {
  test('连接成功 → live，事件逐条下发', () {
    fakeAsync((async) {
      final states = <SseChannelState>[];
      final channel = FakeSseChannel<String>(
        onStateChanged: (s) => states.add(s),
      );
      final received = <String>[];
      channel.start(onEvent: received.add);
      async.flushMicrotasks();

      expect(channel.state, SseChannelState.live);
      expect(states, [SseChannelState.connecting, SseChannelState.live]);

      channel.emit('a');
      channel.emit('b');
      async.flushMicrotasks();
      expect(received, ['a', 'b']);
    });
  });

  test('断线 → 按退避表逐档重连 → 恢复 live', () {
    fakeAsync((async) {
      final channel = FakeSseChannel<String>();
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      for (var i = 0; i < 3; i++) {
        channel.failNextConnectWithError(StateError('e$i'));
      }
      channel.emitError(StateError('drop'));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.reconnecting);

      // 第 1/2/3 次重连（1s/2s/4s 档）仍失败，第 4 次（8s 档）成功。
      async.elapse(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 4));
      expect(channel.state, SseChannelState.reconnecting);
      async.elapse(const Duration(seconds: 8));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.live);
    });
  });

  test('importBackoff 使用 [2,5,10,30]s 档位', () {
    fakeAsync((async) {
      final channel = FakeSseChannel<String>(importBackoff: true);
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      for (var i = 0; i < 3; i++) {
        channel.failNextConnectWithError(StateError('e$i'));
      }
      channel.emitError(StateError('drop'));
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 5));
      async.elapse(const Duration(seconds: 10));
      expect(channel.state, SseChannelState.reconnecting);
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.live);
    });
  });

  test('unsupported + giveUpOnUnsupported=false → polling 轮询', () {
    fakeAsync((async) {
      var ticks = 0;
      final channel = FakeSseChannel<String>(
        pollingInterval: const Duration(seconds: 30),
        onPollingTick: () => ticks++,
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.emitUnsupported();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.polling);

      async.elapse(const Duration(seconds: 30));
      async.elapse(const Duration(seconds: 30));
      expect(ticks, 2);
    });
  });

  test('unsupported + giveUpOnUnsupported=true → 停订阅不重连', () {
    fakeAsync((async) {
      final channel = FakeSseChannel<String>(giveUpOnUnsupported: true);
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.emitUnsupported();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.unsupportedAbandoned);

      async.elapse(const Duration(minutes: 5));
      expect(channel.state, SseChannelState.unsupportedAbandoned);
    });
  });

  test('connect 同步抛 unsupported 也走轮询/放弃路径', () {
    fakeAsync((async) {
      final polling = FakeSseChannel<String>(
        pollingInterval: const Duration(seconds: 30),
      );
      polling.failNextConnectWithUnsupported();
      polling.start(onEvent: (_) {});
      async.flushMicrotasks();
      expect(polling.state, SseChannelState.polling);

      final abandon = FakeSseChannel<String>(giveUpOnUnsupported: true);
      abandon.failNextConnectWithUnsupported();
      abandon.start(onEvent: (_) {});
      async.flushMicrotasks();
      expect(abandon.state, SseChannelState.unsupportedAbandoned);
    });
  });

  test('mergeMode: microtask - 同 tick 事件合批，微任务结束一次 flush', () {
    fakeAsync((async) {
      final batches = <List<String>>[];
      final channel = FakeSseChannel<String>(
        mergeMode: SseMergeMode.microtask,
      );
      channel.start(onEvent: (_) {}, onBatch: batches.add);
      async.flushMicrotasks();

      channel.emit('a');
      channel.emit('b');
      channel.emit('c');
      // 事件同 tick 到达；微任务尚未 flush。
      expect(batches, isEmpty);

      async.flushMicrotasks();
      expect(batches.length, 1);
      expect(batches.first, ['a', 'b', 'c']);

      // 下一 tick 的事件独立成批。
      channel.emit('d');
      async.flushMicrotasks();
      expect(batches.length, 2);
      expect(batches.last, ['d']);
    });
  });

  test(
    'mergeMode: microtask + minMergeInterval - 硬闸拦第二次合批、闸满补发',
    () {
      fakeAsync((async) {
        final batches = <List<String>>[];
        final channel = FakeSseChannel<String>(
          mergeMode: SseMergeMode.microtask,
          minMergeInterval: const Duration(seconds: 15),
        );
        channel.start(onEvent: (_) {}, onBatch: batches.add);
        async.flushMicrotasks();

        channel.emit('a');
        async.flushMicrotasks();
        expect(batches.length, 1);

        channel.emit('b');
        channel.emit('c');
        async.flushMicrotasks();
        // 距上次 flush 不足 15s：被硬闸拦下。
        expect(batches.length, 1);

        async.elapse(const Duration(seconds: 15));
        expect(batches.length, 2);
        expect(batches.last, ['b', 'c']);
      });
    },
  );

  test('mergeMode: microtask - shutdown 后队列里的 flush 被短路，不动 batch', () {
    fakeAsync((async) {
      final batches = <List<String>>[];
      final channel = FakeSseChannel<String>(
        mergeMode: SseMergeMode.microtask,
      );
      channel.start(onEvent: (_) {}, onBatch: batches.add);
      async.flushMicrotasks();

      channel.emit('a');
      channel.emit('b');
      // 微任务已被调度但尚未跑，此刻立即 shutdown。
      channel.shutdown();
      async.flushMicrotasks();

      // 微任务里读到 _shutdown 为 true 直接返回，无 batch 产生。
      expect(batches, isEmpty);
      expect(channel.state, SseChannelState.idle);
    });
  });

  test('mergeDebounce：窗口内多事件合批成一次 flush', () {
    fakeAsync((async) {
      final batches = <List<String>>[];
      final channel = FakeSseChannel<String>(
        mergeDebounce: const Duration(milliseconds: 800),
      );
      channel.start(onEvent: (_) {}, onBatch: batches.add);
      async.flushMicrotasks();

      channel.emit('a');
      channel.emit('b');
      channel.emit('c');
      async.flushMicrotasks();
      expect(batches, isEmpty); // 窗口内不发

      async.elapse(const Duration(milliseconds: 800));
      expect(batches.length, 1);
      expect(batches.first, ['a', 'b', 'c']);

      // 第二次窗口独立成批。
      channel.emit('d');
      async.elapse(const Duration(milliseconds: 800));
      expect(batches.length, 2);
      expect(batches.last, ['d']);
    });
  });

  test('minMergeInterval 硬闸：间隔内第二次 flush 被拦、闸满补发', () {
    fakeAsync((async) {
      final batches = <List<String>>[];
      final channel = FakeSseChannel<String>(
        mergeDebounce: const Duration(milliseconds: 800),
        minMergeInterval: const Duration(seconds: 15),
      );
      channel.start(onEvent: (_) {}, onBatch: batches.add);
      async.flushMicrotasks();

      channel.emit('a');
      async.elapse(const Duration(milliseconds: 800));
      expect(batches.length, 1);

      channel.emit('b');
      channel.emit('c');
      async.elapse(const Duration(milliseconds: 800));
      expect(batches.length, 1); // 距上次 flush 不足 15s：被拦

      async.elapse(const Duration(seconds: 15));
      expect(batches.length, 2);
      expect(batches.last, ['b', 'c']);
    });
  });

  test('longDisconnectThreshold：长断线重连前触发补拉', () {
    fakeAsync((async) {
      var recovered = 0;
      final channel = FakeSseChannel<String>(
        longDisconnectThreshold: const Duration(minutes: 2),
        onLongDisconnectRecover: () async => recovered++,
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.simulateLongDisconnect();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.reconnecting);
      expect(recovered, 0);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(recovered, 1);
      expect(channel.state, SseChannelState.live);
    });
  });

  test('onLongDisconnectRecover 时序：补拉 await 完再进 connect（live）', () {
    fakeAsync((async) {
      final events = <String>[];
      final channel = FakeSseChannel<String>(
        longDisconnectThreshold: const Duration(minutes: 2),
        onLongDisconnectRecover: () async {
          events.add('recover-start');
          // 等 200ms 模拟真实 await（api 请求）
          await Future<void>.delayed(const Duration(milliseconds: 200));
          events.add('recover-end');
        },
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.simulateLongDisconnect();
      async.flushMicrotasks();
      // 断线后进 reconnecting，等 1s 到重连档
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      // 补拉未完成前 doConnect 未跑：还没 live
      expect(events, ['recover-start']);
      expect(channel.state, SseChannelState.connecting);

      async.elapse(const Duration(milliseconds: 200));
      async.flushMicrotasks();
      // 补拉完成后才 doConnect → live
      expect(events, ['recover-start', 'recover-end']);
      expect(channel.state, SseChannelState.live);
    });
  });

  test('onLongDisconnectRecover 抛错：onError 收到，仍继续连流', () {
    fakeAsync((async) {
      final errors = <Object>[];
      final channel = FakeSseChannel<String>(
        longDisconnectThreshold: const Duration(minutes: 2),
        onLongDisconnectRecover: () async => throw StateError('recover fail'),
        onError: errors.add,
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.simulateLongDisconnect();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(errors.length, 2);
      expect(errors.first.toString(), contains('connection dropped'));
      expect(errors.last.toString(), contains('recover fail'));
      // 补拉抛错后仍继续 doConnect → live
      expect(channel.state, SseChannelState.live);
    });
  });

  test('bootstrap 成功：afterEventId 透传给 connect', () {
    fakeAsync((async) {
      final channel = FakeSseChannel<String>(
        needsBootstrapBeforeStream: true,
        bootstrap: () async => 'evt-42',
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      expect(channel.state, SseChannelState.live);
      expect(channel.lastAfterEventId, 'evt-42');
    });
  });

  test('abandonOnBootstrapFailure：bootstrap 失败走 backoff 自动重试', () {
    fakeAsync((async) {
      final errors = <Object>[];
      final channel = FakeSseChannel<String>(
        needsBootstrapBeforeStream: true,
        abandonOnBootstrapFailure: true,
        bootstrap: () async => 'evt-9',
        onError: errors.add,
      );
      channel.failNextBootstrap();
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      // 首轮 bootstrap 失败：不订阅、进 reconnecting（走 backoff 表首档）
      expect(errors.length, 1);
      expect(channel.state, SseChannelState.reconnecting);
      expect(channel.lastAfterEventId, isNull);

      // 1s 后重试整个 bootstrap+connect 循环：bootstrap 成功 → live
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.live);
      expect(channel.lastAfterEventId, 'evt-9');
    });
  });

  test('needsBootstrapBeforeStream：bootstrap 只跑首轮，重连不重复跑', () {
    fakeAsync((async) {
      var bootstrapCalls = 0;
      final channel = FakeSseChannel<String>(
        needsBootstrapBeforeStream: true,
        bootstrap: () async {
          bootstrapCalls++;
          return 'evt-${bootstrapCalls * 10}';
        },
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();
      expect(bootstrapCalls, 1);
      expect(channel.lastAfterEventId, 'evt-10');
      expect(channel.state, SseChannelState.live);

      // 触发一次断线重连
      channel.emitError(StateError('drop'));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.reconnecting);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      // 重连 live：bootstrap 未再跑；afterEventId 为 null（消费方在
      // connect 闭包里读自己维护的 _lastEventId 拼，本 fake 无 _lastEventId
      // 维护，所以传 null）
      expect(bootstrapCalls, 1);
      expect(channel.state, SseChannelState.live);
      expect(channel.lastAfterEventId, isNull);
    });
  });

  test('onDone（服务端断流）→ reconnecting → 重连', () {
    fakeAsync((async) {
      final channel = FakeSseChannel<String>();
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      channel.closeStream();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.reconnecting);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.live);
    });
  });

  test('shutdown 幂等：清订阅与全部 timer', () {
    fakeAsync((async) {
      final states = <SseChannelState>[];
      final channel = FakeSseChannel<String>(
        onStateChanged: (s) => states.add(s),
      );
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      // 制造一个 pending 的重连 timer。
      channel.emitError(StateError('drop'));
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.reconnecting);

      channel.shutdown();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.idle);
      expect(states.last, SseChannelState.idle);

      // 再次 shutdown 幂等不抛。
      channel.shutdown();
      async.flushMicrotasks();
      expect(channel.state, SseChannelState.idle);

      // 无残留 timer：长时间推移不应有任何状态变化/重连。
      final before = states.length;
      async.elapse(const Duration(minutes: 10));
      expect(states.length, before);
      expect(channel.state, SseChannelState.idle);
    });
  });
}
