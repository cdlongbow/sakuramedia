import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/account/data/account_api.dart';

part 'account_api_provider.g.dart';

/// account 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<AccountApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
AccountApi accountApi(Ref ref) {
  throw UnimplementedError('Override accountApiProvider at the app root');
}
