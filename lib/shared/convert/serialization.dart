// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.convert.serialization;

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



