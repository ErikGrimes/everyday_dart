library everyday.io.message_handler;

import 'dart:async';


abstract class TransferableFactory<T> {
  Future<T> create();
}

abstract class MessageHandler<T> implements Stream, StreamSink {
  
}


abstract class MessageHandlerContainer {
  Future start();
  Future attach(Stream inbound, StreamSink outbound);
  stop();
}
