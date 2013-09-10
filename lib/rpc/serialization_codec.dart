// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.rpc.serialization_codec;

import 'dart:convert';
import 'package:serialization/serialization.dart';

class SerializationEncoder extends Converter {
  Serialization _serialization;
  SerializationEncoder(this._serialization);
  
  convert(input) {
    return _serialization.write(input);
  }
  
  ChunkedConversionSink startChunkedConversion(
      ChunkedConversionSink<Object> sink) {
    return new _SerializationEncoderSink(_serialization, sink);
  }
  
}

class _SerializationEncoderSink extends ChunkedConversionSink {
  
  bool _done = false;
  
  Serialization _serialization;
  ChunkedConversionSink _sink;
  
  _SerializationEncoderSink(this._serialization, this._sink);
  
  void add(chunk) {
    if(_done){
      throw new StateError("Only one call to add allowed");
    }
    _sink.add(_serialization.write(chunk));
    _sink.close();
    _done = true;
  }

  void close() {}
}

class SerializationDecoder extends Converter {
  Serialization _serialization;
  SerializationDecoder(this._serialization);
  
  convert(input) {
    return _serialization.read(input);
  }
  
  
  ChunkedConversionSink startChunkedConversion(
      ChunkedConversionSink<Object> sink) {
    return new _SerializationDecoderSink(_serialization, sink);
  }
  
}

class _SerializationDecoderSink extends ChunkedConversionSink {
  
  Serialization _serialization;
  ChunkedConversionSink _sink;
  
  bool _done = false;
  
  _SerializationDecoderSink(this._serialization, this._sink);
  
  void add(chunk) {
    if(!_done){
      _sink.add(_serialization.read(chunk));
      _sink.close();
    } else {
      throw new StateError('Only one chunk can be added');
    }
  }

  void close() {
   
  }
}

class SerializationCodec extends Codec {
  
  SerializationDecoder _decoder;
  SerializationEncoder _encoder;
  
  SerializationCodec(serialization) : 
    _encoder = new SerializationEncoder(serialization),
    _decoder = new SerializationDecoder(serialization);  
  
  Converter get decoder => _decoder;

  Converter get encoder => _encoder;
}

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
    print('JsonStrinkEncodeSink encoding $chunk');
    _sink.add(JSON.encode(chunk));
    _sink.close();
  }

  void close() {}
  
}

