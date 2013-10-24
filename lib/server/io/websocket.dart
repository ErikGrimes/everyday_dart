library everyday.server.io.websocket;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:io' as io;

import 'package:logging/logging.dart';

import '../../shared/convert/stream.dart';
import '../../shared/isolate/isolate.dart';

import 'message_handler.dart';

class _WebSocketTransformSink implements EventSink<io.HttpRequest> {
  static final Logger _LOGGER = new Logger('everyday.server.io.websocket_transformer');
  
  final EventSink<io.WebSocket> _outputSink;
  
  bool _discardRegular;
  
  _WebSocketTransformSink(this._outputSink, this._discardRegular);

  void add(io.HttpRequest request) {
    if(io.WebSocketTransformer.isUpgradeRequest(request)){
      _LOGGER.info('Upgrading websocket');
      _setResponseHeaders(request.response);
      io.WebSocketTransformer.upgrade(request)
        .then((websocket){_outputSink.add(websocket);})
          .catchError((error){
            _outputSink.add(error);
          });
   }else if(_discardRegular){
     request.response.statusCode = io.HttpStatus.NOT_FOUND;
     request.response.close();
   }
  }

  void addError(e, [st]) => _outputSink.addError(e, st);
  void close() => _outputSink.close();
  
  void _setResponseHeaders(io.HttpResponse res) {
    res.headers.add("Access-Control-Allow-Origin", "*, ");
    res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  }
  
}

class WebSocketTransformer implements StreamTransformer<io.HttpRequest,io.WebSocket> {
  
  bool _discardRegular;
  
  WebSocketTransformer([discardRegular = true]): this._discardRegular = discardRegular;

  Stream<io.WebSocket> bind(Stream<io.HttpRequest> stream) =>
    new Stream<io.WebSocket>.eventTransformed(
        stream,
        (EventSink sink) => new _WebSocketTransformSink(sink, _discardRegular));
  
}

class _HandleInNewFunctionIsolateTransformSink implements EventSink<io.WebSocket> {

  static final Logger _LOGGER = new Logger('everyday.server.io.HandleInNewFunctionIsolateTransformer');
  
  final TransferableMessageHandlerFactory _handlerFactory;
  
  final Codec _codec;
  
  final EventSink<Disposable> _outputSink;
  
  _HandleInNewFunctionIsolateTransformSink(this._codec, this._handlerFactory, this._outputSink);

  void add(io.WebSocket client) {
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
          _outputSink.add(isolate);
        });
      });
    });
  }

  void addError(e, [st]) => _outputSink.addError(e, st);
  void close() => _outputSink.close();
 
}

class HandleInNewFunctionIsolateTransformer implements StreamTransformer<io.WebSocket, Disposable>{
  
 final TransferableMessageHandlerFactory _handlerFactory;
  
  final Codec _codec;
  
  HandleInNewFunctionIsolateTransformer(this._codec, this._handlerFactory);
  
  Stream<Disposable> bind(Stream<io.WebSocket> stream) =>
      new Stream<Disposable>.eventTransformed(
          stream,
          (EventSink sink) => new _HandleInNewFunctionIsolateTransformSink(_codec, _handlerFactory, sink));
  
}

class _HandleInCurrentIsolateTransformSink implements EventSink<io.WebSocket> {

  static final Logger _LOGGER = new Logger('everyday.server.io.HandleInCurrentIsolateTranformer');
  
  final MessageHandlerFactory _handlerFactory;
  
  final Codec _codec;
  
  final EventSink<Disposable> _outputSink;
  
  _HandleInCurrentIsolateTransformSink(this._codec, this._handlerFactory, this._outputSink);

  void add(io.WebSocket client) {
    _handlerFactory.create().then((handler){
      var decoderStream = new ConverterStream(_codec.decoder);
      decoderStream.pipe(handler); 
      client.pipe(decoderStream);
      var encoderStream = new ConverterStream(_codec.encoder);
      encoderStream.pipe(client);
      handler.pipe(encoderStream);
      _outputSink.add(handler);
    });
    
  }

  void addError(e, [st]) => _outputSink.addError(e, st);
  void close() => _outputSink.close();
 
}


class HandleInCurrentIsolateTransformer implements StreamTransformer<io.WebSocket, Disposable>{
  
  final MessageHandlerFactory _handlerFactory;
  Codec _codec;
  
  HandleInCurrentIsolateTransformer(this._codec, this._handlerFactory);
  
  Stream<Disposable> bind(Stream<io.WebSocket> stream) =>
      new Stream<Disposable>.eventTransformed(
          stream,
          (EventSink sink) => new _HandleInCurrentIsolateTransformSink(_codec, _handlerFactory, sink));
}

