// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.rpc.everyday_rpc;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/rpc/messages.dart';
import 'package:everyday_dart/shared/rpc/invoker.dart';
import 'package:everyday_dart/shared/convert/stream.dart';
import 'package:everyday_dart/shared/async/future.dart';

import 'package:everyday_dart/client/io/everyday_socket.dart';

final Logger _LOGGER = new Logger('everyday.rpc.everyday_rpc');

@CustomTag('everyday-rpc')
class EverydayRpc extends PolymerElement implements Invoker  {
  

  
  static final Symbol CODEC = const Symbol('codec');
  static final Symbol DEFAULT_TIMEOUT = const Symbol('defaultTimeout');
  static final Symbol SOCKET = const Symbol('socket');
  
  StreamController _outbound;
  
  StreamSubscription _selfSub;
  
  Map _completers = new Map();
  
  Random _random = new Random(new DateTime.now().millisecondsSinceEpoch);
  
  List _socketSubs = [];
  
  Duration _defaultTimeout = new Duration(milliseconds: 1000);
  
  @published
  int defaultTimeout = 1000;
  
  @published
  Codec codec;
  
  @published
  EverydaySocket socket;
  
  EverydayRpc.created() : super.created();
  
  enteredView(){
   
    _configure();
    
    _selfSub = this.changes.listen(_propertyChanged);
    
  }
  
  leftView(){
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
  
  get _nextCallId => _random.nextInt(4294967296);  
  
  Future _call(String endpoint, String method, InvocationType invocationType, {List positional, Map named, Duration timeout}){
       
    if(positional == null){
      positional = new List();
    }
    
    if(named == null){
      named = new Map();
    }
    
    var call = new Call(_nextCallId, endpoint, method, invocationType, positional:positional, named:named);
    
    var completer = new TimedCompleter(timeout);
    
    completer.future.catchError((_){}).whenComplete(_completers.remove(call.callId));
    
    _completers[call.callId] = completer;
    
    var watch = new Stopwatch();
    
    watch.start();
    
    var encoded = codec.encoder.convert(call);
    
    _LOGGER.finest('Sending {callId: ${call.callId}, target: ${call.endpoint}, method: ${call.method}, encodingMilliseconds: ${watch.elapsedMilliseconds} }');
       
    watch.stop();
    
    if(socket.isOnline){
      socket.add(encoded);
    }
    
   return completer.future;
   
  }
 
  _configure(){ 
    if(_allAttributesSet()){ 
      //TODO Figure out proper cleanup and error handling
      var decoderStream = new ConverterStream(new _MessageEventDecoder(codec.decoder));
      socket.on['everyday-socket-message'].listen((data){
        decoderStream.addStream(new Stream.fromIterable([data]));
      });
      var decoded = decoderStream.asBroadcastStream();
      _socketSubs.add(decoded.where(((event){return event is CallResult;})).listen(_onCallResult));
      _socketSubs.add(decoded.where(((event){return event is CallError;})).listen(_onCallError));
    }

  }
  
  _allAttributesSet() {
    return socket != null && codec != null;
  }
  
  _onCallResult(CallResult msg){
    var c = _completers.remove(msg.callId);
    _LOGGER.finest('Completing {callId: ${msg.callId}, elapsedMilliseconds: ${c.timeTaken.inMilliseconds}}');
    if(c != null && !c.isCompleted){
      c.complete(msg.data);
    }
  }
  
  _onCallError(CallError msg){
    _LOGGER.finest('Completing call ${msg.callId}');
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
  
  Converter _converter;
  
  _MessageEventDecoder(this._converter);
  
  convert(event) {
    var watch = new Stopwatch();
    watch.start();
    var decoded = _converter.convert(event.detail);
    watch.stop();
    _LOGGER.finest('Decoded {elapsedMilliseconds ${watch.elapsedMilliseconds}');
    return decoded;
    //return _converter.convert(event.detail);
  }
  
  ChunkedConversionSink startChunkedConversion(
      ChunkedConversionSink<Object> sink) {
    return new _MessageEventDecoderSink(_converter, sink);
  }
  
}

class _MessageEventDecoderSink extends ChunkedConversionSink {
  
  bool _closed = false;
  
  ChunkedConversionSink _sink;
  
  Converter _converter; 
  
  _MessageEventDecoderSink(this._converter, this._sink);
  
  void add(chunk) {
    if(_closed) throw new StateError('Only one chunk may be added');
    
    var watch = new Stopwatch();
    watch.start();
    var decoded = _converter.convert(chunk.detail);
    watch.stop();
    _LOGGER.finest('Decoded {elapsedMilliseconds ${watch.elapsedMilliseconds}');
    _sink.add(decoded);
    _closed = true;
  }

  void close() {}
}