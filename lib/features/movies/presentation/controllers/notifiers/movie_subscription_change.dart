import 'package:flutter/foundation.dart';

/// 一次跨页订阅变更事件的载荷。
@immutable
class MovieSubscriptionChange {
  const MovieSubscriptionChange({
    required this.movieNumber,
    required this.isSubscribed,
  });

  final String movieNumber;
  final bool isSubscribed;
}
