// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.io.everyday_socket;

import 'dart:async';
import 'dart:html';

class SocketState {
  final index;
  final name;
  const SocketState(this.index, this.name);
  
  static const STARTED = const SocketState(0, 'STARTED');
  static const ONLINE = const SocketState(1, 'ONLINE');
  static const OFFLINE = const SocketState(1, 'OFFLINE');
  static const STOPPED = const SocketState(1, 'STOPPED');
  

  toString(){
    return name;
  }
}

abstract class EverydaySocket implements StreamSink { 
  
  static final String SERVER_DISCONNECTED = 'SERVER_DISCONNECTED';
  static final String RAWSOCKET_ERROR = 'RAWSOCKET_ERROR';
  static final String CONNECT_TIMED_OUT = 'CONNECT_TIMED_OUT';
  static final String SERVER_INACTIVE = 'SERVER_INACTIVE';
  
  Stream<Event> get onMessage;
  
  Stream<Event> get onError;
  
  Stream<Event> get onStop;
  
  Stream<Event> get onStart;
  
  Stream<Event> get onOnline;
  
  Stream<Event> get onOffline;
  
  SocketState get state;
  
  bool get isStarted;
  
  bool get isStopped;
  
  bool get isOnline;
  
  bool get isOffline;
  
}

abstract class EverydaySocketMixin implements EverydaySocket {
  
  String url;
  int timeout;
  int connectDelay;
  
  StreamController _controller;
  Stream _onError;
  Stream _onMessage;
  Stream _onOnline;
  Stream _onOffline;
  Stream _onStart;
  Stream _onStop;
  
  SocketState _state = SocketState.STOPPED;
  
  SocketState get state => _state;
  
  bool get isStarted =>  _state == SocketState.STARTED;
  bool get isStopped =>  _state == SocketState.STOPPED;
  bool get isOnline =>  _state == SocketState.ONLINE;
  bool get isOffline =>  _state == SocketState.OFFLINE;
  
  Stream<CustomEvent> streamFor(type);
  
  Map<String, dynamic> get customEventHandlers;
  
  StreamController get customEventController => _controller;
  
  start(){
    if(!isStopped) throw new StateError('Tried to start an already started socket');
    _controller = new StreamController.broadcast();
    _onError = streamFor('everyday-socket-error');
    _onMessage = streamFor('everyday-socket-message');
    _onOnline = streamFor('everyday-socket-online');
    _onOffline = streamFor('everyday-socket-offline');
    _onStart = streamFor('everyday-socket-start');
    _onStop = streamFor('everyday-socket-stop');
    _dispatchStart();
  }
  
  stop(){
    if(isStopped) throw new StateError('Tried to stop an already stopped socket');
    _dispatchStop();
    _controller.close();
  }
  
  dispatchCustomEvent(type, detail);
  
  Stream<Event> get onError => _onError;
  
  Stream<Event> get onMessage => _onMessage;
  
  Stream<Event> get onOnline => _onOnline;
  
  Stream<Event> get onOffline => _onOffline;
  
  Stream<Event> get onStart => _onStart;
  
  Stream<Event> get onStop => _onStop;
  
  get onEverydaySocketError => customEventHandlers['on-everyday-socket-error'];
  
  set onEverydaySocketError(value){
    customEventHandlers['on-everyday-socket-error'] = value;
  }
  
  get onEverydaySocketMessage => customEventHandlers['on-everyday-socket-message'];
  
  set onEverydaySocketMessage(value){
    customEventHandlers['on-everyday-socket-message'] = value;
  }
  
  get onEverydaySocketStart => customEventHandlers['on-everyday-socket-start'];
  
  set onEverydaySocketStart(value){
    customEventHandlers['on-everyday-socket-start'] = value;
  }
  
  get onEverydaySocketStop => customEventHandlers['on-everyday-socket-stop'];
  
  set onEverydaySocketStop(value){
    customEventHandlers['on-everyday-socket-stop'] = value;
  }
  
  get onEverydaySocketOnline => customEventHandlers['on-everyday-socket-online'];
  
  set onEverydaySocketOnline(value){
    customEventHandlers['on-everyday-socket-online'] = value;
  }
  
  get onEverydaySocketOffline => customEventHandlers['on-everyday-socket-offline'];
  
  set onEverydaySocketOffline(value){
    customEventHandlers['on-everyday-socket-offline'] = value;
  }
  
  _dispatchStart(){
    _state = SocketState.STARTED;
    dispatchCustomEvent('everyday-socket-start', null);
  }
  
  _dispatchStop(){
    _state = SocketState.STOPPED;
    dispatchCustomEvent('everyday-socket-stop', null);
  }
  
  dispatchMessage(detail){
    dispatchCustomEvent('everyday-socket-message', detail);
  }
  
  dispatchOnline(){
    _state = SocketState.ONLINE;
    dispatchCustomEvent('everyday-socket-online',null);
  }
  
  dispatchOffline(){
    _state = SocketState.OFFLINE;
    dispatchCustomEvent('everyday-socket-offline', null);
  }
  
  dispatchError(detail){
    dispatchCustomEvent('everyday-socket-error',detail);
  }
  
}
