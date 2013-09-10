// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.rpc.everyday_rpc;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:polymer/polymer.dart';
import 'shared.dart';
import '../rpc/invoker.dart';
import '../io/everyday_socket.dart';
import '../async/stream.dart';

@CustomTag('everyday-rpc')
class EverydayRpc extends PolymerElement with ObservableMixin implements Invoker  {
  
  static final Symbol CODEC = const Symbol('codec');
  static final Symbol DEFAULT_TIMEOUT = const Symbol('defaultTimeout');
  static final Symbol SOCKET = const Symbol('socket');
  
  StreamController _outbound;
  
  StreamSubscription _selfSub;
  
  Map _completers = new Map();
  
  Random _random = new Random(new DateTime.now().millisecondsSinceEpoch);
  
  List _socketSubs = [];
  
  Duration _defaultTimeout = new Duration(milliseconds: 1000);
  
  @observable
  int defaultTimeout = 1000;
  
  @observable
  Codec codec;
  
  @observable
  EverydaySocket socket;
  
  inserted(){
   
    _configure();
    
    _selfSub = this.changes.listen(_propertyChanged);
    
  }
  
  removed(){
    _unconfigure();
    _selfSub.cancel();
  }
  
  Future call(String endpoint, String method, InvocationType invocationType, {List positional, Map named, Duration timeout}){
    if(timeout == null){
      timeout = _defaultTimeout;
    }
    return _call(endpoint, method, invocationType, positional:positional, named:named, timeout: timeout);
  }
  
  _propertyChanged(List<ChangeRecord> records){
    for(var cr in records){
      if(cr.field == DEFAULT_TIMEOUT) _defaultTimeout = new Duration(milliseconds: defaultTimeout);
      if(_changeRequiresReconfigure(cr)){
        _unconfigure();
        _configure();
        break;
      }
    }
  }
  
  _changeRequiresReconfigure(cr){
    return CODEC == cr.field ||SOCKET == cr.field; 
  }
  
  Future _call(String endpoint, String method, InvocationType invocationType, {List positional, Map named, Duration timeout}){
    var callId = _random.nextInt(4294967296);
    if(positional == null){
      positional = new List();
    }
    if(named == null){
      named = new Map();
    }
    var call = new Call(callId, endpoint, method, invocationType, positional:positional, named:named);
    var completer = new Completer();
    _completers[callId] = completer;

    var controller = new StreamController();
    controller.add(call);
    pipeStream(controller.stream.transform(codec.encoder), socket).
    then((_){
      if(timeout != null){
        var timer =  new Timer(timeout, () {
          _completers.remove(callId);
          if(!completer.isCompleted){
            completer.completeError('Call timed out');
          }
        });
     
      }
    }).catchError((error){
      completer.completeError(error);
    });

   return completer.future;
   
  }
 
  _configure(){ 
    if(_allAttributesSet()){ 
      var inbound = socket.onMessage.transform(new _MessageEventDecoder()).transform(codec.decoder).handleError((error){
       print('error $error');
      });
      
      //TODO Ask about this grossness
      var transformed = new StreamController.broadcast();
      
      pipeStream(inbound, transformed);
         
      _socketSubs.add(transformed.stream.where(((event){return event is CallResult;})).listen(_onCallResult));
      _socketSubs.add(transformed.stream.where(((event){return event is CallError;})).listen(_onCallError));
    }

  }
  
  _allAttributesSet() {
    return socket != null && codec != null;
  }
  
  _onCallResult(CallResult msg){
    var c = _completers.remove(msg.callId);
    if(c != null && !c.isCompleted){
      c.complete(msg.data);
    }
  }
  
  _onCallError(CallError msg){
    var c = _completers.remove(msg.callId);
    if(c != null && !c.isCompleted){
      c.completeError(msg.error);
    }
  }
  
  _unconfigure(){
    if(_outbound != null){
      _outbound.close();
      _outbound = null;
    }
    _socketSubs.forEach((s){s.cancel();});
    _socketSubs.clear();
  }
  
}

class _MessageEventDecoder extends Converter {
  
  convert(event) {
    return event.detail;
  }
  
  ChunkedConversionSink startChunkedConversion(
      ChunkedConversionSink<Object> sink) {
    return new _MessageEventDecoderSink(sink);
  }
  
}

class _MessageEventDecoderSink extends ChunkedConversionSink {
  
  bool _closed = false;
  
  ChunkedConversionSink _sink;
  
  _MessageEventDecoderSink(this._sink);
  
  void add(chunk) {
    print('adding chunk $chunk');
    if(_closed) throw new StateError('Only one chunk may be added');
    _sink.add(chunk.detail);
    _closed = true;
  }

  void close() {}
}