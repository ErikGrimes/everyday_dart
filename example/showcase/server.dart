library everyday.showcase.server;

import 'dart:io';
import 'dart:async';

import 'package:everyday_dart/rpc/server.dart';
import 'package:everyday_dart/async/stream.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/aai/aai_service.dart';

import 'shared.dart';

final Logger _logger = new Logger('server');

main(){
  runZonedExperimental(() {
   Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_logToConsole);
    _logger.info('Server started');
    _initializePersistence()
      .then((_) =>  _bindServerSocket())
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

_initializePersistence(){
  return new Future.value(true);
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
  
  //TODO Explore approaches to scaling (forwarding messages, running each endpoint on it's own server socket).
  
  var router = new CallRouter();
  router.registerEndpoint('aai', new DefaultAAIService());
  
  var handler = new MessageHandler(router);
  var codec = new EverydayShowcaseCodec();

  //TODO Change this when Stream.pipe works with websockets
  
 pipeStream(socket.transform(codec.decoder), handler);
 pipeStream(handler.transform(codec.encoder), socket);
  
}



