library everyday.showcase.shared;

import 'dart:convert';
import 'package:everyday_dart/rpc/serialization.dart' as rpc;
import 'package:everyday_dart/aai/serialization.dart' as aai;
import 'package:everyday_dart/rpc/serialization_codec.dart';
import 'package:serialization/serialization.dart';

class EverydayShowcaseCodec extends Codec {
  Codec _codec;
  EverydayShowcaseCodec(){
    var ser = new Serialization();
    rpc.configure(ser);
    aai.configure(ser);
    _codec = new SerializationCodec(ser).fuse(new JsonStringCodec());
  }

  Converter get decoder => _codec.decoder;

  Converter get encoder => _codec.encoder;
}

class EverydayShowcaseCodecMixin implements Codec<Object,String>{
 
  Codec __codec;
  
  get _codec {
    if(__codec == null){
      __codec = new EverydayShowcaseCodec();
    }
    return __codec;
  }
  
  Object decode(String encoded) {
    return _codec.decode(encoded);
  }

  Converter<String, Object> get decoder => _codec.decoder;

  String encode(Object input) {
    return _codec.encode(input);
  }

  Converter<Object, String> get encoder => _codec.encoder;

  Codec<Object, dynamic> fuse(Codec<String, dynamic> other) {
    return _codec.fuse(other);
  }

  Codec<String, Object> get inverted => _codec.inverted;
}


