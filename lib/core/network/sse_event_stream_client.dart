import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client_stub.dart'
    if (dart.library.js_interop) 'package:sakuramedia/core/network/sse_event_stream_client_web.dart';

class SseEventStreamUnsupportedException implements Exception {
  const SseEventStreamUnsupportedException([this.message]);

  final String? message;

  @override
  String toString() {
    if (message == null || message!.trim().isEmpty) {
      return 'SseEventStreamUnsupportedException';
    }
    return 'SseEventStreamUnsupportedException: $message';
  }
}

abstract class SseEventStreamClient {
  Stream<ApiSseEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  void dispose();
}

SseEventStreamClient createSseEventStreamClient({
  required ApiClient apiClient,
  required SessionStore sessionStore,
}) {
  return createPlatformSseEventStreamClient(
    apiClient: apiClient,
    sessionStore: sessionStore,
  );
}
