import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';

part 'activity_stream_client_provider.g.dart';

/// 通知中心专用 SSE 流客户端（原生装配）。
@Riverpod(keepAlive: true)
ActivityEventStreamClient activityEventStreamClient(Ref ref) {
  final client = createActivityEventStreamClient(
    apiClient: ref.watch(apiClientProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
  ref.onDispose(client.dispose);
  return client;
}
