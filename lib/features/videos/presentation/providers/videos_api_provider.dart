import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/video_imports_api.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';

part 'videos_api_provider.g.dart';

/// videos 域三个 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<...>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
VideosApi videosApi(Ref ref) {
  throw UnimplementedError('Override videosApiProvider at the app root');
}

@Riverpod(keepAlive: true)
VideoCollectionsApi videoCollectionsApi(Ref ref) {
  throw UnimplementedError(
    'Override videoCollectionsApiProvider at the app root',
  );
}

@Riverpod(keepAlive: true)
VideoImportsApi videoImportsApi(Ref ref) {
  throw UnimplementedError('Override videoImportsApiProvider at the app root');
}
