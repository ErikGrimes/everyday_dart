import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:logging/logging.dart';
import '../../shared/convert/stream.dart';
import '../../shared/isolate/isolate.dart';



abstract class MessageHandler<T> implements Stream, StreamSink, Disposable {
  
}


abstract class MessageHandlerFactory {
  Future<MessageHandler> create();
}

abstract class TransferableMessageHandlerFactory {
  Future<Transferable<MessageHandler>> create();
}

abstract class Transferable<T> {
  Future<T> revive();
}

class MessageHandlerMain implements FunctionIsolateMain {
  
  static final Logger _LOGGER = new Logger('everyday.io.message_handler.message_handler_main');
  
  final SendPort _sendPort;
  
  Completer _done;
  IsolateChannel _channel;
  Transferable<MessageHandler> _transferable;
  Codec _codec;
  MessageHandler _handler;
  
  MessageHandlerMain(this._codec, this._transferable, this._sendPort);
  
  Future run(Future stop) {
    _LOGGER.finest('Started');
    _done = new Completer();
    stop.then(_dispose);
      _transferable.revive().then((handler) {
        _handler = handler;
        IsolateChannel.connect(_sendPort).then((channel){
          _LOGGER.finest('IsolateChannel connected');
          _channel = channel;
          var decoderStream = new ConverterStream(_codec.decoder);
          decoderStream.pipe(_handler);
          _channel.pipe(decoderStream);   
          var encoderStream = new ConverterStream(_codec.encoder);
          encoderStream.pipe(_channel);
          _handler.pipe(encoderStream);
        }).catchError((error) {
          _done.completeError(error);
        });
      });
    return _done.future;
  }
  
  _dispose(dynamic){
    _channel.close();
    _handler.dispose();
    _done.complete();
  }
}