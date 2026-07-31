import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/clip_collections/data/api/clip_collections_api.dart';

part 'clip_collections_api_provider.g.dart';

/// clip_collections 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ClipCollectionsApi clipCollectionsApi(Ref ref) {
  throw UnimplementedError(
    'Override clipCollectionsApiProvider at the app root',
  );
}
