// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.rpc.messages;

import 'invoker.dart';

class Message {
  final String type;
  Message(this.type);
}


class Invocation extends Message {
  
  static const String TYPE = 'invocation';
  
  final int callId;
  final String endpoint;
  final String method;
  final InvocationType invocationType;
  final List positional;
  final Map named;
 
  Invocation(this.callId, this.endpoint, this.method,  this.invocationType, {positional, named}): this.positional=positional, this.named=named,super(TYPE);
}

class InvocationResult extends Message {
  
  static const String TYPE = 'call_result';
  
  final int callId;
  final dynamic data;
 
  InvocationResult(this.callId, this.data): super(TYPE);
}

class InvocationError extends Message {
  
  static const String TYPE = 'call_error';
  
  final int callId;
  final dynamic error;
 
  InvocationError(this.callId, this.error):super(TYPE);
}