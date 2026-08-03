import 'dart:async';

import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';

/// [SseChannel] 的测试对偶：直接控制传输层状态机。
///
/// 用法：`channel.start(onEvent: ...)` 后，用 [emit] / [emitError] /
/// [emitUnsupported] / [emitBootstrapFailure] / [simulateLongDisconnect]
/// 驱动连接、断线重连、退避、轮询、补拉等路径，无需真实 SSE 客户端。
///
/// 构造参数与 [SseChannel] 一一对应（退避表、轮询间隔、合批、bootstrap
/// 前置、长断线阈值等），`connect` 由本 fake 接管。
class FakeSseChannel<E> extends SseChannel<E> {
  FakeSseChannel({
    super.backoff,
    super.importBackoff,
    super.pollingInterval,
    super.giveUpOnUnsupported,
    super.mergeDebounce,
    super.minMergeInterval,
    super.longDisconnectThreshold,
    super.needsBootstrapBeforeStream,
    super.abandonOnBootstrapFailure,
    Future<String?> Function()? bootstrap,
    super.onError,
    super.onStateChanged,
    super.onPollingTick,
    super.onLongDisconnectRecover,
  }) : super() {
    final userBootstrap = bootstrap;
    this.bootstrap = () async {
      if (_bootstrapShouldFail) {
        _bootstrapShouldFail = false;
        throw StateError('bootstrap failed');
      }
      return userBootstrap?.call();
    };
  }

  StreamController<E> _controller = StreamController<E>.broadcast();
  bool _bootstrapShouldFail = false;
  bool _unsupportedOnNextConnect = false;
  final List<Object> _connectErrors = <Object>[];

  /// 最近一次 doConnect 收到的 afterEventId（验证 bootstrap 传参）。
  String? lastAfterEventId;

  /// 生产路径的 connect 行为：返回本 fake 的广播流。
  @override
  Stream<E> doConnect({String? afterEventId}) {
    lastAfterEventId = afterEventId;
    if (_connectErrors.isNotEmpty) {
      throw _connectErrors.removeAt(0);
    }
    if (_unsupportedOnNextConnect) {
      _unsupportedOnNextConnect = false;
      throw const SseEventStreamUnsupportedException();
    }
    if (_controller.isClosed) {
      // 上一轮流被 closeStream 关闭（模拟服务端断流）：重连时开新流。
      _controller = StreamController<E>.broadcast();
    }
    return _controller.stream;
  }

  /// 让下一次（及之后第 N 次）connect 同步抛 [error]（模拟 `connect` 闭包内抛）。
  void failNextConnectWithError(Object error) => _connectErrors.add(error);

  /// 关闭广播流，触发当前订阅的 onDone（模拟服务端断流）。
  void closeStream() => _controller.close();

  /// 推送一条事件，走通道的正常事件管线（合批/立即 sink 由参数决定）。
  void emit(E event) => _controller.add(event);

  /// 推送一个流错误（触发重连路径）。
  void emitError(Object error) => _controller.addError(error);

  /// 推送 unsupported（触发轮询回退或放弃订阅，依 `giveUpOnUnsupported`）。
  void emitUnsupported() => _controller.addError(
    const SseEventStreamUnsupportedException(),
  );

  /// 让下一次 connect 同步抛 unsupported（模拟 `connect` 闭包内抛）。
  void failNextConnectWithUnsupported() => _unsupportedOnNextConnect = true;

  /// 让下一次 bootstrap 抛错（配合 `needsBootstrapBeforeStream` 验证
  /// `abandonOnBootstrapFailure` 语义）。
  void failNextBootstrap() => _bootstrapShouldFail = true;

  /// 模拟一次长断线：触发一次连接错误 → 断线计时开始 → 把断线起点回拨到
  /// `longDisconnectThreshold` 之前，让下一次重连触发 [onLongDisconnectRecover]。
  ///
  /// 回拨排在微任务里执行（错误先送达、`_disconnectStartedAt` 先落位）。
  void simulateLongDisconnect() {
    emitError(StateError('connection dropped'));
    scheduleMicrotask(() {
      debugBackdateDisconnectStart(
        by: (longDisconnectThreshold ?? const Duration(minutes: 2)) +
            const Duration(seconds: 1),
      );
    });
  }

  /// 测试内销毁广播流。
  void dispose() => _controller.close();
}
