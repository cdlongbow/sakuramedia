import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

/// 已拿到 [AppLocalizations] 时的错误提示入口。
///
/// 保留这个薄封装，登录页/设置页等原先的调用点不用改；新代码可直接用
/// `apiErrorMessage(error, fallback: ..., l10n: l10n)`。
String localizedApiErrorMessage(
  AppLocalizations l10n,
  Object error, {
  required String fallback,
}) {
  return apiErrorMessage(error, fallback: fallback, l10n: l10n);
}
