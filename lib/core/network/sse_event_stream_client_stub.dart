import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';

SseEventStreamClient createPlatformSseEventStreamClient({
  required ApiClient apiClient,
  required SessionStore sessionStore,
}) {
  return _IoSseEventStreamClient(apiClient);
}

class _IoSseEventStreamClient implements SseEventStreamClient {
  _IoSseEventStreamClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Stream<ApiSseEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.getSse(path, queryParameters: queryParameters);
  }

  @override
  void dispose() {}
}
