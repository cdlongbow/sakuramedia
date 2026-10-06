import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/plugins/data/plugin_market_source.dart';
import 'package:sakuramedia/features/plugins/data/plugins_api.dart';
import 'package:sakuramedia/features/plugins/presentation/pages/mobile/mobile_plugin_market_page.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_api_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';
import '../../../support/plugin_market_test_data.dart';
import '../../../support/plugin_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'mobile-access-token',
      refreshToken: 'mobile-refresh-token',
      expiresAt: DateTime.parse('2026-09-02T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  testWidgets('lists market plugins on mobile', (tester) async {
    _enqueueMarket(bundle);
    _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

    await _pumpPage(tester, bundle);

    expect(find.byKey(const Key('mobile-plugin-market')), findsOneWidget);
    expect(find.byKey(const Key('mobile-plugin-market-notice')), findsOneWidget);
    expect(find.text('演示插件'), findsOneWidget);
    expect(find.text('官方'), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-plugin-market-install-button-demo_plugin')),
      findsOneWidget,
    );
  });

  testWidgets('marks a lower installed version as updatable', (tester) async {
    _enqueueMarket(bundle);
    _enqueueInstalled(
      bundle,
      plugins: <Map<String, dynamic>>[pluginSummaryJson(version: '1.0.0')],
    );

    await _pumpPage(tester, bundle);

    expect(find.textContaining('可更新到 v1.1.0'), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-plugin-market-upgrade-button-demo_plugin')),
      findsOneWidget,
    );
  });

  testWidgets('installs a market plugin from the card', (tester) async {
    _enqueueMarket(bundle);
    _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);
    bundle.adapter.enqueueBytes(
      method: 'GET',
      path:
          'https://github.com/example/demo_plugin/releases/download/'
          'v1.1.0/demo_plugin-1.1.0.zip',
      body: Uint8List.fromList(<int>[80, 75, 3, 4]),
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/system/plugins',
      statusCode: 201,
      body: <String, dynamic>{
        'plugin_id': 'demo_plugin',
        'version': '1.1.0',
        'pending_restart': <String>['api', 'aps'],
      },
    );
    _enqueueInstalled(
      bundle,
      plugins: <Map<String, dynamic>>[pluginSummaryJson(version: '1.1.0')],
    );

    await _pumpPage(tester, bundle);
    final installButton = find.byKey(
      const Key('mobile-plugin-market-install-button-demo_plugin'),
    );
    await tester.ensureVisible(installButton);
    await tester.tap(installButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('plugin-market-install-confirm-dialog-demo_plugin'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('plugin-market-install-confirm-button-demo_plugin'),
      ),
    );
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('POST', '/system/plugins'), 1);
    final request = bundle.adapter.requests.singleWhere(
      (item) => item.method == 'POST',
    );
    final formData = request.body as FormData;
    expect(
      formData.fields.singleWhere((entry) => entry.key == 'sha256').value,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
    expect(find.text('已安装'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // 排掉 oktoast 计时器
  });

  testWidgets('shows error state and retries', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: kPluginMarketIndexUrl,
      statusCode: 500,
      body: <String, dynamic>{'detail': 'boom'},
    );
    _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

    await _pumpPage(tester, bundle);

    expect(
      find.byKey(const Key('mobile-plugin-market-error-state')),
      findsOneWidget,
    );

    _enqueueMarket(bundle);
    await tester.tap(
      find.byKey(const Key('mobile-plugin-market-retry-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('演示插件'), findsOneWidget);
  });

  testWidgets('copies the project homepage link from the market card', (
    tester,
  ) async {
    final clipboard = _installClipboardMock(tester);
    _enqueueMarket(
      bundle,
      plugins: <Map<String, dynamic>>[
        pluginMarketItemJson(homepage: 'https://example.com/demo-plugin'),
      ],
    );
    _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

    await _pumpPage(tester, bundle);
    final copyButton = find.byKey(
      const Key('mobile-plugin-market-copy-homepage-button-demo_plugin'),
    );
    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(clipboard.arguments, <String, dynamic>{
      'text': 'https://example.com/demo-plugin',
    });
    await tester.pump(const Duration(seconds: 3)); // 排掉 oktoast 计时器
  });
}

void _enqueueMarket(
  TestApiBundle bundle, {
  List<Map<String, dynamic>>? plugins,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: kPluginMarketIndexUrl,
    body: pluginMarketIndexJson(plugins: plugins),
  );
}

void _enqueueInstalled(
  TestApiBundle bundle, {
  required List<Map<String, dynamic>> plugins,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/plugins',
    body: plugins,
  );
}

Future<void> _pumpPage(WidgetTester tester, TestApiBundle bundle) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...bundle.riverpodOverrides(),
        pluginsApiProvider.overrideWithValue(
          PluginsApi(apiClient: bundle.apiClient),
        ),
      ],
      child: OKToast(
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: const AppPlatformScope(
            platform: AppPlatform.mobile,
            child: Scaffold(body: MobilePluginMarketPage()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ClipboardRecorder {
  Object? arguments;
}

_ClipboardRecorder _installClipboardMock(WidgetTester tester) {
  final recorder = _ClipboardRecorder();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        recorder.arguments = call.arguments;
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
  return recorder;
}
