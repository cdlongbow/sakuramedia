import 'dart:async';
import 'package:clock/clock.dart';

import 'package:flutter/foundation.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';

/// SSE 重连退避档位：[1,2,4,8,16,30]s——download / notification / activity。
const List<Duration> kActivityBackoff = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 16),
  Duration(seconds: 30),
];

/// import 双子星（media_import / video_import）的退避档位：[2,5,10,30]s。
const List<Duration> kImportBackoff = <Duration>[
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 30),
];

enum SseChannelState {
  idle,
  connecting,
  live,
  reconnecting,
  polling,
  unsupportedAbandoned,
}

/// 事件合批模式。
///
/// - [none]：事件立即逐条 sink（import 双子星现状——每条事件立即刷新）。
/// - [microtask]：`scheduleMicrotask` 合批——同 event loop tick 内多条事件
///   合并成一次 flush，tick 结尾就出手。download / notification / activity
///   三家现状。**语义等价于**「同一帧内的多条事件合并成一次状态更新」，60fps
///   顺滑，用户视觉无卡顿。
/// - [timerDebounce]：`Timer(mergeDebounce)` 合批——第一条事件起计时，窗口内
///   后续事件合入同一批，窗口到期一次 flush。语义等价于「debounce」，
///   `mergeDebounce=800ms` 会让 UI 800ms 才动一次。**注意**：这**不是**
///   download 现状——download 的 800ms 只用来去抖「拉第一页」的网络请求，
///   事件本身仍走 [microtask] 合批。此模式是给"事件流量极大、UI 不追求
///   实时性、可以牺牲响应换稳定"的场景保留的。
enum SseMergeMode { none, microtask, timerDebounce }

/// SSE 连接状态机封装，收敛 download / notification / activity / media_import /
/// video_import 五家的重复管理代码。差异全部走构造参数：
///
/// | 参数 | download | notification/activity | import 双子星 |
/// |---|---|---|---|
/// | 退避表 | 默认 [kActivityBackoff] | 默认 | `importBackoff: true`（[kImportBackoff]） |
/// | unsupported 后 | 30s 轮询 | 30s 轮询 | 放弃订阅不重连 |
/// | bootstrap 前置 | 无 | 需要（拿 afterEventId，只跑首次） | 需要（只跑首次；失败不订阅但走 backoff 自动重试） |
/// | 合批 | microtask + 拉页 15s 硬闸 | microtask | none（逐条 sink） |
/// | 长断线补拉 | 2min（消费方 [onLongDisconnectRecover] 里 await 拉页） | 2min（同左） | 无 |
///
/// 生命周期：`start(onEvent:)` → [SseChannelState.live]；断线按退避表
/// [SseChannelState.reconnecting] 重连；unsupported 依 [giveUpOnUnsupported]
/// 走轮询或放弃；`shutdown()` 幂等清场。
///
/// [connect] 闭包负责拼 afterEventId（消费方自持 `_lastEventId`，闭包内读）；
/// [needsBootstrapBeforeStream] 时**首轮**连流前先跑 [bootstrap] 拿起始事件
/// id——非首轮（普通重连）复用 [connect] 闭包里的 `_lastEventId`；长断线
/// 补拉时机由 [onLongDisconnectRecover] 承担（消费方在 callback 里显式跑
/// bootstrap，见其 dartdoc）。
class SseChannel<E> {
  SseChannel({
    Stream<E> Function({String? afterEventId})? connect,
    this.backoff = kActivityBackoff,
    this.importBackoff = false,
    this.pollingInterval,
    this.giveUpOnUnsupported = false,
    this.mergeDebounce,
    SseMergeMode? mergeMode,
    this.minMergeInterval,
    this.longDisconnectThreshold,
    this.needsBootstrapBeforeStream = false,
    this.abandonOnBootstrapFailure = false,
    this.bootstrap,
    this.onError,
    this.onStateChanged,
    this.onPollingTick,
    this.onLongDisconnectRecover,
  })  : _connect = connect,
        _explicitMergeMode = mergeMode;

  final Stream<E> Function({String? afterEventId})? _connect;

