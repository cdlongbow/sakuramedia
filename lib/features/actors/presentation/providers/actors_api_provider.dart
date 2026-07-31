import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';

part 'actors_api_provider.g.dart';

/// actors 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActorsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ActorsApi actorsApi(Ref ref) {
  throw UnimplementedError('Override actorsApiProvider at the app root');
}
