import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/plugins/data/plugin_market_source.dart';
import 'package:sakuramedia/features/plugins/data/plugins_api.dart';
import 'package:sakuramedia/features/plugins/presentation/pages/desktop/plugin_market_section.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_api_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/logged_in_session_store.dart';
import '../../../../../support/test_api_bundle.dart';
import '../../../support/plugin_market_test_data.dart';
import '../../../support/plugin_test_data.dart';

void main() {
  group('DesktopPluginMarketSection', () {
    late SessionStore sessionStore;
    late TestApiBundle bundle;

    setUp(() async {
      sessionStore = await buildLoggedInSessionStore();
      bundle = await createTestApiBundle(sessionStore);
    });

    tearDown(() {
      bundle.dispose();
    });

    testWidgets('lists market plugins with badge and install button', (
      WidgetTester tester,
    ) async {
      _enqueueMarket(bundle);
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);

      expect(find.text('演示插件'), findsOneWidget);
      expect(find.text('官方'), findsOneWidget);
      expect(
        find.byKey(const Key('plugin-market-install-button-demo_plugin')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('plugin-market-list-card')), findsOneWidget);
    });

    testWidgets('marks a lower installed version as updatable', (
      WidgetTester tester,
    ) async {
      _enqueueMarket(bundle);
      _enqueueInstalled(
        bundle,
        plugins: <Map<String, dynamic>>[pluginSummaryJson(version: '1.0.0')],
      );

      await _pumpSection(tester, bundle);

      expect(
        find.byKey(const Key('plugin-market-upgrade-button-demo_plugin')),
        findsOneWidget,
      );
      expect(find.textContaining('可更新到 v1.1.0'), findsOneWidget);
    });

    testWidgets('marks the same installed version as installed', (
      WidgetTester tester,
    ) async {
      _enqueueMarket(bundle);
      _enqueueInstalled(
        bundle,
        plugins: <Map<String, dynamic>>[pluginSummaryJson(version: '1.1.0')],
      );

      await _pumpSection(tester, bundle);

      expect(find.text('已安装'), findsOneWidget);
      expect(
        find.byKey(const Key('plugin-market-install-button-demo_plugin')),
        findsNothing,
      );
    });

    testWidgets('installs a market plugin after confirmation', (
      WidgetTester tester,
    ) async {
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

      await _pumpSection(tester, bundle);
      await tester.tap(
        find.byKey(const Key('plugin-market-install-button-demo_plugin')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('plugin-market-install-confirm-dialog-demo_plugin'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('example/demo_plugin'), findsOneWidget);
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
      expect(formData.files.single.value.filename, 'demo_plugin-1.1.0.zip');
      expect(
        formData.fields.singleWhere((entry) => entry.key == 'sha256').value,
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      );
      expect(find.text('已安装'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3)); // 排掉 oktoast 计时器
    });

    testWidgets('filters the market list by keyword', (
      WidgetTester tester,
    ) async {
      _enqueueMarket(
        bundle,
        plugins: <Map<String, dynamic>>[
          pluginMarketItemJson(),
          pluginMarketItemJson(
            pluginId: 'sakuramedia_javbus_metadata',
            displayName: 'JavBus',
            version: '0.0.1',
          ),
        ],
      );
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);
      await tester.enterText(
        find.byKey(const Key('plugin-market-search-field')),
        'javbus',
      );
      await tester.pumpAndSettle();

      expect(find.text('JavBus'), findsOneWidget);
      expect(find.text('演示插件'), findsNothing);
    });

    testWidgets('shows error state and retries', (WidgetTester tester) async {
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: kPluginMarketIndexUrl,
        statusCode: 500,
        body: <String, dynamic>{'detail': 'boom'},
      );
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);

      expect(find.byKey(const Key('plugin-market-error')), findsOneWidget);

      _enqueueMarket(bundle);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      expect(find.text('演示插件'), findsOneWidget);
    });

    testWidgets('shows the actual request host when the index host is unreachable', (
      WidgetTester tester,
    ) async {
      bundle.adapter.enqueueResponder(
        method: 'GET',
        path: kPluginMarketIndexUrl,
        responder: (options, _) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Connection failed',
          );
        },
      );
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);

      expect(find.textContaining('无法连接到服务器'), findsOneWidget);
      expect(find.textContaining('raw.githubusercontent.com'), findsOneWidget);
    });

    testWidgets('copies the project homepage link', (
      WidgetTester tester,
    ) async {
      final clipboard = _installClipboardMock(tester);
      _enqueueMarket(
        bundle,
        plugins: <Map<String, dynamic>>[
          pluginMarketItemJson(homepage: 'https://example.com/demo-plugin'),
        ],
      );
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);
      await tester.tap(
        find.byKey(
          const Key('plugin-market-copy-homepage-button-demo_plugin'),
        ),
      );
      await tester.pumpAndSettle();

      expect(clipboard.arguments, <String, dynamic>{
        'text': 'https://example.com/demo-plugin',
      });
      await tester.pump(const Duration(seconds: 3)); // 排掉 oktoast 计时器
    });

    testWidgets('falls back to the repo url when homepage is missing', (
      WidgetTester tester,
    ) async {
      final clipboard = _installClipboardMock(tester);
      _enqueueMarket(
        bundle,
        plugins: <Map<String, dynamic>>[
          pluginMarketItemJson(withHomepage: false),
        ],
      );
      _enqueueInstalled(bundle, plugins: const <Map<String, dynamic>>[]);

      await _pumpSection(tester, bundle);
      await tester.tap(
        find.byKey(
          const Key('plugin-market-copy-homepage-button-demo_plugin'),
        ),
      );
      await tester.pumpAndSettle();

      expect(clipboard.arguments, <String, dynamic>{
        'text': 'https://github.com/example/demo_plugin',
      });
      await tester.pump(const Duration(seconds: 3)); // 排掉 oktoast 计时器
    });
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

Future<void> _pumpSection(WidgetTester tester, TestApiBundle bundle) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
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
          theme: sakuraThemeData,
          home: Scaffold(
            body: SingleChildScrollView(
              child: const DesktopPluginMarketSection(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(tester.view.reset);
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
