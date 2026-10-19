import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/rating/rating_dimensions_dialog.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('列出已有维度并可新增维度', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movie-rating-dimensions',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'name': '颜值',
          'min_value': 1,
          'max_value': 5,
          'weight': 1.0,
        },
      ],
    );

    await tester.pumpWidget(wrap(const RatingDimensionsDialog()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rating-dimension-1')), findsOneWidget);

    await tester.tap(find.text('新增维度'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rating-dimension-name-field')),
      '演技',
    );

    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/movie-rating-dimensions',
      statusCode: 201,
      body: <String, dynamic>{
        'id': 2,
        'name': '演技',
        'min_value': 0,
        'max_value': 5,
        'weight': 1.0,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movie-rating-dimensions',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'name': '颜值',
          'min_value': 1,
          'max_value': 5,
          'weight': 1.0,
        },
        <String, dynamic>{
          'id': 2,
          'name': '演技',
          'min_value': 1,
          'max_value': 5,
          'weight': 1.0,
        },
      ],
    );

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final request = bundle.adapter.requests.lastWhere(
      (request) => request.method == 'POST',
    );
    expect(request.body, <String, dynamic>{'name': '演技'});
    expect(find.byKey(const Key('rating-dimension-2')), findsOneWidget);
  });
}
