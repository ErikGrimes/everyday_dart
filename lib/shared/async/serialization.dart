// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.async.serialization;

import 'package:serialization/serialization.dart';

import 'package:everyday_dart/shared/async/future.dart';

configure(Serialization serialization){
  serialization.addRule(new TimedOutExceptionRule());
}

class TimedOutExceptionRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == TimedOutException;
  getState(instance) => [];
  create(state) => new TimedOutException();
  setState(TimedOutException a, List state) => {};
}

