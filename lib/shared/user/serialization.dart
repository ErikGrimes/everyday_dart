// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.user.serialization;

import 'package:serialization/serialization.dart';
import 'user.dart';

configure(Serialization serialization){
  serialization.addRule(new EmailPasswordTokenRule());
  serialization.addRule(new UserRule());
}

class EmailPasswordTokenRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == EmailPasswordToken;
  getState(instance) => [instance.email, instance.password];
  create(state) => new EmailPasswordToken(state[0], state[1]);
  setState(EmailPasswordToken a, List state) => {};
}

class UserRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == User;
  getState(User instance) => [];
  create(state) => new User();
  setState(User instance, List state) => {};
}