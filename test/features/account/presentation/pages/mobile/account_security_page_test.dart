import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/account/presentation/pages/mobile/account_security_page.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/routes/app_router.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

late SessionStore _sessionStore;
late TestApiBundle _bundle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _sessionStore = await _buildLoggedInSessionStore();
    _bundle = await createTestApiBundle(_sessionStore);
  });

  tearDown(() {
    _bundle.dispose();
  });

  testWidgets('renders account, password and api key cards', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);

    expect(
      find.byKey(const Key('mobile-settings-account-security')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-account-card')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-account-username-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-account-password-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-account-password-current-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-account-password-new-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-account-password-confirm-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-account-apikeys-card')),
      findsOneWidget,
    );
    expect(find.text('还没有 API 密钥。'), findsOneWidget);
  });

  testWidgets('saves username and updates summary', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);
    await tester.enterText(
      find.byKey(const Key('mobile-account-username-field')),
      'renamed-account',
    );
    _bundle.adapter.enqueueJson(
      method: 'PATCH',
      path: '/account',
      body: <String, dynamic>{
        'username': 'renamed-account',
        'created_at': '2026-03-08T09:00:00Z',
        'last_login_at': '2026-03-08T10:00:00Z',
      },
    );

    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-username-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-username-submit-button')),
    );
    await tester.pumpAndSettle();

    final patch = _bundle.adapter.requests.firstWhere(
      (request) => request.method == 'PATCH' && request.path == '/account',
    );
    expect(patch.body, <String, dynamic>{'username': 'renamed-account'});
    expect(find.text('renamed-account'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows username conflict inline', (WidgetTester tester) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);
    await tester.enterText(
      find.byKey(const Key('mobile-account-username-field')),
      'duplicate',
    );
    _bundle.adapter.enqueueJson(
      method: 'PATCH',
      path: '/account',
      statusCode: 409,
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'username_conflict',
          'message': 'Username exists',
        },
      },
    );

    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-username-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-username-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-account-username-error-text')),
      findsOneWidget,
    );
    // 内联错误与 toast 文案一致，可能出现两个。
    expect(find.text('用户名已存在，请换一个名称'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('validates required password fields on first submit', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);

    expect(find.text('请输入当前密码'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('请输入当前密码'), findsOneWidget);
    expect(find.text('请输入新密码'), findsOneWidget);
    expect(find.text('请再次输入新密码'), findsOneWidget);
    expect(_bundle.adapter.hitCount('POST', '/account/password'), 0);
  });

  testWidgets('rejects same new password and mismatched confirmation', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-current-field')),
      'same-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-new-field')),
      'same-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-confirm-field')),
      'other-password',
    );
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('新密码不能与当前密码相同'), findsOneWidget);
    expect(find.text('两次输入的新密码不一致'), findsOneWidget);
    expect(_bundle.adapter.hitCount('POST', '/account/password'), 0);
  });

  testWidgets('successful password change clears session and returns login', (
    WidgetTester tester,
  ) async {
    final router = buildMobileRouter(sessionStore: _sessionStore);
    addTearDown(router.dispose);
    router.go(mobileSettingsAccountSecurityPath);

    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/account/password',
      statusCode: 204,
    );
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/auth/tokens',
      body: <String, dynamic>{
        'access_token': 'verified-access-token',
        'refresh_token': 'verified-refresh-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'expires_at': '2026-03-10T13:00:00Z',
        'refresh_expires_at': '2026-03-17T13:00:00Z',
        'user': <String, dynamic>{'username': 'account'},
      },
    );

    await _pumpRouterApp(tester, router: router);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('mobile-account-password-current-field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-new-field')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-confirm-field')),
      'new-password',
    );
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      _bundle.adapter.requests
          .where(
            (request) =>
                request.path == '/account/password' ||
                request.path == '/auth/tokens',
          )
          .map((request) => '${request.method} ${request.path}')
          .toList(),
      <String>['POST /account/password', 'POST /auth/tokens'],
    );
    expect(
      _bundle.adapter.requests
          .firstWhere((request) => request.path == '/account/password')
          .body,
      <String, dynamic>{
        'current_password': 'old-password',
        'new_password': 'new-password',
      },
    );
    expect(_sessionStore.hasSession, isFalse);
    expect(router.routeInformationProvider.value.uri.path, loginPath);
    expect(find.byKey(const Key('login-form-base-url')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'shows backend error and keeps session when password change fails',
    (WidgetTester tester) async {
      _enqueueAccount(_bundle);
      _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

      await _pumpStandalonePage(tester);
      _bundle.adapter.enqueueJson(
        method: 'POST',
        path: '/account/password',
        statusCode: 401,
        body: <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'invalid_credentials',
            'message': 'Current password is incorrect',
            'details': null,
          },
        },
      );

      await tester.enterText(
        find.byKey(const Key('mobile-account-password-current-field')),
        'wrong-password',
      );
      await tester.enterText(
        find.byKey(const Key('mobile-account-password-new-field')),
        'new-password',
      );
      await tester.enterText(
        find.byKey(const Key('mobile-account-password-confirm-field')),
        'new-password',
      );
      await tester.ensureVisible(
        find.byKey(const Key('mobile-account-password-submit-button')),
      );
      await tester.tap(
        find.byKey(const Key('mobile-account-password-submit-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(_bundle.adapter.hitCount('POST', '/auth/tokens'), 0);
      expect(_sessionStore.hasSession, isTrue);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('keeps session when verification with new password fails', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/account/password',
      statusCode: 204,
    );
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/auth/tokens',
      statusCode: 401,
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'invalid_credentials',
          'message': 'Invalid username or password',
          'details': null,
        },
      },
    );

    await tester.enterText(
      find.byKey(const Key('mobile-account-password-current-field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-new-field')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-confirm-field')),
      'new-password',
    );
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('密码已修改，但新密码登录校验失败，请重新登录确认'), findsOneWidget);
    expect(_sessionStore.hasSession, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('submit stays single-flight while request is in progress', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);
    final completer = Completer<ResponseBody>();

    await _pumpStandalonePage(tester);
    _bundle.adapter.enqueueResponder(
      method: 'POST',
      path: '/account/password',
      responder: (request, body) => completer.future,
    );
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/auth/tokens',
      body: <String, dynamic>{
        'access_token': 'verified-access-token',
        'refresh_token': 'verified-refresh-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'expires_at': '2026-03-10T13:00:00Z',
        'refresh_expires_at': '2026-03-17T13:00:00Z',
        'user': <String, dynamic>{'username': 'account'},
      },
    );

    await tester.enterText(
      find.byKey(const Key('mobile-account-password-current-field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-new-field')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('mobile-account-password-confirm-field')),
      'new-password',
    );

    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('mobile-account-password-submit-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_bundle.adapter.hitCount('POST', '/account/password'), 1);

    completer.complete(
      ResponseBody.fromBytes(const <int>[], 204, headers: const {}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('lists existing api keys', (WidgetTester tester) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, <Map<String, Object?>>[
      <String, Object?>{
        'id': 3,
        'name': 'MCP server',
        'key_hint': 'sk-AbCd1234',
        'created_at': '2026-10-06T10:00:00',
        'last_used_at': '2026-10-07T11:20:00',
      },
      <String, Object?>{
        'id': 2,
        'name': '',
        'key_hint': 'sk-ZzZz9999',
        'created_at': '2026-10-06T10:00:00',
        'last_used_at': null,
      },
    ]);

    await _pumpStandalonePage(tester);

    expect(find.text('MCP server'), findsOneWidget);
    expect(find.textContaining('sk-AbCd1234'), findsOneWidget);
    expect(find.text('未命名密钥'), findsOneWidget);
    expect(find.textContaining('从未使用'), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-account-apikey-delete-3')),
      findsOneWidget,
    );
  });

  testWidgets('generates api key via drawer with one-time secret', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, const <Map<String, Object?>>[]);

    await _pumpStandalonePage(tester);
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-apikeys-create-button')),
    );
    await tester.tap(
      find.byKey(const Key('mobile-account-apikeys-create-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('生成 API 密钥'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('mobile-api-key-name-field')),
      'MCP',
    );
    _bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/account/api-keys',
      statusCode: 201,
      body: <String, dynamic>{
        'id': 5,
        'name': 'MCP',
        'key_hint': 'sk-OneTimeKe',
        'created_at': '2026-10-07T12:00:00',
        'last_used_at': null,
        'key': 'sk-OneTimeKe_SecretValue_AbCdEfGh1234567890xyz',
      },
    );
    await tester.tap(find.byKey(const Key('mobile-api-key-generate-submit')));
    await tester.pumpAndSettle();

    expect(find.text('密钥已生成'), findsOneWidget);
    expect(
      find.text('sk-OneTimeKe_SecretValue_AbCdEfGh1234567890xyz'),
      findsOneWidget,
    );
    expect(find.textContaining('仅显示一次'), findsOneWidget);
    expect(
      _bundle.adapter.requests
          .firstWhere(
            (request) =>
                request.method == 'POST' && request.path == '/account/api-keys',
          )
          .body,
      <String, dynamic>{'name': 'MCP'},
    );

    await tester.tap(find.byKey(const Key('mobile-api-key-done-button')));
    await tester.pumpAndSettle();

    expect(find.text('MCP'), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-account-apikey-delete-5')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('deletes api key after confirmation', (
    WidgetTester tester,
  ) async {
    _enqueueAccount(_bundle);
    _enqueueApiKeys(_bundle, <Map<String, Object?>>[
      <String, Object?>{
        'id': 7,
        'name': 'MCP server',
        'key_hint': 'sk-Del12345',
        'created_at': '2026-10-06T10:00:00',
        'last_used_at': null,
      },
    ]);

    await _pumpStandalonePage(tester);
    await tester.ensureVisible(
      find.byKey(const Key('mobile-account-apikey-delete-7')),
    );
    await tester.tap(find.byKey(const Key('mobile-account-apikey-delete-7')));
    await tester.pumpAndSettle();

    expect(find.text('删除 API 密钥'), findsOneWidget);

    _bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/account/api-keys/7',
      statusCode: 204,
    );
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(_bundle.adapter.hitCount('DELETE', '/account/api-keys/7'), 1);
    expect(find.text('MCP server'), findsNothing);
    expect(
      find.byKey(const Key('mobile-account-apikey-delete-7')),
      findsNothing,
    );
  });
}

Future<void> _pumpStandalonePage(WidgetTester tester) async {
  _useTallViewport(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(body: MobileAccountSecurityPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRouterApp(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  _useTallViewport(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
      ),
    ),
  );
}

/// 账号安全页三张卡纵向排列，默认 800×600 视口放不下第三张（懒构建不可查）。
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _enqueueAccount(TestApiBundle bundle, {String username = 'account'}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/account',
    body: <String, dynamic>{
      'username': username,
      'created_at': '2026-03-08T09:00:00Z',
      'last_login_at': '2026-03-08T10:00:00Z',
    },
  );
}

void _enqueueApiKeys(TestApiBundle bundle, List<Map<String, Object?>> items) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/account/api-keys',
    body: items,
  );
}

Future<SessionStore> _buildLoggedInSessionStore() async {
  final store = SessionStore.inMemory();
  await store.saveBaseUrl('https://api.example.com');
  await store.saveTokens(
    accessToken: 'mobile-access-token',
    refreshToken: 'mobile-refresh-token',
    expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
  );
  return store;
}