  /// 默认退避档位（[importBackoff] 为 true 时改用 [kImportBackoff]）。
  final List<Duration> backoff;

  /// true → 使用 [kImportBackoff]（import 双子星）。
  final bool importBackoff;

  /// 非 null = unsupported 后进入 [SseChannelState.polling] 轮询的间隔。
  final Duration? pollingInterval;

  /// true = unsupported 后放弃订阅（[SseChannelState.unsupportedAbandoned]，
  /// 不再重连/轮询）——import 双子星；false = polling fallback。
  final bool giveUpOnUnsupported;

  /// [SseMergeMode.timerDebounce] 模式下的窗口时长。非该模式时忽略。
  final Duration? mergeDebounce;

  /// 显式指定的合批模式；null 时按 [mergeDebounce] 兼容旧写法推断
  /// （非空 → [SseMergeMode.timerDebounce]；空 → [SseMergeMode.none]）。
  final SseMergeMode? _explicitMergeMode;

  /// 生效的合批模式。
  SseMergeMode get mergeMode {
    if (_explicitMergeMode != null) {
      return _explicitMergeMode;
    }
    return mergeDebounce != null
        ? SseMergeMode.timerDebounce
        : SseMergeMode.none;
  }

  /// 硬闸：距上次实际 flush 不足此间隔时，本次合批被拦下、顺延到闸满再发
  /// （download 15s，防死循环打爆第一页接口）。
  final Duration? minMergeInterval;

  /// 长断线阈值：断线超过此时间，重连前先调 [onLongDisconnectRecover] 补拉。
  final Duration? longDisconnectThreshold;

  /// true = **首轮**连流前先跑 [bootstrap] 拿 afterEventId（import +
  /// notification / activity）；普通重连不重复跑，由 [connect] 闭包内读
  /// 消费方自持的 `_lastEventId` 拼参；长断线补拉走 [onLongDisconnectRecover]。
  final bool needsBootstrapBeforeStream;

  /// true = bootstrap 失败**本次不订阅**（防 after_event_id=0 全量回放），
  /// 但走 backoff 自动重试整个 bootstrap+connect 循环（对齐 import 双子星的
  /// `catch { _scheduleReconnect(); }` 语义，消费方不必自行安排重试）；
  /// false = 失败也照常连（afterEventId 为 null，会触发全量回放，谨慎）。
  final bool abandonOnBootstrapFailure;

  /// 返回起始 afterEventId；失败抛异常（依 [abandonOnBootstrapFailure] 处置）。
  Future<String?> Function()? bootstrap;

  /// 流错误 / bootstrap 失败回调。
  final void Function(Object error)? onError;

  /// 状态迁移回调（idle/connecting/live/reconnecting/polling/…）。
  final void Function(SseChannelState)? onStateChanged;

  /// 轮询 tick 回调（消费方拉第一页）。
  final void Function()? onPollingTick;

  /// 长断线补拉回调（消费方重新拉第一页）。
  ///
  /// 返回 `Future` 让重连流程可以 `await` 补拉完成再进 [connect]——避免"补
  /// 拉与连流并发跑"导致的 UI 闪一下旧数据（消费方内部一般是
  /// `await api.getBootstrap()` + `await loadInitialPage()` 等异步动作）。
  final Future<void> Function()? onLongDisconnectRecover;

  StreamSubscription<E>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  Timer? _mergeDebounceTimer;
  Timer? _mergeGateTimer;
  bool _microtaskFlushScheduled = false;
  void Function(E)? _onEvent;
  void Function(List<E>)? _onBatch;
  int _reconnectAttempt = 0;
  DateTime? _disconnectStartedAt;
  DateTime? _lastFlushAt;
  final List<E> _pending = <E>[];
  bool _shutdown = false;
  bool _bootstrapCompleted = false;
  SseChannelState _state = SseChannelState.idle;

  SseChannelState get state => _state;

  List<Duration> get _effectiveBackoff => importBackoff ? kImportBackoff : backoff;

