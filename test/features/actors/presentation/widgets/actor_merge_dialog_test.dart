import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_detail_dto.dart';
import 'package:sakuramedia/features/actors/presentation/widgets/actor_merge_dialog.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/pump_with_providers.dart';
import '../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('合并弹窗支持搜索、多选来源并提交合并请求', (tester) async {
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      statusCode: 200,
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          _actorJson(id: 1, name: '新名'),
          _actorJson(id: 2, name: '旧名一'),
          _actorJson(id: 3, name: '旧名二'),
        ],
        'page': 1,
        'page_size': 20,
        'total': 3,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/actors/1/merge',
      statusCode: 200,
      body: _actorJson(id: 1, name: '新名'),
    );

    ActorMergeResult? result;
    await pumpWithProviders(
      tester,
      bundle: bundle,
      theme: sakuraThemeData,
      physicalSize: const Size(900, 760),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result = await showActorMergeDialog(
                  context,
                  actor: ActorDetailDto.fromJson(
                    _actorJson(id: 1, name: '新名'),
                  ),
                  api: bundle.actorsApi,
                );
              },
              child: const Text('打开合并'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开合并'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actor-merge-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('actor-merge-search-field')),
      '旧名',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actor-merge-candidate-1')), findsNothing);
    expect(find.byKey(const Key('actor-merge-candidate-2')), findsOneWidget);
    expect(find.byKey(const Key('actor-merge-candidate-3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('actor-merge-candidate-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('actor-merge-candidate-3')));
    await tester.pump();
    expect(find.textContaining('已选 2 位'), findsOneWidget);

    await tester.tap(find.byKey(const Key('actor-merge-confirm-button')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.actor.summary.id, 1);
    expect(result!.sourceActorIds, <int>[2, 3]);
    expect(find.byKey(const Key('actor-merge-dialog')), findsNothing);

    final mergeRequest = bundle.adapter.requests
        .where((request) => request.method == 'POST')
        .single;
    expect(mergeRequest.path, '/actors/1/merge');
    expect(mergeRequest.body, <String, dynamic>{
      'source_actor_ids': <int>[2, 3],
    });
  });
}

Map<String, dynamic> _actorJson({required int id, required String name}) {
  return <String, dynamic>{
    'id': id,
    'javdb_id': 'javdb-$id',
    'name': name,
    'alias_name': '',
    'display_name': name,
    'profile_image': null,
    'is_subscribed': false,
    'gender': 1,
    'mutation_revision': 0,
  };
}
