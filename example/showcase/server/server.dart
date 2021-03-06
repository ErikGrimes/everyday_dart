// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.server.server;

import 'dart:io';
import 'dart:async';

import 'package:everyday_dart/server/rpc/message_handler.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/server/user/transient_user_service.dart';
import 'package:everyday_dart/server/persistence/postgresql_entity_manager.dart';
import 'package:everyday_dart/server/io/websocket.dart' as eio;
import 'package:everyday_dart/server/io/message_handler.dart';
import 'package:postgresql/postgresql_pool.dart';

import 'postgresql_persistence_handlers.dart';

import '../shared/codec.dart';

final Logger _LOGGER = new Logger('server');

String _databaseUrl = 'postgres://dev:dev@dev.local:5432/dev';

Timer _logTimer;

StringBuffer _logBuffer = new StringBuffer();

main(){
  runZoned(() {
   Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen(_logToConsole);
    
    _logTimer = new Timer.periodic(new Duration(seconds:1),(timer){
      if(_logBuffer.isNotEmpty){
        print(_logBuffer.toString());
        _logBuffer.clear();
      }
    });
    
    _LOGGER.info('Server started');
    _bindServerSocket().then((_) {
      _LOGGER.info('Server socket bound');
      _listenForRequests(_);});
    }, onError:(e, st){
      print(st);
    _LOGGER.warning('An unhandled exception occurred. Resources may have leaked.', e);});
}

_bindServerSocket(){
  return ServerSocket.bind('localhost', 8000);
}


_listenForRequests(socket){
    HttpServer server = new HttpServer.listenOn(socket);
    server.transform(new eio.WebSocketTransformer())
      .transform(new eio.CurrentIsolateTransformer(
          new EverydayShowcaseCodec(), 
          new EverydayShowcaseMessageHandlerFactory()))
            .listen((disposer){
    });
}


class EverydayShowcaseTransferableMessageHandlerFactory implements MessageHandlerContainer {
  
  Future<TransferableFactory<MessageHandler>> create() {
    return new Future.value(new EverydayShowcaseTransferableMessageHandler());  
  }
  
}

class EverydayShowcaseMessageHandlerFactory implements MessageHandlerContainer {
  
  Future<MessageHandler> create() {
    return new EverydayShowcaseTransferableMessageHandler().revive();
  }
  
}

abstract class EverydayShowcaseClientMixin {

  static int _poolMembers = 0;
  static Pool _pool;

  enter(){
    var completer = new Completer();
    if(_pool == null){
      _pool = new Pool(_databaseUrl);
      _pool.start().then((_){
        completer.complete(_pool);
      }).catchError((error){
        completer.completeError(error);
      });
    }else {
      completer.complete(_pool);
    }
    return completer.future;
  }

  leave(){
    _poolMembers--;
    if(_poolMembers == 0){
      _pool.destroy();
      _pool = null;
    }
  }
}

class EverydayShowcaseTransferableMessageHandler extends Object with EverydayShowcaseClientMixin implements TransferableFactory<MessageHandler> {
  
  static final Logger _LOGGER = new Logger('everyday.showcase.EverydayShowcaseTransferableMessageHandler');
  
  Future<MessageHandler> revive() {
    _LOGGER.info('Reviving MessageHandler');
    var completer = new Completer();
    enter().then((pool){
      _LOGGER.info('Entered environment');
      CallRouter router = new CallRouter();
      router.registerEndpoint('user', new TransientUserService());
      var handlers = {'Profile': new ProfileEntityHandler(new EverydayShowcaseCodec())};  
      var entityManager = new PostgresqlEntityManager(pool, handlers);
      router.registerEndpoint('entity-manager', entityManager);
      var handler = new RpcMessageHandler(router);
      handler.done.whenComplete((){
        leave();
      });
      completer.complete(handler);
    }).catchError((error){
      _LOGGER.info('Revive failed [$error]');
    });
    return completer.future;
  }
}


_logToConsole(LogRecord lr){
  if(lr.loggerName.startsWith('polymer')) return;
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  if(lr.error != null){
    json['error'] = lr.error;
  }
  _logBuffer.writeln(json);
}







