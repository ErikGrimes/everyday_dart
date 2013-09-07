library everyday.aai.serialization;

import 'package:serialization/serialization.dart';
import 'shared.dart';

configure(Serialization serialization){
  serialization.addRule(new EmailPasswordTokenRule());
}

class EmailPasswordTokenRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == EmailPasswordToken;
  getState(instance) => [instance.email, instance.password];
  create(state) => new EmailPasswordToken(state[0], state[1]);
  setState(EmailPasswordToken a, List state) => {};
}