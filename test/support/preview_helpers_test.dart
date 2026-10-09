import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

import 'logged_in_session_store.dart';
import 'preview_helpers.dart';

const String _url = 'https://api.example.com/media/covers/PREVIEW-001.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registered preview image renders synchronously in MaskedImage', (
    tester,
  ) async {
    final sessionStore = await buildLoggedInSessionStore();
    addTearDown(sessionStore.dispose);
    final image = await makePreviewImage(width: 80, height: 120);
    registerPreviewImage(_url, image);
    addTearDown(clearPreviewImages);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(sessionStore)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 120,
              child: const MaskedImage(url: _url, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 注册图片同步命中：无异常、无占位（placeholder 分支不出现）。
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('placeholder')), findsNothing);
  });
}
