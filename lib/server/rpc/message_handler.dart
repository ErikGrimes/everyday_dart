// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.server.rpc.message_handler;

import 'dart:async';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import '../../server/io/message_handler.dart';
import '../../shared/rpc/invoker.dart';
import '../../shared/rpc/messages.dart';

class RpcMessageHandler extends Stream implements MessageHandler<Message> {
  static final Logger _LOGGER = new Logger('everyday.rpc.server.message_handler');
  final StreamController _outbound = new StreamController();
  final CallRouter _router;
  bool _bound = false;
  bool _isDisposed = false;

  RpcMessageHandler(this._router);
  
  _handleCall(Call call){
    _LOGGER.finest('Calling {callId: ${call.callId}, target: ${call.endpoint}, method: ${call.method}');
    var watch = new Stopwatch();
    watch.start();
    _router.route(call).then((_){  
      _outbound.add(_);
    }).catchError((e){
      _outbound.add(e);
    }, test: (e) => e is CallError)
    .catchError((error){
      _LOGGER.warning('Unexpected error: $error', error);
    }).whenComplete((){
      watch.stop();
      _LOGGER.finest('Completed {callId: ${call.callId}, target: ${call.endpoint}, method: ${call.method}, elapsedMillis: ${watch.elapsedMilliseconds}');
    });
  }
  

  void add(event) {
    if(event is Call){
      _handleCall(event);
    }
  }

  void addError(errorEvent, [st]) {
    //TODO Implement this method
    throw new UnimplementedError();
  }

  Future addStream(Stream<Message> stream) {
    _bound = true;
    //TODO Think about this more carefully, examine sdk websocket_impl.dart
    var completer = new Completer();
    var subscription = stream.listen(
        (data) {
          add(data);
        },
        onDone: () {
          _bound = false;
          if(!completer.isCompleted){
            completer.complete();
          }
        },
        onError: (error) {
          completer.completeError(error);
        },
        cancelOnError: true);
    return completer.future;
  }

  Future close() {
    if(!_bound){
      _isDisposed = true;
      _outbound.close();
    }
    return _outbound.done;
  }

  Future get done => _outbound.done;

  StreamSubscription listen(void onData(event), {void onError(error), void onDone(), bool cancelOnError}) {
    return _outbound.stream.listen(onData, onDone: onDone, onError:onError, cancelOnError:cancelOnError);
  }
  
  Future get disposed => done;
  
  dispose(){
    close();
  }
  
  bool get isDisposed => _isDisposed;
}


class CallRouter {
  Map<String, _Invoker> _endpoints = new Map();
  
  registerEndpoint(String name, Object o){
    _endpoints[name]= new _Invoker(o);
  }
  
  //async vs sync methods
  Future<dynamic> route(Call call){
   var endpoint = _endpoints[call.endpoint];
   if(endpoint != null){
     return endpoint.apply(call);
   }else {
     return new Future.value(new CallError(call.callId, 'No such endpoint ${call.endpoint}'));
   }
  }
  
}

class _Invoker {
  
  final Object target;
  
  _Invoker(this.target);
  
  Future apply(Call call){
    switch(call.invocationType){
      case InvocationType.INVOKE:
      return _invoke(call);
      break;
    default:    
     throw new UnimplementedError();  
    }
  }
  
  //TODO serialized errors?
  //TODO implement named arguments when dart does
  //TODO handle synchronous exceptions
  _invoke(Call call){
    var im = reflect(target);
    var completer = new Completer();
    var rim = im.invoke(new Symbol(call.method), call.positional);
    if(rim.reflectee is Future){
      rim.reflectee.then((v){
        completer.complete(new CallResult(call.callId, v));
      }).catchError((e){
        completer.completeError(new CallError(call.callId, e.toString()));
      });
    }else {
      completer.complete(rim.reflectee);
    }
    return completer.future;
  }
  
}