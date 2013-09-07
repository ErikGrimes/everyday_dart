library everyday.rpc.invoker;

import 'dart:async';

class InvocationType {
  
  static const INVOKE = const InvocationType._(0);
  static const GET = const InvocationType._(1);
  static const SET = const InvocationType._(2);

  final int value;
  const InvocationType._(this.value);
}

abstract class Invoker {
  Future call(String target, String method, InvocationType invocationType, {List positional, Map named, Duration timeout});
}