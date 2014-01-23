// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.io.everyday_websocket;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

import 'package:everyday_dart/client/io/everyday_socket.dart';
import 'package:everyday_dart/shared/async/future.dart';

@CustomTag('everyday-websocket')
class EverydayWebsocket extends PolymerElement 
  with EverydaySocketMixin
  implements EverydaySocket {

  static final _LOGGER = new Logger('everyday.io.everyday_websocket');
  
  Duration _reconnectDelay = new Duration(seconds:1);
  
  Duration _connectTimeout = new Duration(seconds:1);
  
  Completer _done;
  WebSocket _websocket;
  
  @published
  bool auto = false;
  
  @published
  String url;
  
  @published
  int connectTimeout = 1000;
  
  @published
  int reconnectDelay = 1000;

  EverydayWebsocket.created() : super.created();
  
  Future get done => _done.future;
  
  enteredView(){
    
    super.enteredView();
    if(this.auto){
      start();  
    }
  }
  
  leftView(){
    stop();
    super.leftView();
    
  }
  
  close(){
    stop();
  }
  
  start(){
    super.start();
    _done = new Completer();
    _configure();
  }
  
  stop(){
    super.stop();
    _done.complete();
    _unconfigure();
  }
  
  autoChanged(oldValue){
    if(this.auto && !this.isStarted){
      start();
    }
  }
  
  urlChanged(oldValue){
    if(this.isStarted){
      _unconfigure();
      _configure();
    }
  }
  
  reconnectDelayChanged(oldValue){
    _reconnectDelay = new Duration(milliseconds: reconnectDelay);
  }
  
  connectTimeoutChanged(oldValue){
    _connectTimeout = new Duration(milliseconds: connectTimeout);
  }
  
  _assertOnline(){
    if(!isOnline) throw new StateError('Socket is currently offline');
  }
  
  _configure(){
    if(_requiredAttributesSet) {
      _queueConnect(Duration.ZERO);
    }
  }
  
  _unconfigure(){
    _closeSocket();
  }
  
  int count = 0;
  
  _queueConnect(Duration delay){
 
    _websocket = null;
    new Timer(delay,(){
      _LOGGER.finest('Connecting to $url');
      _connect(url, _connectTimeout).then((websocket){
        _LOGGER.finest('Connected to $url');
        _websocket = websocket;
        _websocket.onMessage.listen((data){
          fireMessage(data.data);});
        _websocket.onError.listen((error){    
          fireError(EverydaySocket.RAWSOCKET_ERROR);
          fireOffline();
          _queueConnect(_reconnectDelay);});
       _websocket.onClose.listen((_){
         _LOGGER.finest('Connection to $url unexpectedly closed');
         fireError(EverydaySocket.SERVER_DISCONNECTED);
         fireOffline();
         _queueConnect(_reconnectDelay);});
        fireOnline();
       }).catchError((e){
         _LOGGER.finest('Initial connect to $url failed',e);
         fireError(e);
         _queueConnect(_reconnectDelay);
       }); 
    });
  }
    
  
  _closeSocket(){
    if(_websocket != null){
      _websocket.close();
      _websocket == null;
    }
  }
  
  get _requiredAttributesSet => url != null;
  
  static Future _connect(String url, Duration timeout){
    var websocket = new WebSocket(url); 
    var completer = new TimedCompleter(timeout);
   
    List _subs = [];
    
    _subs.add(websocket.onError.listen((event){
      _subs.forEach((s){s.cancel();});
      completer.completeError(EverydaySocket.RAWSOCKET_ERROR);
    }));
    
    _subs.add(websocket.onOpen.listen((event) { 
      _subs.forEach((s){s.cancel();});
      completer.complete(websocket);
    }));
    
    return completer.future;
  }

  void add(event) {
   _assertOnline();
   if(isOnline){
      _websocket.send(event);
   }
  }

  //TODO Figure out what this should do
  void addError(error, [stackTrace]) {
    
  }

  Future addStream(Stream stream) {
   var completer = new Completer();
   stream.listen((data) {
     add(data);
   }, onError: (error){
     completer.complete(error);
   }, onDone: (){
     if(!completer.isCompleted){
      completer.complete();
     }
   }, cancelOnError: true);
   return completer.future;
  }

}