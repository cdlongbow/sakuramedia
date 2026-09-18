import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/image_search/presentation/pages/desktop/image_search_page.dart';
import 'package:sakuramedia/features/image_search/presentation/pages/mobile/image_search_page.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    bundle = await createTestApiBundle(sessionStore);
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/status/capabilities',
      body: const <String, bool>{
        'image_search': false,
        'movie_similarity': false,
      },
    );
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  imageSearchRequests() => bundle.adapter.requests.where(
    (request) => request.path.startsWith('/image-search'),
  );

  testWidgets('desktop page shows disabled notice without issuing searches', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopImageSearchPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('图片与文字搜图未启用'), findsOneWidget);
    expect(imageSearchRequests(), isEmpty);
  });

  testWidgets('mobile page shows disabled notice without issuing searches', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: const Scaffold(body: MobileImageSearchPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('图片与文字搜图未启用'), findsOneWidget);
    expect(imageSearchRequests(), isEmpty);
  });

  testWidgets('mobile page points pure-mobile users at the server admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: AppPlatformScope(
          platform: AppPlatform.mobile,
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: const Scaffold(body: MobileImageSearchPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('管理员'), findsOneWidget);
  });

  testWidgets('disabled notice can re-check capabilities', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopImageSearchPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(bundle.adapter.hitCount('GET', '/status/capabilities'), 1);

    await tester.tap(find.text('重新检测'));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('GET', '/status/capabilities'), 2);
    expect(find.text('图片与文字搜图未启用'), findsOneWidget);
  });
}
