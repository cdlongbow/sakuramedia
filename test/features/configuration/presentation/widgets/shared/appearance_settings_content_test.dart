import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakuramedia/app/appearance_store.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/features/configuration/presentation/widgets/shared/appearance_settings_content.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('外观设置默认选中浅色，点击深色切换偏好', (WidgetTester tester) async {
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
          home: const Scaffold(body: AppearanceSettingsContent()),
        ),
      ),
    );

    expect(find.byKey(const Key('appearance-mode-light')), findsOneWidget);
    expect(find.byKey(const Key('appearance-mode-dark')), findsOneWidget);
    expect(
      find.byKey(const Key('appearance-theme-color-burgundy')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('appearance-mode-dark')));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).brightness, Brightness.dark);
    expect(store.read().brightness, Brightness.dark);
  });
}
