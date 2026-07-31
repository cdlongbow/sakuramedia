import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/configuration/data/api/config_api.dart';

part 'config_api_provider.g.dart';

/// configuration 域 ConfigApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ConfigApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ConfigApi configApi(Ref ref) {
  throw UnimplementedError('Override configApiProvider at the app root');
}
