import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/actors/presentation/controllers/listing/actor_filter_state.dart';

void main() {
  group('ActorSortField', () {
    test('可播放影片数映射后端排序字段', () {
      expect(ActorSortField.playableMovieCount.apiValue, 'playable_movie_count');
      expect(ActorSortField.playableMovieCount.label, '可播放影片数');
    });
  });

  group('ActorFilterState', () {
    test('初始状态不搜索、不筛可播放且为默认态', () {
      const state = ActorFilterState.initial;
      expect(state.query, isNull);
      expect(state.hasPlayableMovies, isFalse);
      expect(state.isDefault, isTrue);
    });

    test('关键词与可播放筛选影响 isDefault', () {
      expect(const ActorFilterState(query: '三上').isDefault, isFalse);
      expect(
        const ActorFilterState(hasPlayableMovies: true).isDefault,
        isFalse,
      );
    });

    test('copyWith 可显式清空关键词', () {
      const withQuery = ActorFilterState(query: '三上');
      expect(withQuery.copyWith().query, '三上');
      expect(withQuery.copyWith(query: null).query, isNull);
    });

    test('withSearchQuery 从默认「已订阅」开始搜索时放宽为全部', () {
      final next = ActorFilterState.initial.withSearchQuery('  三上  ');
      expect(next.query, '三上');
      expect(next.subscriptionStatus, ActorSubscriptionStatus.all);
    });

    test('withSearchQuery 开始搜索时保留显式选择的未订阅筛选', () {
      const state = ActorFilterState(
        subscriptionStatus: ActorSubscriptionStatus.unsubscribed,
      );
      final next = state.withSearchQuery('三上');
      expect(next.query, '三上');
      expect(next.subscriptionStatus, ActorSubscriptionStatus.unsubscribed);
    });

    test('withSearchQuery 搜索中继续输入不覆盖手动改过的筛选', () {
      const state = ActorFilterState(
        query: '三上',
        subscriptionStatus: ActorSubscriptionStatus.subscribed,
      );
      final next = state.withSearchQuery('三上悠亚');
      expect(next.query, '三上悠亚');
      expect(next.subscriptionStatus, ActorSubscriptionStatus.subscribed);
    });

    test('withSearchQuery 清空关键词只清 query，订阅筛选保持现状', () {
      const state = ActorFilterState(
        query: '三上',
        subscriptionStatus: ActorSubscriptionStatus.all,
      );
      final cleared = state.withSearchQuery('');
      expect(cleared.query, isNull);
      expect(cleared.subscriptionStatus, ActorSubscriptionStatus.all);
    });

    test('排序表达式包含可播放影片数', () {
      const state = ActorFilterState(
        sortField: ActorSortField.playableMovieCount,
      );
      expect(state.sortExpression, 'playable_movie_count:desc');
    });

    test('相等性包含关键词与可播放筛选', () {
      const base = ActorFilterState();
      expect(base == const ActorFilterState(), isTrue);
      expect(base == const ActorFilterState(query: '三上'), isFalse);
      expect(base == const ActorFilterState(hasPlayableMovies: true), isFalse);
      expect(
        base.hashCode == const ActorFilterState(hasPlayableMovies: true).hashCode,
        isFalse,
      );
    });
  });
}
