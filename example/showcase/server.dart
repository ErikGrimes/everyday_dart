library everyday.showcase.server;

import 'dart:io';
import 'dart:async';

import 'package:everyday_dart/rpc/server.dart';
import 'package:everyday_dart/async/stream.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/aai/aai_service.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'package:everyday_dart/persistence/entity_manager_service.dart';
import 'persistence_handlers.dart';

import 'shared.dart';

final Logger _logger = new Logger('server');

Pool _pool;

main(){
  runZonedExperimental(() {
   Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_logToConsole);
    _logger.info('Server started');
    _initializePersistence('postgres://dev:dev@dev.local:5432/dev',3,5)
      .then((pool)  { 
        _pool = pool;
        return _bindServerSocket();
        })
        .then((_) {
          _logger.info('Server socket bound');
          _listenForRequests(_);});
    }, onError:(e){
    _logger.warning('An unhandled exception occurred. Resources may have leaked.', e);});
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
      _logger.info('Upgrading websocket');
      _addCorsHeaders(request.response);
      WebSocketTransformer.upgrade(request).then(_handleNewClient);
   }else {
     _logger.info('Discarding regular http request');
     request.response.close();
   }
    
}

void _addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*, ");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

_initializePersistence(url, min, max){
  var completer = new Completer();
  var pool = new Pool(url, min: min, max: max);
  //TODO Pool is starting event when connections fails
  pool.start().then((v){
    _logger.info('Persistence initialized...');
    completer.complete(pool);
  }).catchError((e){
    completer.completeError(e);
  });
  return completer.future;
}

_logToConsole(LogRecord lr){
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  print(json);
}

_handleNewClient(WebSocket socket){
  
  var router = new CallRouter();
  router.registerEndpoint('aai', new DefaultAAIService());
  
  var codec = new EverydayShowcaseCodec();
  
  var handlers = {'Profile': new ProfileEntityHandler(codec)};
  
  var entityManager = new PostgresqlEntityManagerService(_pool, handlers);
  
  router.registerEndpoint('entity-manager', entityManager);
  
  var handler = new MessageHandler(router);


  //TODO Change this when Stream.pipe works with websockets
  
 pipeStream(socket.transform(codec.decoder), handler);
 pipeStream(handler.transform(codec.encoder), socket);
  
}



