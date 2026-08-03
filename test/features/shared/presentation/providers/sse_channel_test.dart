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
        onLongDisconnectRecover: () => recovered++,
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

  test('abandonOnBootstrapFailure：bootstrap 失败不订阅、回 idle', () {
    fakeAsync((async) {
      final errors = <Object>[];
      final channel = FakeSseChannel<String>(
        needsBootstrapBeforeStream: true,
        abandonOnBootstrapFailure: true,
        onError: errors.add,
      );
      channel.failNextBootstrap();
      channel.start(onEvent: (_) {});
      async.flushMicrotasks();

      expect(errors.length, 1);
      expect(channel.state, SseChannelState.idle);
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
