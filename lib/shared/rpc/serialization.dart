// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.rpc.serialization;

import "dart:core" hide Invocation;

import 'package:serialization/serialization.dart';

import 'messages.dart';
import 'invoker.dart';

configure(Serialization serialization){
  serialization.addRule(new InvocationRule());
  serialization.addRule(new InvocationTypeRule());
  serialization.addRule(new InvocationResultRule());
  serialization.addRule(new InvocationErrorRule());
}

class InvocationRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == Invocation;
  getState(instance) => [instance.callId, instance.endpoint,  instance.method, instance.invocationType, instance.positional, instance.named];
  create(state) => new Invocation(state[0], state[1], state[2], state[3], positional:state[4], named:state[5]);
  setState(Invocation a, List state) => {};
}

class InvocationResultRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == InvocationResult;
  getState(instance) => [instance.callId, instance.data];
  create(state) => new InvocationResult(state[0], state[1]);
  setState(InvocationResult a, List state) => {};
}

class InvocationErrorRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == InvocationError;
  getState(instance) => [instance.callId, instance.error];
  create(state) => new InvocationError(state[0], state[1]);
  setState(InvocationError a, List state) => {};
}

class InvocationTypeRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == InvocationType;
  getState(instance) => [instance.value];
  create(state)  {
    switch(state[0]){
      case 0:
        return InvocationType.INVOKE;
      case 1:
        return InvocationType.GET;
      case 2:
        return InvocationType.SET;
      default:
        throw new StateError('Unknown InvocationType [${state[0]}]');
    }
  }
  setState(InvocationType a, List state) => {};
}
