// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.io.everyday_socket;

import 'dart:async';

import 'package:polymer/polymer.dart';

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

abstract class EverydaySocket implements StreamSink, PolymerElement { 
  
  static final String SERVER_DISCONNECTED = 'SERVER_DISCONNECTED';
  static final String RAWSOCKET_ERROR = 'RAWSOCKET_ERROR';
  static final String CONNECT_TIMED_OUT = 'CONNECT_TIMED_OUT';
  static final String SERVER_INACTIVE = 'SERVER_INACTIVE';
  
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
  
  SocketState _state = SocketState.STOPPED;
  
  SocketState get state => _state;
  
  bool get isStarted =>  _state == SocketState.STARTED;
  bool get isStopped =>  _state == SocketState.STOPPED;
  bool get isOnline =>  _state == SocketState.ONLINE;
  bool get isOffline =>  _state == SocketState.OFFLINE;
  
  start(){
    if(!isStopped) throw new StateError('Tried to start an already started socket');
    _state = SocketState.STARTED;
    this.fire('everydaysocketstart');
  }
  
  stop(){
    if(isStopped) throw new StateError('Tried to stop an already stopped socket');
    _state = SocketState.STOPPED;
    this.fire('everydaysocketstop');
  }
  
  fireMessage(detail){
    this.fire('everydaysocketmessage', detail:detail);
  }
  
  fireOnline(){
    _state = SocketState.ONLINE;
    this.fire('everydaysocketonline');
  }
  
  fireOffline(){
    _state = SocketState.OFFLINE;
    this.fire('everydaysocketoffline');
  }
  
  fireError(detail){
    this.fire('everydaysocketerror',detail:detail);
  }
  
}
