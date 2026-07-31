import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/widgets/system_diagnostics_strip.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/test_api_bundle.dart';

late TestApiBundle _bundle;

Future<SessionStore> _buildLoggedInSessionStore() async {
  final store = SessionStore.inMemory();
  await store.saveBaseUrl('https://api.example.com');
  await store.saveTokens(
    accessToken: 't',
    refreshToken: 'r',
    expiresAt: DateTime.parse('2099-01-01T00:00:00Z'),
  );
  return store;
}

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => Scaffold(body: child)),
    ],
  );
  return ProviderScope(
    overrides: _bundle.riverpodOverrides(),
    child: MaterialApp.router(routerConfig: router, theme: sakuraThemeData),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = await _buildLoggedInSessionStore();
    _bundle = await createTestApiBundle(store);
  });

  tearDown(() {
    _bundle.dispose();
  });

  testWidgets('未检测态渲染「开始检测」按钮 + Key 稳定', (tester) async {
    await tester.pumpWidget(_wrap(const SystemDiagnosticsStrip()));

    expect(find.byKey(const Key('system-diagnostics-strip')), findsOneWidget);
    expect(
      find.byKey(const Key('system-diagnostics-strip-start')),
      findsOneWidget,
    );
    expect(find.text('组件诊断'), findsOneWidget);
    expect(find.text('开始检测'), findsOneWidget);
  });
}
