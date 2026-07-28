import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/format/relative_time_label.dart';

void main() {
  final now = DateTime.parse('2026-07-28T12:00:00');

  test('一分钟以内归「刚刚」', () {
    expect(
      formatRelativeTimeLabel(
        DateTime.parse('2026-07-28T11:59:30'),
        now: now,
      ),
      '刚刚',
    );
    expect(formatRelativeTimeLabel(now, now: now), '刚刚');
  });

  test('按分钟 / 小时 / 天分档', () {
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-28T11:15:00'), now: now),
      '45 分钟前',
    );
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-28T09:00:00'), now: now),
      '3 小时前',
    );
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-25T12:00:00'), now: now),
      '3 天前',
    );
  });

  test('suffix 拼在单位之后，「刚刚」也带上', () {
    expect(
      formatRelativeTimeLabel(
        DateTime.parse('2026-07-25T12:00:00'),
        now: now,
        suffix: '检测',
      ),
      '3 天前检测',
    );
    expect(formatRelativeTimeLabel(now, now: now, suffix: '检测'), '刚刚检测');
  });

  test('未来时间归「刚刚」而不是负数', () {
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-28T12:30:00'), now: now),
      '刚刚',
    );
  });

  test('边界：整 60 分钟进「小时」档、整 24 小时进「天」档', () {
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-28T11:00:00'), now: now),
      '1 小时前',
    );
    expect(
      formatRelativeTimeLabel(DateTime.parse('2026-07-27T12:00:00'), now: now),
      '1 天前',
    );
  });
}
