import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/video_imports_api.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';

part 'videos_api_provider.g.dart';

/// videos 域三个 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用 `overrideWithValue(...)` 注入——与
/// `moviesApiProvider` 同一范式。
@Riverpod(keepAlive: true)
VideosApi videosApi(Ref ref) {
  return VideosApi(apiClient: ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
VideoCollectionsApi videoCollectionsApi(Ref ref) {
  return VideoCollectionsApi(apiClient: ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
VideoImportsApi videoImportsApi(Ref ref) {
  return VideoImportsApi(apiClient: ref.watch(apiClientProvider));
}
