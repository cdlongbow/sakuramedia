import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakuramedia/app/appearance_store.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/features/configuration/presentation/widgets/shared/appearance_settings_content.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('外观设置默认跟随系统 + 绛红，点击模式与主题色切换偏好', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryAppearanceStore();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [appearanceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: sakuraThemeData,
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          home: const Scaffold(
            body: SingleChildScrollView(child: AppearanceSettingsContent()),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('settings-language-zh-CN')), findsOneWidget);
    expect(find.byKey(const Key('settings-language-en')), findsOneWidget);

    expect(container.read(appearanceProvider).themeMode, ThemeMode.system);
    expect(
      container.read(appearanceProvider).themeColor.id,
      AppThemeColor.crimsonId,
    );
    expect(find.byKey(const Key('appearance-mode-system')), findsOneWidget);
    expect(find.byKey(const Key('appearance-mode-light')), findsOneWidget);
    expect(find.byKey(const Key('appearance-mode-dark')), findsOneWidget);
    expect(
      find.byKey(const Key('appearance-theme-color-burgundy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appearance-theme-color-crimson')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appearance-theme-color-klein-blue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appearance-theme-color-silhouette')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('appearance-mode-dark')));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).themeMode, ThemeMode.dark);
    expect(store.read().themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const Key('appearance-mode-system')));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).themeMode, ThemeMode.system);
    expect(store.read().themeMode, ThemeMode.system);

    await tester.tap(
      find.byKey(const Key('appearance-theme-color-klein-blue')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(appearanceProvider).themeColor.id,
      AppThemeColor.kleinBlueId,
    );
    expect(store.read().themeColor.id, AppThemeColor.kleinBlueId);
  });
}
