import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/session/credential_store.dart';

part 'credential_store_provider.g.dart';

/// 全局 [CredentialStore] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<CredentialStore>())` 注入。
@Riverpod(keepAlive: true)
CredentialStore credentialStore(Ref ref) {
  return CredentialStore();
}
