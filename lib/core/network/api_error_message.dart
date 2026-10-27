import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

/// 把请求异常转成用户可读文案。
///
/// 服务端返回的 [ApiException.error] 已经按请求语言本地化；这里只兜底
/// 传输失败和非 [ApiException]。传了 [l10n] 时传输失败文案走 ARB；不传时
/// 保留旧的中文兜底，供尚未迁移的 widget 调用点渐进替换。
String apiErrorMessage(
  Object error, {
  required String fallback,
  AppLocalizations? l10n,
}) {
  if (error is ApiException) {
    if (error.isTransportFailure) {
      if (l10n != null) {
        return _localizedTransportFailureMessage(error, l10n);
      }
      return _transportFailureMessage(error);
    }
    return error.error?.message ?? error.message;
  }
  return fallback;
}

String _localizedTransportFailureMessage(
  ApiException error,
  AppLocalizations l10n,
) {
  final baseUrl = error.baseUrl?.trim();
  return switch (error.transportFailureKind) {
    ApiTransportFailureKind.timeout
        when baseUrl != null && baseUrl.isNotEmpty =>
      l10n.errorTimeoutWithHost(baseUrl),
    ApiTransportFailureKind.timeout => l10n.errorTimeout,
    _ when baseUrl != null && baseUrl.isNotEmpty =>
      l10n.errorNetworkFailureWithHost(baseUrl),
    _ => l10n.errorNetworkFailure,
  };
}

String _transportFailureMessage(ApiException error) {
  final baseUrl = error.baseUrl?.trim();
  return switch (error.transportFailureKind) {
    ApiTransportFailureKind.timeout
        when baseUrl != null && baseUrl.isNotEmpty =>
      '连接服务器超时：$baseUrl。请检查服务是否繁忙、网络是否稳定，或稍后重试。',
    ApiTransportFailureKind.timeout => '连接服务器超时。请检查服务是否繁忙、网络是否稳定，或稍后重试。',
    _ when baseUrl != null && baseUrl.isNotEmpty =>
      '无法连接到服务器：$baseUrl。请检查后端地址是否正确、服务是否已启动，或网络是否可达。',
    _ => '无法连接到服务器。请检查后端地址是否正确、服务是否已启动，或网络是否可达。',
  };
}
