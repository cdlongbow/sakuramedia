import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

import 'test_api_bundle.dart';

/// 搭测试树：`ProviderScope + MaterialApp + OKToast` 一键完成。
///
/// 收敛各测试文件里散落的手搭样板（95+ 处）。传 [bundle] 时自动拼
/// `bundle.riverpodOverrides()`，再叠加 [overrides]（后者优先）。
///
/// - [physicalSize]：指定逻辑尺寸（`devicePixelRatio` 恒 1.0），结束自动复位。
/// - [theme]：默认 Material 主题；需要设计 token 的测试传
///   `sakuraDesktopThemeData` / `sakuraMobileThemeData`。
/// - [wrapInOkToast]：默认 true（toast 文案断言依赖 OKToast 树）。
/// - [wrap]：自定义外壳（如 `Scaffold(body: ...)`、navigatorObservers）。
///
/// 语言固定为简体中文，并挂上 ARB 委托：页面文案走 `AppLocalizations`，
/// 没有委托的测试树会在 `AppLocalizations.of(context)` 处直接抛错。
///
/// 不强推替换存量测试——新测试用这个，旧测试随页面迁移顺手 refactor。
Future<void> pumpWithProviders(
  WidgetTester tester, {
  required Widget home,
  List<Override> overrides = const [],
  TestApiBundle? bundle,
  Size? physicalSize,
  ThemeData? theme,
  bool wrapInOkToast = true,
  Widget Function(Widget)? wrap,
  Locale? locale,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale>? supportedLocales,
}) async {
  var child = home;
  if (wrap != null) {
    child = wrap(child);
  }
  Widget app = ProviderScope(
    overrides: <Override>[
      if (bundle != null) ...bundle.riverpodOverrides(),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
      theme: theme,
      locale: locale ?? const Locale('zh'),
      localizationsDelegates: localizationsDelegates ??
          <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
      supportedLocales:
          supportedLocales ?? const <Locale>[Locale('zh'), Locale('en')],
    ),
  );
  if (wrapInOkToast) {
    app = OKToast(child: app);
  }

  if (physicalSize != null) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(app);
}
