library everyday.rpc.shared;

import 'invoker.dart';

class Message {
  final String type;
  Message(this.type);
}



class Call extends Message {
  
  static const String TYPE = 'call';
  
  final int callId;
  final String endpoint;
  final String method;
  final InvocationType invocationType;
  final List positional;
  final Map named;
 
  Call(this.callId, this.endpoint, this.method,  this.invocationType, {positional, named}): this.positional=positional, this.named=named,super(TYPE);
}

class CallResult extends Message {
  
  static const String TYPE = 'call_result';
  
  final int callId;
  final dynamic data;
 
  CallResult(this.callId, this.data): super(TYPE);
}

class CallError extends Message {
  
  static const String TYPE = 'call_error';
  
  final int callId;
  final dynamic error;
 
  CallError(this.callId, this.error):super(TYPE);
}