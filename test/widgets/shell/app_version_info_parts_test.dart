import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/app/providers/external_url_provider.dart';
import 'package:sakuramedia/config/app_release_channels.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/shell/app_version_info_parts.dart';

/// 测试树的本地化 delegate：ARB 文案 + material_ui 的 Material/Cupertino 文案。
const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

void main() {
  testWidgets('更新提示同时展示前后端发布页，点击打开浏览器', (WidgetTester tester) async {
    final opened = await _pumpNotice(
      tester,
      frontendUpdateVersion: 'v0.3.0',
      backendUpdateVersion: 'v0.3.0',
    );

    expect(find.text('客户端发布页'), findsOneWidget);
    expect(find.text('服务端发布页'), findsOneWidget);

    await tester.tap(find.byKey(const Key('version-release-link-frontend')));
    await tester.pump();
    expect(opened.single, Uri.parse(AppReleaseChannels.frontendPageUrl));

    await tester.tap(find.byKey(const Key('version-release-link-backend')));
    await tester.pump();
    expect(opened.last, Uri.parse(AppReleaseChannels.backendPageUrl));
  });

  testWidgets('只有服务端更新时只显示服务端发布页', (WidgetTester tester) async {
    await _pumpNotice(tester, backendUpdateVersion: 'v0.3.0');

    expect(
      find.byKey(const Key('version-release-link-frontend')),
      findsNothing,
    );
    expect(find.text('客户端发布页'), findsNothing);
    expect(
      find.byKey(const Key('version-release-link-backend')),
      findsOneWidget,
    );
    expect(find.text('服务端发布页'), findsOneWidget);
  });

  testWidgets('只有插件更新时不显示发布页', (WidgetTester tester) async {
    await _pumpNotice(tester, pluginUpdateCount: 2);

    expect(
      find.byKey(const Key('version-release-link-frontend')),
      findsNothing,
    );
    expect(find.byKey(const Key('version-release-link-backend')), findsNothing);
    expect(find.text('2 个插件'), findsOneWidget);
  });

  testWidgets('打开浏览器失败时复制链接并提示', (WidgetTester tester) async {
    Object? clipboardArguments;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardArguments = call.arguments;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pumpNotice(
      tester,
      frontendUpdateVersion: 'v0.3.0',
      openSucceeds: false,
    );

    await tester.tap(find.byKey(const Key('version-release-link-frontend')));
    await tester.pumpAndSettle();

    expect(clipboardArguments, <String, dynamic>{
      'text': AppReleaseChannels.frontendPageUrl,
    });
    expect(find.text('无法打开浏览器，链接已复制'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<List<Uri>> _pumpNotice(
  WidgetTester tester, {
  String? frontendUpdateVersion,
  String? backendUpdateVersion,
  int pluginUpdateCount = 0,
  bool openSucceeds = true,
}) async {
  final opened = <Uri>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        externalUrlOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return openSucceeds;
        }),
      ],
      child: OKToast(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: _testLocalizationsDelegates,
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          theme: sakuraDesktopThemeData,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: AppVersionUpdateNotice(
                  frontendUpdateVersion: frontendUpdateVersion,
                  backendUpdateVersion: backendUpdateVersion,
                  pluginUpdateCount: pluginUpdateCount,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return opened;
}
