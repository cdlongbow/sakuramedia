import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/image_search/data/image_search_api.dart';

part 'image_search_api_provider.g.dart';

/// image_search 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ImageSearchApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ImageSearchApi imageSearchApi(Ref ref) {
  throw UnimplementedError('Override imageSearchApiProvider at the app root');
}
