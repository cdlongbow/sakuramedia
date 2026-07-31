import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';

part 'movies_api_provider.g.dart';

/// movies 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<MoviesApi>())` 注入——与 `mediaApiProvider` /
/// `downloadsApiProvider` 同一范式。
@Riverpod(keepAlive: true)
MoviesApi moviesApi(Ref ref) {
  return MoviesApi(apiClient: ref.watch(apiClientProvider));
}
