// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.rpc.invoker;

import 'dart:async';

class InvocationType {
  
  static const INVOKE = const InvocationType._(0);
  static const GET = const InvocationType._(1);
  static const SET = const InvocationType._(2);

  final int value;
  const InvocationType._(this.value);
}

abstract class Invoker {
  Future invoke(String target, String method, InvocationType invocationType, {List positional, Map named, Duration timeout});
}