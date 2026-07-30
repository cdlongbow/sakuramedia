import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/features/system_diagnostics/data/diagnostic_fix_target.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/hints/diagnostic_hints.dart';

/// JavDB / DMM **必须分开两套 hint**，因为两者的代理语义完全不同：
///
/// - `build_javdb_provider()` 写死 `proxy=None`（"JavDB 请求永远不走 metadata proxy"），
///   JavDB 只依赖「高级设置 · JavDB 域名」自身的可达性。
/// - `build_dmm_provider()` 才吃 `settings.metadata.proxy`，DMM 是**唯一**走代理的源。
/// - 两边的 httpx client 都是 `trust_env=False`，`HTTP_PROXY` 环境变量一律无效。
///
/// key 与后端 [MetadataProviderErrorType] 的三个取值一一对应，外加一个前端侧的
/// `probe-request-failed`（调 `/status/metadata-providers/{p}/test` 本身就失败了）。

/// 「高级设置」在配置页分类列表里的索引（`desktop_configuration_page.dart`）。
const DiagnosticFixTarget _advancedSettingsTarget =
    DiagnosticFixTarget.configurationTab(7);

const DiagnosticHint _probeRequestFailedHint = DiagnosticHint(
  cause: '检测请求没完成，后端没有响应。',
  fixHint: '确认后端正常后重新检测。',
);

/// JavDB 侧**一律不给 fixTarget**：能改的只有「高级设置 · JavDB API 域名」，而 wiki
/// `config.md` 明确写着这个字段不建议随便改。真正的修法在路由器/透明代理那一侧
/// （见 wiki「常见问题 · 代理配置」），SakuraMedia 里没有对应开关，指过去等于误导。
const Map<String, DiagnosticHint> javdbHints = <String, DiagnosticHint>{
  MetadataProviderErrorType.notFound: DiagnosticHint(
    cause: 'JavDB 打得开，但搜不到测试用的番号。',
    fixHint: '先重新检测一次。还是失败就是 JavDB 改版了，需要等适配。',
  ),
  MetadataProviderErrorType.requestError: DiagnosticHint(
    cause: '连不上 JavDB。',
    fixHint:
        'JavDB 不走代理，填代理没用。如果路由器开了透明代理，要让 JavDB 的域名直连，'
        '详见 wiki「常见问题 · 代理配置」。',
  ),
  MetadataProviderErrorType.unexpected: DiagnosticHint(
    cause: 'JavDB 抓取时出错了。',
    fixHint: '点「查看诊断详情」看具体报错。',
  ),
  'probe-request-failed': _probeRequestFailedHint,
};

const Map<String, DiagnosticHint> dmmHints = <String, DiagnosticHint>{
  MetadataProviderErrorType.notFound: DiagnosticHint(
    cause: 'DMM 打得开，但这部片子没找到简介。',
    fixHint: '先重新检测一次。还是失败就是 DMM 改版了，需要等适配，改配置没用。',
  ),
  MetadataProviderErrorType.requestError: DiagnosticHint(
    cause: '连不上 DMM。',
    fixHint: 'DMM 只让日本 IP 访问，在「高级设置」填一个日本代理。',
    fixTarget: _advancedSettingsTarget,
  ),
  MetadataProviderErrorType.unexpected: DiagnosticHint(
    cause: 'DMM 抓取时出错了。',
    fixHint: '点「查看诊断详情」看具体报错。',
    fixTarget: _advancedSettingsTarget,
  ),
  'probe-request-failed': _probeRequestFailedHint,
};

/// 元数据源标识，与后端 `/status/metadata-providers/{provider}/test` 的路径参数一致。
const String javdbProviderKey = 'javdb';
const String dmmProviderKey = 'dmm';

/// 取 [provider] 对应的 hint 表。未知 provider 一律按 JavDB 处理（当前后端只支持两种）。
Map<String, DiagnosticHint> metadataProviderHints(String provider) {
  return provider == dmmProviderKey ? dmmHints : javdbHints;
}

/// 按后端 `error.type` 分派 hint key。
///
/// [error] 为 null（healthy=false 但没带 error，理论上不会出现）或 type 不认识时，
/// 归到 `unexpected_error`。
String resolveMetadataProviderHintKey(
  StatusMetadataProviderTestErrorDto? error,
) {
  return switch (error?.type) {
    MetadataProviderErrorType.notFound => MetadataProviderErrorType.notFound,
    MetadataProviderErrorType.requestError =>
      MetadataProviderErrorType.requestError,
    _ => MetadataProviderErrorType.unexpected,
  };
}
