import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/language/app_language.dart';
import 'package:sakuramedia/app/language/language_store.dart';
import 'package:sakuramedia/app/language/providers/language_providers.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/account/data/account_api.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/widgets/shared/language_settings_content.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/fake_http_client_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late ApiClient apiClient;
  late FakeHttpClientAdapter adapter;
  late InMemoryLanguageStore languageStore;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
    languageStore = InMemoryLanguageStore();
  });

  tearDown(() {
    apiClient.dispose();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        appLanguageStoreProvider.overrideWithValue(languageStore),
        sessionStoreProvider.overrideWithValue(sessionStore),
        accountApiProvider.overrideWithValue(AccountApi(apiClient: apiClient)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final language = ref.watch(appLanguageControllerProvider);
            return OKToast(
              child: MaterialApp(
                theme: sakuraThemeData,
                locale: language.locale,
                localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
                home: const Scaffold(
                  body: SingleChildScrollView(child: LanguageSettingsContent()),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('switching language patches the server and updates the UI', (
    WidgetTester tester,
  ) async {
    adapter.enqueueJson(
      method: 'PATCH',
      path: '/account',
      body: <String, dynamic>{
        'username': 'account',
        'language': 'en',
        'created_at': '2026-03-08T09:00:00Z',
        'last_login_at': '2026-03-08T10:00:00Z',
      },
    );
    final container = await pump(tester);

    expect(find.text('界面语言'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-language-en')));
    await tester.pumpAndSettle();

    expect(container.read(appLanguageControllerProvider), AppLanguage.en);
    expect(languageStore.read(), AppLanguage.en);
    expect(find.text('Interface language'), findsOneWidget);
    expect(adapter.requests.single.body, <String, dynamic>{'language': 'en'});
  });

  testWidgets('failed patch keeps the previous language', (
    WidgetTester tester,
  ) async {
    adapter.enqueueJson(
      method: 'PATCH',
      path: '/account',
      statusCode: 422,
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'invalid_language',
          'message': 'Unsupported language: en',
        },
      },
    );
    final container = await pump(tester);

    await tester.tap(find.byKey(const Key('settings-language-en')));
    await tester.pumpAndSettle();

    expect(container.read(appLanguageControllerProvider), AppLanguage.zhCN);
    expect(languageStore.read(), isNull);
    expect(find.text('界面语言'), findsOneWidget);
    // 等待失败 toast 的自动消失定时器结束，避免测试结束时报 pending timer。
    await tester.pump(const Duration(seconds: 5));
  });
}
