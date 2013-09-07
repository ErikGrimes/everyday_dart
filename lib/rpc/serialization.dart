library everyday.rpc.serialization;

import 'package:serialization/serialization.dart';

import 'shared.dart';
import 'invoker.dart';



configure(Serialization serialization){
  serialization.addRule(new CallRule());
  serialization.addRule(new InvocationTypeRule());
  serialization.addRule(new CallResultRule());
  serialization.addRule(new CallErrorRule());
}


class CallRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == Call;
  getState(instance) => [instance.callId, instance.endpoint,  instance.method, instance.invocationType, instance.positional, instance.named];
  create(state) => new Call(state[0], state[1], state[2], state[3], positional:state[4], named:state[5]);
  setState(Call a, List state) => {};
}

class CallResultRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == CallResult;
  getState(instance) => [instance.callId, instance.data];
  create(state) => new CallResult(state[0], state[1]);
  setState(CallResult a, List state) => {};
}

class CallErrorRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == CallError;
  getState(instance) => [instance.callId, instance.error];
  create(state) => new CallError(state[0], state[1]);
  setState(CallError a, List state) => {};
}

class InvocationTypeRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == InvocationType;
  getState(instance) => [instance.value];
  create(state)  {
    switch(state[0]){
      case 0:
        return InvocationType.INVOKE;
      break;
      case 1:
        return InvocationType.GET;
      break;
      case 2:
        return InvocationType.SET;
      break;
    }
  }
  setState(InvocationType a, List state) => {};
}
