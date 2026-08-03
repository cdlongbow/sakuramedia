import 'dart:async';
import 'dart:convert';

import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';

/// 传输层 SSE 假实现：替换 `sseEventStreamClientProvider` /
/// `activityEventStreamClientProvider`，测试直接向指定 endpoint 注入事件。
///
/// 与 `FakeSseChannel`（channel 层状态机对偶）不同，本类是**传输层**打桩：
/// 生产代码里 `apiClient.getSse` 的替代品，为迁移后的 SSE 控制器（通知中心 /
/// 活动中心 / 媒体导入 / 视频导入等）提供集成级测试路径。
///
/// 默认「静默不推事件」（不触发 SSE 消费副作用）；要打事件的测试用 [emit] /
/// [emitError] / [emitUnsupported] 等钩子手动注入。活动域的
/// [ActivityEventStreamClient] 用 [FakeActivityEventStreamClient] 包一层
/// （两者 `connect` 签名不同，Dart 不允许单类双实现）。
class FakeSseEventStreamClient implements SseEventStreamClient {
  static const String activityEndpoint = '/system/events/stream';

  final Map<String, StreamController<ApiSseEvent>> _controllers = {};

  StreamController<ApiSseEvent> _controllerFor(String endpoint) =>
      _controllers.putIfAbsent(
        endpoint,
        StreamController<ApiSseEvent>.broadcast,
      );

  @override
  Stream<ApiSseEvent> connect(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _controllerFor(endpoint).stream;
  }

  /// 向指定 endpoint 注入一条事件。
  void emit(
    String endpoint, {
    int? id,
    String event = 'message',
    String data = '',
  }) {
    _controllerFor(endpoint).add(
      ApiSseEvent(id: id, event: event, data: data),
    );
  }

  /// 注入一条 JSON 事件（data 自动 jsonEncode）。
  void emitJson(
    String endpoint, {
    int? id,
    String event = 'message',
    Map<String, dynamic>? json,
  }) {
    emit(
      endpoint,
      id: id,
      event: event,
      data: json == null ? '' : jsonEncode(json),
    );
  }

  /// 注入错误：与生产 `getSse` 出错时一样，error 沿 stream 冒泡给消费方。
  void emitError(String endpoint, Object error) {
    _controllerFor(endpoint).addError(error);
  }

  /// 触发「该 endpoint 不支持 SSE」（如 Web 端）：消费方应走 unsupported 分支。
  void emitUnsupported(String endpoint) {
    _controllerFor(endpoint).addError(
      const SseEventStreamUnsupportedException('fake unsupported'),
    );
  }

  /// 关闭全部 endpoint 的连接并清空状态（幂等）。
  void closeAll() {
    for (final controller in _controllers.values) {
      unawaited(controller.close());
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    closeAll();
  }
}

/// 活动域 SSE 客户端的 fake：把 [FakeSseEventStreamClient] 包装成固定连
/// `activityEndpoint` 的 `connect({afterEventId})` 签名（与生产
/// `_ActivityEventStreamClient` 同构）。事件注入仍走
/// `fake.emit(FakeSseEventStreamClient.activityEndpoint, ...)`。
class FakeActivityEventStreamClient implements ActivityEventStreamClient {
  FakeActivityEventStreamClient(this._inner);

  final FakeSseEventStreamClient _inner;

  @override
  Stream<ApiSseEvent> connect({required int afterEventId}) {
    return _inner.connect(FakeSseEventStreamClient.activityEndpoint);
  }

  @override
  void dispose() {
    _inner.dispose();
  }
}
