// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.io.everyday_websocket;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

import '../polymer/polyfills.dart';
import 'everyday_socket.dart';

@CustomTag('everyday-websocket')
class EverydayWebsocket extends PolymerElement 
  with ObservableMixin, EverydaySocketMixin, CustomEventsMixin
  implements EverydaySocket {
  
  static const Symbol RECONNECT_DELAY = const Symbol('reconnectDelay');
  static const Symbol CONNECT_TIMEOUT = const Symbol('connectTmeout');
  static const Symbol URL = const Symbol('url');

  static final _LOGGER = new Logger('everyday.io.everyday_websocket');
  
  Duration _reconnectDelay = new Duration(seconds:1);
  Duration _connectTimeout = new Duration(seconds:1);
  Completer _done;
  StreamSubscription _selfSub;
  WebSocket _websocket;
 
  @observable
  String url;
  
  int get connectTimeout => _connectTimeout.inMilliseconds;
  
  set connectTimeout(int value){
    _connectTimeout = new Duration(milliseconds: this.notifyPropertyChange(CONNECT_TIMEOUT, _connectTimeout.inMilliseconds, value));  
  }
  
  int get reconnectDelay => _reconnectDelay.inMilliseconds;
  
  set reconnectDelay(int value){
    _reconnectDelay = new Duration(milliseconds: this.notifyPropertyChange(RECONNECT_DELAY, _connectTimeout.inMilliseconds, value));  
  }
  
  Future get done => _done.future;
  
  inserted(){
   start();  
  }
  
  removed(){
    stop();
  }
  
  close(){
    stop();
  }
  
  start(){
    super.start();
    _done = new Completer();
    _configure();
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  stop(){
    super.stop();
    _done.complete();
    _selfSub.cancel();
    _unconfigure();
  }

  _propertyChanged(List<ChangeRecord> records){
    for(var cr in records){
      if(_changeRequiresReconfigure(cr)){
        _unconfigure();
        _configure();
        break;
      }
    }
  }
  
  _changeRequiresReconfigure(cr){
    return cr.field == URL;
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
  
  _queueConnect(Duration delay){
    _websocket = null;
    new Timer(delay,(){
      _LOGGER.finest('Connecting to $url');
      _connect(url, _connectTimeout).then((websocket){
        _LOGGER.finest('Connected to $url');
        _websocket = websocket;
        _websocket.onMessage.listen((data){dispatchMessage(data.data);});
        _websocket.onError.listen((error){    
          dispatchError(EverydaySocket.RAWSOCKET_ERROR);
          dispatchOffline();
          _queueConnect(_reconnectDelay);});
       _websocket.onClose.listen((_){
         _LOGGER.finest('Connection to $url unexpectedly closed');
         dispatchError(EverydaySocket.SERVER_DISCONNECTED);
         dispatchOffline();
         _queueConnect(_reconnectDelay);});
        dispatchOnline();
       }).catchError((e){
         _LOGGER.finest('Initial connect to $url failed',e);
         dispatchError(e);
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
    var completer = new Completer();
    if(timeout != null){
      var timer =  new Timer(timeout, () {
        if(!completer.isCompleted){
          completer.completeError(EverydaySocket.CONNECT_TIMED_OUT);
        }
      });   
    }
    
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
  void addError(error) {
    
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