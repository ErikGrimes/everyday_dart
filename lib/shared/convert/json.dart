library everyday.shared.convert.json;

import 'dart:convert';

class JsonStringCodec extends Codec {
  
  JsonStringDecoder _decoder;
  JsonStringEncoder _encoder;
  
  JsonStringCodec() : 
    _decoder = new JsonStringDecoder(),
    _encoder = new JsonStringEncoder();

  Converter get decoder => _decoder;

  Converter get encoder => _encoder;
}

class JsonStringEncoder extends Converter {
  
  convert(input) {
    return JSON.encode(input);
  }
  
  ChunkedConversionSink startChunkedConversion(
                                               ChunkedConversionSink<Object> sink) {
    return new JsonStringEncodeSink(sink);
  }
}

class JsonStringDecoder extends Converter {
  
  convert(input) {
    return JSON.decode(input);
  }
  
  ChunkedConversionSink startChunkedConversion(
                                               ChunkedConversionSink<Object> sink) {
    return new JsonStringDecodeSink(sink);
  }
}

class JsonStringDecodeSink extends ChunkedConversionSink {
  
  bool _done = false;
  
  ChunkedConversionSink _sink;
 
  JsonStringDecodeSink(this._sink);
  
  void add(chunk) {
    if(_done){
      throw new StateError("Only one call to add allowed");
    }
    _sink.add(JSON.decode(chunk));
    _sink.close();
  }

  void close() {}
}

class JsonStringEncodeSink extends ChunkedConversionSink {
  
  
  bool _done = false;
  
  ChunkedConversionSink _sink;
  
  JsonStringEncodeSink(this._sink);
  
  void add(chunk) {
    if(_done){
      throw new StateError("Only one call to add allowed");
    }
    _sink.add(JSON.encode(chunk));
    _sink.close();
  }

  void close() {}
  
}