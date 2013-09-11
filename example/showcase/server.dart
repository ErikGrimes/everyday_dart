// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.server;

import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:everyday_dart/rpc/server.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/aai/aai_service.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'package:everyday_dart/persistence/entity_manager_service.dart';
import 'package:everyday_dart/isolate/isolate.dart';
import 'package:everyday_dart/async/stream.dart';

import 'persistence_handlers.dart';
import 'shared.dart';

final Logger _LOGGER = new Logger('server');

String _databaseUrl = 'postgres://dev:dev@dev.local:5432/dev';

main(){
  runZonedExperimental(() {
   Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_logToConsole);
    _LOGGER.info('Server started');
    _bindServerSocket().then((_) {
      _LOGGER.info('Server socket bound');
      _listenForRequests(_);});
    }, onError:(e){
    _LOGGER.warning('An unhandled exception occurred. Resources may have leaked.', e);});
}

_bindServerSocket(){
  return ServerSocket.bind('localhost', 8080);
}

_listenForRequests(socket){
    HttpServer server = new HttpServer.listenOn(socket);
    server.listen(_handleRequest);
}

_handleRequest(request){
 
  if(WebSocketTransformer.isUpgradeRequest(request)){
      _LOGGER.info('Upgrading websocket');
      _addCorsHeaders(request.response);
      WebSocketTransformer.upgrade(request).then((_handleNewClient));
   }else {
     _LOGGER.info('Discarding regular http request');
     request.response.close();
   }
    
}

void _addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*, ");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

_logToConsole(LogRecord lr){
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  print(json);
}

_handleNewClient(WebSocket client){
 
  var localReceive = new ReceivePort();
  
  var main = new EverydayShowcaseClientMain(_databaseUrl, localReceive.toSendPort());
  
  spawnFunctionIsolate(main).then((isolate){
    IsolateChannel.bind(localReceive).then((channel){
      client.pipe(channel).then((_){}).catchError((error){
        _LOGGER.warning('An error occurred on the client websocket $error', error);
      }).whenComplete((){
        _LOGGER.info('Client disconnected');
        isolate.dispose();
        client.close();
      });
      channel.pipe(client);
    });
  });
}

class EverydayShowcaseClientMain implements FunctionIsolateMain {
 
  static final Logger _LOGGER = new Logger('everyday.showcase.server.everyday_showcase_client_main');
  
  String _databaseUrl;
  final SendPort _sendPort;
  
  Completer _done;
  Pool _pool;
  IsolateChannel _channel;
  
  EverydayShowcaseClientMain(this._databaseUrl, this._sendPort);
  
  Future run(Future stop) {
    _LOGGER.finest('Client started');
    _done = new Completer();
    stop.then(_dispose);
    _initializePersistence().then((pool){
      _LOGGER.finest('Persistence initialized');
      _pool = pool;
      var router = new CallRouter();
      router.registerEndpoint('aai', new DefaultAAIService());
      var codec = new EverydayShowcaseCodec();
      var handlers = {'Profile': new ProfileEntityHandler(codec)};  
      var entityManager = new PostgresqlEntityManagerService(_pool, handlers);
      router.registerEndpoint('entity-manager', entityManager);
      var handler = new MessageHandler(router);  
      
      IsolateChannel.connect(_sendPort).then((channel){
        _LOGGER.finest('IsolateChannel connected');
        _channel = channel;
       _channel.transform(codec.decoder).pipe(new InsatiableStreamConsumer(handler));
       handler.transform(codec.encoder).pipe(new InsatiableStreamConsumer(channel));
      });
      

    }).catchError((error){
      _done.completeError((error));
    });
    
    return _done.future;
  }
  
  _dispose(dynamic){
    _pool.destroy();
    _channel.close();
    _done.complete();
  }
  
  _initializePersistence(){
    var completer = new Completer();
    var pool = new Pool(this._databaseUrl, min: 1, max: 1);
    //TODO Pool is starting event when connections fails
    pool.start().then((v){
      completer.complete(pool);
    }).catchError((e){
      completer.completeError(e);
    });
    return completer.future;
  }
  
}