  /// 建立连接并持续消费事件。幂等：已在连接中则直接返回。
  ///
  /// [onEvent] 在 [mergeDebounce] 为 null 时被逐条调用；非 null 时事件先入
  /// pending 队列，微任务合批后经 [flushPending] 一次性交给 [onBatch]
  /// （未提供时退化为逐条调 [onEvent]）。
  Future<void> start({
    required void Function(E) onEvent,
    void Function(List<E>)? onBatch,
  }) async {
    if (_subscription != null || _state != SseChannelState.idle) {
      return;
    }
    _onEvent = onEvent;
    _onBatch = onBatch ?? (events) {
      for (final event in events) {
        onEvent(event);
      }
    };
    _shutdown = false;
    await _connectLoop();
  }

  /// 停止并清场：幂等。取消订阅与全部 timer、清空 pending。
  Future<void> shutdown() async {
    _shutdown = true;
    _cancelReconnectTimer();
    _cancelPollingTimer();
    _cancelMergeDebounceTimer();
    _cancelMergeGateTimer();
    // 已经在队列里的 microtask 已被安排、无法撤销；靠 `_shutdown` 守卫短路。
    _microtaskFlushScheduled = false;
    _pending.clear();
    _disconnectStartedAt = null;
    _reconnectAttempt = 0;
    _bootstrapCompleted = false;
    final sub = _subscription;
    _subscription = null;
    unawaited(sub?.cancel());
    _setState(SseChannelState.idle);
  }

  /// 合批下发点：微任务 flush 与外部手动 flush 都走这里。当
  /// [minMergeInterval] 非空且距上次实际下发不足该间隔时，本次合批被拦下，
  /// 顺延到闸满再补发（防死循环）。
  void flushPending(void Function(List<E>) apply) {
    if (_pending.isEmpty) {
      return;
    }
    final gate = minMergeInterval;
    if (gate != null && _lastFlushAt != null) {
      final remaining =
          gate - clock.now().difference(_lastFlushAt!);
      if (remaining > Duration.zero) {
        _cancelMergeGateTimer();
        _mergeGateTimer = Timer(remaining, () => flushPending(apply));
        return;
      }
    }
    final events = List<E>.from(_pending);
    _pending.clear();
    _lastFlushAt = clock.now();
    apply(events);
  }

  @protected
  Stream<E> doConnect({String? afterEventId}) {
    final connect = _connect;
    if (connect == null) {
      throw UnimplementedError('SseChannel.connect 未提供');
    }
    return connect(afterEventId: afterEventId);
  }

  /// 测试钩子：把断线起始时刻回拨，用于验证长断线补拉逻辑。
  @visibleForTesting
  void debugBackdateDisconnectStart({required Duration by}) {
    final t = _disconnectStartedAt;
    if (t != null) {
      _disconnectStartedAt = t.subtract(by);
    }
  }

