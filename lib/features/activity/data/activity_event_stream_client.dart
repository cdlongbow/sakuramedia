import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';

/// 兼容别名：活动流的 Unsupported 异常上提到 core 后，保留别名让现有 catch 逻辑不改。
typedef ActivityEventStreamUnsupportedException
    = SseEventStreamUnsupportedException;

/// 活动流客户端：把 core 的通用 SSE 客户端包装成固定连 `/system/events/stream`
/// 的 `connect({afterEventId})` API，避免调用方感知路径与查询参数。
abstract class ActivityEventStreamClient {
  Stream<ApiSseEvent> connect({required int afterEventId});

  void dispose();
}

ActivityEventStreamClient createActivityEventStreamClient({
  required ApiClient apiClient,
  required SessionStore sessionStore,
}) {
  final inner = createSseEventStreamClient(
    apiClient: apiClient,
    sessionStore: sessionStore,
  );
  return _ActivityEventStreamClient(inner);
}

class _ActivityEventStreamClient implements ActivityEventStreamClient {
  _ActivityEventStreamClient(this._inner);

  final SseEventStreamClient _inner;

  @override
  Stream<ApiSseEvent> connect({required int afterEventId}) {
    return _inner.connect(
      '/system/events/stream',
      queryParameters: <String, dynamic>{'after_event_id': afterEventId},
    );
  }

  @override
  void dispose() {
    _inner.dispose();
  }
}
