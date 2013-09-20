library everyday.server.io.websocket;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:io' as io;

import 'package:logging/logging.dart';

import '../../shared/convert/stream.dart';
import '../../shared/isolate/isolate.dart';

import 'message_handler.dart';

class WebSocketTransformer extends StreamEventTransformer<io.HttpRequest,io.WebSocket> {
  
  static final Logger _LOGGER = new Logger('everyday.server.io.websocket_transformer');
  
  bool _discardRegular;
  
  WebSocketTransformer([discardRegular = true]): this._discardRegular = discardRegular;
  
  void handleData(io.HttpRequest request, EventSink<io.WebSocket> sink){
    if(io.WebSocketTransformer.isUpgradeRequest(request)){
      _LOGGER.info('Upgrading websocket');
      _setResponseHeaders(request.response);
      io.WebSocketTransformer.upgrade(request)
        .then((websocket){sink.add(websocket);})
          .catchError((error){
            sink.add(error);
          });
   }else if(_discardRegular){
     request.response.statusCode = io.HttpStatus.NOT_FOUND;
     request.response.close();
   }
  }
  
  void _setResponseHeaders(io.HttpResponse res) {
    res.headers.add("Access-Control-Allow-Origin", "*, ");
    res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  }
  
}

class HandleInNewFunctionIsolateTransformer extends StreamEventTransformer<io.WebSocket, Disposable>{
  
  static final Logger _LOGGER = new Logger('everyday.server.io.HandleInNewFunctionIsolateTransformer');
  
  final TransferableMessageHandlerFactory _handlerFactory;
  
  final Codec _codec;
  
  HandleInNewFunctionIsolateTransformer(this._codec, this._handlerFactory);
  
  handleData(io.WebSocket client, EventSink<Disposable> sink){
    var localReceive = new ReceivePort();
    _handlerFactory.create().then((handler){
      spawnFunctionIsolate(new MessageHandlerMain(_codec, handler, localReceive.toSendPort())).then((isolate){
        IsolateChannel.bind(localReceive).then((channel){
          client.pipe(channel).catchError((error){
            _LOGGER.warning('An error occurred on the client websocket $error', error);
          }).whenComplete((){
            _LOGGER.info('Client disconnected');
            isolate.dispose();
            client.close();
          });
          channel.pipe(client);
          sink.add(isolate);
        });
      });
    });
   
  }
}

class HandleInCurrentIsolateTransformer extends StreamEventTransformer<io.WebSocket, Disposable>{
  
  static final Logger _LOGGER = new Logger('everyday.server.io.HandleInCurrentIsolateTransformer');
  
  final MessageHandlerFactory _handlerFactory;
  Codec _codec;
  
  HandleInCurrentIsolateTransformer(this._codec, this._handlerFactory);
  
  //TODO Ensure proper cleanup
  handleData(io.WebSocket client, EventSink<Disposable> sink){
    _handlerFactory.create().then((handler){
      var decoderStream = new ConverterStream(_codec.decoder);
      decoderStream.pipe(handler); 
      client.pipe(decoderStream);
      var encoderStream = new ConverterStream(_codec.encoder);
      encoderStream.pipe(client);
      handler.pipe(encoderStream);
      sink.add(handler);
    });
  }
}