  Future<void> _connectLoop() async {
    if (_shutdown) {
      return;
    }
    _cancelReconnectTimer();
    _cancelPollingTimer();
    _setState(SseChannelState.connecting);

    // 长断线补拉：断线超过阈值，重连前先让消费方补拉第一页——await 完再连流,
    // 避免"补拉与连流并发"造成 UI 闪一下旧数据。
    if (longDisconnectThreshold != null &&
        _disconnectStartedAt != null &&
        clock.now().difference(_disconnectStartedAt!) >
            longDisconnectThreshold!) {
      final recover = onLongDisconnectRecover;
      if (recover != null) {
        try {
          await recover();
        } catch (error) {
          onError?.call(error);
        }
        if (_shutdown) {
          return;
        }
      }
    }

    String? afterEventId;
    // bootstrap 只在首轮跑：常规重连由消费方在 [connect] 闭包里读自己维护的
    // `_lastEventId` 拼 afterEventId，不再走 bootstrap；长断线补拉由
    // [onLongDisconnectRecover] 承担（消费方在 callback 里显式跑 bootstrap，
    // 见其 dartdoc）。
    if (needsBootstrapBeforeStream &&
        !_bootstrapCompleted &&
        bootstrap != null) {
      try {
        afterEventId = await bootstrap!();
        _bootstrapCompleted = true;
      } catch (error) {
        onError?.call(error);
        if (abandonOnBootstrapFailure) {
          // 拿不到起始事件 id 就不订阅（防 after_event_id=0 全量回放），
          // 但走 backoff 自动重试整个 bootstrap+connect 循环——对齐
          // media_import / video_import 的 `catch { _scheduleReconnect(); }`
          // 语义（消费方不必自行安排重试）。
          _scheduleReconnect();
          return;
        }
      }
    }
    if (_shutdown) {
      return;
    }

    try {
      final stream = doConnect(afterEventId: afterEventId);
      _subscription = stream.listen(
        _handleStreamEvent,
        onError: _handleStreamError,
        onDone: _handleStreamDone,
        cancelOnError: false,
      );
      _reconnectAttempt = 0;
      _disconnectStartedAt = null;
      _setState(SseChannelState.live);
    } on SseEventStreamUnsupportedException {
      _handleUnsupported();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleStreamEvent(E event) {
    if (_shutdown) {
      return;
    }
    switch (mergeMode) {
      case SseMergeMode.none:
        _onEvent?.call(event);
        return;
      case SseMergeMode.microtask:
        _pending.add(event);
        if (_microtaskFlushScheduled) {
          return;
        }
        _microtaskFlushScheduled = true;
        scheduleMicrotask(() {
          _microtaskFlushScheduled = false;
          if (_shutdown) {
            return;
          }
          final batch = _onBatch;
          if (batch != null) {
            flushPending(batch);
          }
        });
        return;
      case SseMergeMode.timerDebounce:
        _pending.add(event);
        // 合批窗口：从第一条事件起计时，窗口内到达的事件合并成一次 flush。
        _mergeDebounceTimer ??= Timer(mergeDebounce!, () {
          _mergeDebounceTimer = null;
          if (_shutdown) {
            return;
          }
          final batch = _onBatch;
          if (batch != null) {
            flushPending(batch);
          }
        });
        return;
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (_shutdown) {
      return;
    }
    if (error is SseEventStreamUnsupportedException) {
      _handleUnsupported();
      return;
    }
    onError?.call(error);
    _scheduleReconnect();
  }

  void _handleStreamDone() {
    if (_shutdown) {
      return;
    }
    if (_state == SseChannelState.polling) {
      return;
    }
    _scheduleReconnect();
  }

  void _handleUnsupported() {
    if (giveUpOnUnsupported) {
      _cancelReconnectTimer();
      _cancelPollingTimer();
      _pending.clear();
      _setState(SseChannelState.unsupportedAbandoned);
      return;
    }
    _startPollingFallback();
  }

  void _startPollingFallback() {
    final interval = pollingInterval;
    if (interval == null) {
      _scheduleReconnect();
      return;
    }
    _cancelReconnectTimer();
    _pending.clear();
    _setState(SseChannelState.polling);
    _cancelPollingTimer();
    _pollingTimer = Timer.periodic(interval, (_) {
      if (_shutdown) {
        return;
      }
      onPollingTick?.call();
    });
  }

  void _scheduleReconnect() {
    if (_shutdown || _state == SseChannelState.polling) {
      return;
    }
    _disconnectStartedAt ??= clock.now();
    _setState(SseChannelState.reconnecting);

    final delays = _effectiveBackoff;
    final delay = delays[_reconnectAttempt.clamp(0, delays.length - 1)];
    _reconnectAttempt += 1;
    _cancelReconnectTimer();
    _reconnectTimer = Timer(delay, () {
      if (_shutdown) {
        return;
      }
      final sub = _subscription;
      _subscription = null;
      unawaited(sub?.cancel());
      _connectLoop();
    });
  }

  void _setState(SseChannelState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    onStateChanged?.call(next);
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cancelPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _cancelMergeDebounceTimer() {
    _mergeDebounceTimer?.cancel();
    _mergeDebounceTimer = null;
  }

  void _cancelMergeGateTimer() {
    _mergeGateTimer?.cancel();
    _mergeGateTimer = null;
  }
}
