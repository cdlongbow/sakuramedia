import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const drawerKey = Key('media-preview-auto-drawer');
  const contentKey = Key('media-preview-auto-content');

  Widget buildHost({AppPlatform? platform}) {
    final app = MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () {
                    showMediaPreviewOverlay(
                      context: context,
                      presentation: MediaPreviewPresentation.auto,
                      drawerKey: drawerKey,
                      builder:
                          (context) =>
                              const SizedBox(key: contentKey, height: 120),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
    if (platform == null) {
      return app;
    }
    return AppPlatformScope(platform: platform, child: app);
  }

  testWidgets('auto presentation opens bottom drawer on mobile scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHost(platform: AppPlatform.mobile));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(drawerKey), findsOneWidget);
    expect(find.byKey(contentKey), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('auto presentation opens dialog on desktop scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHost(platform: AppPlatform.desktop));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(drawerKey), findsNothing);
    expect(find.byKey(contentKey), findsOneWidget);
  });

  testWidgets('auto presentation falls back to dialog without scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHost());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(drawerKey), findsNothing);
    expect(find.byKey(contentKey), findsOneWidget);
  });

  testWidgets('explicit presentation is not overridden by platform scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppPlatformScope(
        platform: AppPlatform.mobile,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder:
                    (context) => TextButton(
                      onPressed: () {
                        showMediaPreviewOverlay(
                          context: context,
                          presentation: MediaPreviewPresentation.dialog,
                          drawerKey: drawerKey,
                          builder:
                              (context) =>
                                  const SizedBox(key: contentKey, height: 120),
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

    expect(find.byKey(drawerKey), findsNothing);
    expect(find.byKey(contentKey), findsOneWidget);
  });
}
