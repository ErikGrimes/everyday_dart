library everyday.rpc.server;

import 'dart:async';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'invoker.dart';
import 'shared.dart';

class MessageHandler extends Stream<Message> implements StreamSink<Message> {
  static final Logger _LOGGER = new Logger('everyday.rpc.server.message_handler');
  final StreamController _outbound = new StreamController();
  final CallRouter _router;

  MessageHandler(this._router);
  
  _handleCall(Call call){
    _router.route(call).then((_){
      _outbound.add(_);
    }).catchError((e){
      _outbound.add(e);
    }, test: (e) => e is CallError);
  }
  

  void add(event) {
    if(event is Call){
      _handleCall(event);
    }
  }

  void addError(errorEvent) {
    //TODO Implement this method
    throw new UnimplementedError();
  }

  Future addStream(Stream<Message> stream) {
    //TODO Think about this more carefully, examine sdk websocket_impl.dart
    var completer = new Completer();
    var subscription = stream.listen(
        (data) {
          add(data);
        },
        onDone: () {
          completer.complete();
        },
        onError: (error) {
          completer.completeError(error);
        },
        cancelOnError: true);
    return completer.future;
  }

  Future close() {
    return _outbound.close();
  }

  Future get done => _outbound.done;

  StreamSubscription listen(void onData(event), {void onError(error), void onDone(), bool cancelOnError}) {
    return _outbound.stream.listen(onData, onDone: onDone, onError:onError, cancelOnError:cancelOnError);
  }
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
     throw new CallError(call.callId, 'No such endpoint ${call.endpoint}');
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