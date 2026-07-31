import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/auth/data/auth_api.dart';

part 'auth_api_provider.g.dart';

/// auth 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<AuthApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) {
  throw UnimplementedError('Override authApiProvider at the app root');
}
