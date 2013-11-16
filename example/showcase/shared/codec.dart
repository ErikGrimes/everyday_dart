// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.shared;

import 'dart:convert';

import 'package:everyday_dart/shared/rpc/serialization.dart' as rpc;
import 'package:everyday_dart/shared/user/serialization.dart' as user;
import 'package:everyday_dart/shared/patch/serialization.dart' as patch;
import 'package:everyday_dart/shared/async/serialization.dart' as async;
import 'package:everyday_dart/shared/convert/json.dart';
import 'package:everyday_dart/shared/convert/serialization.dart';
import 'package:serialization/serialization.dart';


import 'model.dart';

class EverydayShowcaseCodec extends Codec {
  Codec _codec;
  EverydayShowcaseCodec(){
    var serialization = new Serialization();
    rpc.configure(serialization);
    user.configure(serialization);
    patch.configure(serialization);
    async.configure(serialization);
    serialization.addRule(new ProfileRule());
    serialization.addRule(new ContactInfoRule());
    serialization.addRule(new AddressRule());
    _codec = new SerializationCodec(serialization).fuse(new JsonStringCodec());
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

class ProfileRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == Profile;
  getState(Profile instance) => [instance.key, instance.addressAs, instance.bornOn, instance.fullName, instance.contactInfo];
  create(state) => new Profile.from(key:state[0], addressAs:state[1], bornOn:state[2], fullName: state[3], contactInfo:state[4]);
  setState(instance, List state) => {};
}

class ContactInfoRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == ContactInfo;
  getState(ContactInfo instance) => [instance.phone, instance.email, instance.mailingAddress];
  create(state) => new ContactInfo.from(phone:state[0], email:state[1], mailingAddress: state[2]);
  setState(instance, List state) => {};
}

class AddressRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == Address;
  getState(Address instance) => [instance.streetOrBox, instance.city, instance.stateOrRegion, instance.postalCode];
  create(state) => new Address.from(streetOrBox:state[0], city:state[1], stateOrRegion: state[2], postalCode:state[3]);
  setState(instance, List state) => {};
}


