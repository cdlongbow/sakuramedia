import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakuramedia/app/appearance_store.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('默认外观为浅色 + 酒红', () {
    final container = ProviderContainer(retry: (_, _) => null);
    addTearDown(container.dispose);

    final appearance = container.read(appearanceProvider);
    expect(appearance.brightness, Brightness.light);
    expect(appearance.themeColor.id, AppThemeColor.burgundyId);
  });

  test('切换明暗模式与主题色会更新状态并写入存储', () async {
    final store = InMemoryAppearanceStore();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [appearanceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container
        .read(appearanceProvider.notifier)
        .setBrightness(Brightness.dark);
    expect(container.read(appearanceProvider).brightness, Brightness.dark);
    expect(store.read().brightness, Brightness.dark);

    await container
        .read(appearanceProvider.notifier)
        .setThemeColor(AppThemeColor.burgundy);
    expect(
      container.read(appearanceProvider).themeColor.id,
      AppThemeColor.burgundyId,
    );
  });

  test('SharedPreferences 实现落盘并回读明暗模式', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesAppearanceStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.read().brightness, Brightness.light);

    await store.save(
      const AppearanceSettings(
        brightness: Brightness.dark,
        themeColor: AppThemeColor.burgundy,
      ),
    );

    final reloaded = SharedPreferencesAppearanceStore(
      await SharedPreferences.getInstance(),
    );
    expect(reloaded.read().brightness, Brightness.dark);
    expect(reloaded.read().themeColor.id, AppThemeColor.burgundyId);
  });

  test('未知主题色 id 回退到酒红', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAppearanceStore.themeColorKey: 'not-a-color',
      SharedPreferencesAppearanceStore.brightnessKey: 'dark',
    });
    final store = SharedPreferencesAppearanceStore(
      await SharedPreferences.getInstance(),
    );

    expect(store.read().themeColor.id, AppThemeColor.burgundyId);
    expect(store.read().brightness, Brightness.dark);
  });
}
