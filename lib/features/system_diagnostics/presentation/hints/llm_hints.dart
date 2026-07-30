import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/features/system_diagnostics/data/diagnostic_fix_target.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/hints/diagnostic_hints.dart';

/// LLM 翻译探测的 hint 表。
///
/// 后端 `POST /movie-desc-translation-settings/test` **只在成功时**返回 `{ok: true}`；
/// 失败时抛 `ApiError(status, error_code, message)`，也就是走 HTTP 错误响应，
/// `error.code` 就是下面 [LlmErrorCode] 的取值（见 `MovieDescTranslationClient`）。
/// 所以错误细分不需要等后端改造——把 [ApiException] 的 `error.code` 读出来即可。
///
/// `disabled` / `not-configured` 是前端在发请求前的本地判定，没有对应后端错误码。

/// 「LLM 配置」在配置页分类列表里的索引（`desktop_configuration_page.dart`）。
const DiagnosticFixTarget _llmTarget = DiagnosticFixTarget.configurationTab(5);

/// 后端 `MovieDescTranslationClientError.error_code` 的全部取值。
abstract final class LlmErrorCode {
  /// 请求超时 / 网络不可达（后端 httpx `TimeoutException` / `NetworkError`）。
  static const String unavailable = 'movie_desc_translation_unavailable';

  /// 上游返回 4xx/5xx，或非超时类 HTTP 失败；后端保留了真实状态码。
  static const String failed = 'movie_desc_translation_failed';

  /// 上游返回了非法 JSON / 缺 choices / 缺 message 结构。
  static const String invalidResponse =
      'movie_desc_translation_invalid_response';

  /// 上游正常响应但译文为空。
  static const String emptyResult = 'movie_desc_translation_empty_result';
}

const Map<String, DiagnosticHint> llmHints = <String, DiagnosticHint>{
  'disabled': DiagnosticHint(
    cause: 'LLM 翻译没有启用，这次跳过检测。',
    fixHint: '想要中文的影片信息，就在「LLM 配置」页打开开关并填好地址、密钥、模型。',
    fixTarget: _llmTarget,
  ),
  'not-configured': DiagnosticHint(
    cause: '开关开着，但地址、密钥、模型没填全。',
    fixHint: '在「LLM 配置」页把三项补齐，或者先关掉开关。',
    fixTarget: _llmTarget,
  ),
  LlmErrorCode.unavailable: DiagnosticHint(
    cause: '连不上 LLM 服务，请求超时了。',
    fixHint: '确认后端能访问这个地址。地址没问题就是响应太慢，可以在「LLM 配置」页调大超时。',
    fixTarget: _llmTarget,
  ),
  LlmErrorCode.failed: DiagnosticHint(
    cause: 'LLM 服务拒绝了这次请求。',
    fixHint: '在「LLM 配置」页核对密钥和模型名。注意地址末尾不要带 /v1，系统会自己补上。',
    fixTarget: _llmTarget,
  ),
  LlmErrorCode.invalidResponse: DiagnosticHint(
    cause: 'LLM 服务返回的内容看不懂。',
    fixHint: '确认地址填的是接口地址，不是网页地址。',
    fixTarget: _llmTarget,
  ),
  LlmErrorCode.emptyResult: DiagnosticHint(
    cause: '服务能连上，但这次没返回译文。',
    fixHint: '换一个内容审查更宽松的模型再试，wiki「常见问题」里有推荐的模型。',
    fixTarget: _llmTarget,
  ),
  'unknown': DiagnosticHint(
    cause: '测试请求失败了。',
    fixHint: '在「LLM 配置」页核对地址、密钥和模型名。',
    fixTarget: _llmTarget,
  ),
};

/// 从探测抛出的异常里取 hint key。
///
/// 只认 [ApiException] 携带的后端 `error.code`；传输层失败（连不上后端本身）
/// 与其它异常都落 `unknown`，因为那时压根没跑到 LLM 上游。
String resolveLlmHintKey(Object error) {
  if (error is! ApiException || error.isTransportFailure) {
    return 'unknown';
  }
  final code = error.error?.code ?? '';
  return llmHints.containsKey(code) ? code : 'unknown';
}
