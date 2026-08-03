import 'package:http/http.dart' as http;

/// Web 平台占位：`package:http` 在 Web 上默认走 `BrowserClient`
/// （浏览器 fetch）；`cronet_http` / `cupertino_http` 不能引入。
/// 返回 null 表示「用 http.Client() 的默认实现」。
http.Client? createNativePlatformHttpClient() => null;
