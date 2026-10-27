import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/configuration/data/dto/download_client_dto.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/configuration/data/dto/provider_catalog_dto.dart';
import 'package:sakuramedia/features/configuration/presentation/pages/desktop/download_clients_section.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_settings_group.dart';

import '../../../../../support/logged_in_session_store.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets(
    'editing a client with an unavailable provider preserves its library and config',
    (tester) async {
      final sessionStore = await buildLoggedInSessionStore();
      addTearDown(sessionStore.dispose);
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/download-clients',
        body: const <Map<String, dynamic>>[],
      );
      bundle.adapter.enqueueJson(
        method: 'PATCH',
        path: '/download-clients/1',
        body: const <String, dynamic>{
          'id': 1,
          'name': 'Renamed downloader',
          'library_id': 7,
          'provider_config': <String, dynamic>{'endpoint': 'http://old'},
        },
      );
      const client = DownloadClientDto(
        id: 1,
        name: 'Downloader',
        libraryId: 7,
        providerConfig: <String, dynamic>{'endpoint': 'http://old'},
        createdAt: null,
        updatedAt: null,
      );
      const library = MediaLibraryDto(
        id: 7,
        name: 'Main Library',
        providerKey: 'missing-provider',
        providerConfig: <String, dynamic>{'root': '/media'},
        createdAt: null,
        updatedAt: null,
      );

      await _pumpDialog(
        tester,
        bundle: bundle,
        dialog: const DownloadClientDialog(
          libraries: <MediaLibraryDto>[library],
          providers: <MediaProviderDto>[],
          title: '编辑下载器',
          initialClient: client,
        ),
      );
      expect(find.text('Main Library'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('download-client-name-field')),
        'Renamed downloader',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final patchRequest = bundle.adapter.requests.firstWhere(
        (request) =>
            request.method == 'PATCH' &&
            request.path == '/download-clients/1',
      );
      expect(patchRequest.body, <String, dynamic>{
        'name': 'Renamed downloader',
        'library_id': 7,
      });
      expect(find.byType(DownloadClientDialog), findsNothing);
      expect(find.text('下载器已更新'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'keeps the add dialog and input when saving fails, then retries',
    (tester) async {
      final sessionStore = await buildLoggedInSessionStore();
      addTearDown(sessionStore.dispose);
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/download-clients',
        body: const <Map<String, dynamic>>[],
      );
      bundle.adapter.enqueueJson(
        method: 'POST',
        path: '/download-clients',
        statusCode: 409,
        body: const <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'download_client_invalid',
            'message': '下载器配置无效',
          },
        },
      );
      const provider = MediaProviderDto(
        providerKey: 'demo',
        displayName: 'Provider A',
        libraryConfigFields: <ProviderConfigFieldDto>[],
        downloadConfigFields: <ProviderConfigFieldDto>[],
      );
      const library = MediaLibraryDto(
        id: 7,
        name: 'Main Library',
        providerKey: 'demo',
        createdAt: null,
        updatedAt: null,
      );

      await _pumpDialog(
        tester,
        bundle: bundle,
        dialog: const DownloadClientDialog(
          libraries: <MediaLibraryDto>[library],
          providers: <MediaProviderDto>[provider],
          title: '添加下载器',
        ),
      );
      await tester.enterText(
        find.byKey(const Key('download-client-name-field')),
        'New downloader',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(bundle.adapter.hitCount('POST', '/download-clients'), 1);
      expect(find.byType(DownloadClientDialog), findsOneWidget);
      expect(find.text('New downloader'), findsOneWidget);
      expect(find.text('下载器配置无效'), findsOneWidget);

      bundle.adapter.enqueueJson(
        method: 'POST',
        path: '/download-clients',
        body: const <String, dynamic>{
          'id': 2,
          'name': 'New downloader',
          'library_id': 7,
          'provider_config': <String, dynamic>{},
        },
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(bundle.adapter.hitCount('POST', '/download-clients'), 2);
      expect(find.byType(DownloadClientDialog), findsNothing);
      expect(find.text('下载器已创建'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'keeps existing clients visible when the provider catalog request fails',
    (tester) async {
      final sessionStore = SessionStore.inMemory();
      addTearDown(sessionStore.dispose);
      await sessionStore.saveBaseUrl('https://api.example.com');
      await sessionStore.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.parse('2099-01-01T00:00:00Z'),
      );
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/download-clients',
        body: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Downloader',
            'library_id': 7,
            'provider_config': <String, dynamic>{'endpoint': 'http://old'},
          },
        ],
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media-libraries',
        body: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7,
            'name': 'Main Library',
            'provider_key': 'missing-provider',
            'provider_config': <String, dynamic>{'root': '/media'},
          },
        ],
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media-libraries/providers',
        statusCode: 500,
        body: const <String, dynamic>{'message': 'catalog unavailable'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: bundle.riverpodOverrides(),
          child: OKToast(
            child: MaterialApp(
              theme: sakuraThemeData,
              locale: const Locale('zh'),
              localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
              home: const Scaffold(body: DownloadClientsSection(active: true)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('download-client-card-1')), findsOneWidget);
      expect(find.textContaining('Provider 目录暂不可用'), findsOneWidget);
      final createButton = tester.widget<AppSettingCell>(
        find.byKey(const Key('configuration-download-client-create-button')),
      );
      expect(createButton.onTap, isNull);
    },
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required TestApiBundle bundle,
  required Widget dialog,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => dialog,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
