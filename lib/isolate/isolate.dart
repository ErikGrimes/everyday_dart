// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.isolate;

import 'dart:isolate';
import 'dart:async';

import 'package:logging/logging.dart';

class IsolateChannel extends Stream implements StreamSink {
  
  StreamController _controller = new StreamController();
  SendPort _sendPort;
  ReceivePort _receivePort;
  SendPort _replyTo;
  Completer _done = new Completer();
  
  IsolateChannel._(this._receivePort, this._sendPort){
    _receivePort.receive((message, replyTo){
      _controller.add(message);
    });
  }
  
  static Future<IsolateChannel> connect(SendPort connectTo){
    ReceivePort thisPort = new ReceivePort();
    connectTo.send('connect', thisPort.toSendPort());
    return new Future.value(new IsolateChannel._(thisPort, connectTo));
   
  }
  
  static Future<IsolateChannel> bind(ReceivePort value){
    var completer = new Completer();
    value.receive((message, replyTo){
      if(message == 'connect'){
        completer.complete(new IsolateChannel._(value, replyTo));
      }
    });
    return completer.future;
  }
  
  void add(event) {
    _sendPort.send(event, _replyTo);
  }

  void addError(errorEvent) {
    // TODO implement this method
    throw new UnimplementedError();
  }

  Future addStream(Stream stream) {
    var completer = new Completer();
      stream.listen((data){
        add(data);
      }, onError: (error){
        throw new UnimplementedError();
      }, onDone:(){
        completer.complete();
      });
      return completer.future;
  }

  Future close() {
    _receivePort.close();
    _done.complete();
    return new Future.value();
  }

  Future get done => _done.future;

  StreamSubscription listen(void onData(event), {void onError(error), void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError:onError, onDone: onDone, cancelOnError:cancelOnError);
  }
  
  _receive(message, replyTo){
    _controller.add(message);
  }
}
// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

abstract class FunctionIsolateMain {
    Future run(Future terminate);
}

class IsolateAbortedException implements Exception {
  
}

const Duration DEFAULT_MAX_WAIT = const Duration(seconds:1);

Future<FunctionIsolate>spawnFunctionIsolate(FunctionIsolateMain main, [maxWait = DEFAULT_MAX_WAIT]){
  var isolateMainSend = spawnFunction(_isolateMain);
  isolateMainSend.send(main);
  return new Future.value(new FunctionIsolate(isolateMainSend, maxWait));
}

class FunctionIsolate {
  
  SendPort _isolateMainSend;
  
  SendPort _controlSend;
  
  Duration _maxWait;
  
  bool _isDisposed = false;
  
  bool get isDisposed => _isDisposed;
  
  FunctionIsolate(this._isolateMainSend, this._maxWait);

  dispose(){
    _isolateMainSend.send(new _Die(_maxWait));
  }
  
}

class _Die {
  final Duration wait;
  
  _Die(this.wait);
}



_isolateMain(){
  var _LOGGER = new Logger('everyday.isolate._isolate_main');
  Logger.root.level = Level.ALL;
  _LOGGER.onRecord.listen(_logToConsole);
  var stop = new Completer();
  Future done;
  port.receive((message, replyTo){
    if (message is _Die){
      _LOGGER.finest('Termination signal received');
      port.close();
      stop.complete();
      var graceful = new Completer();
      var withPrejudice = new Timer(message.wait,(){
        if(!graceful.isCompleted){
          _LOGGER.finest('FunctionIsolateMain failed to stop.  Terminating with prejudice.');
          throw new IsolateAbortedException();
        }
      });
      if(done != null){
        done.whenComplete((){
          graceful.complete();
          _LOGGER.finest('Isolate shutdown gracefully');
        });
      }else {
        graceful.complete();
        _LOGGER.finest('Isolate shutdown gracefully');
      }
    }else if (message is FunctionIsolateMain){
      _LOGGER.finest('FunctionIsolateMain received');
      done = message.run(stop.future);
    }
  });
}

_logToConsole(LogRecord lr){
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  print(json);
}