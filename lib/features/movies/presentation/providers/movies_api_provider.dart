import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';

part 'movies_api_provider.g.dart';

/// movies 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MoviesApi>())` 注入——与 `mediaApiProvider` /
/// `downloadsApiProvider` 同一范式。
@Riverpod(keepAlive: true)
MoviesApi moviesApi(Ref ref) {
  throw UnimplementedError('Override moviesApiProvider at the app root');
}
