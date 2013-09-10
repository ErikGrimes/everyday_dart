// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.model;

import 'package:observe/observe.dart';
import 'package:everyday_dart/persistence/entity_manager.dart';


class Profile extends Object with ObservableMixin implements Entity {
  
  static const Symbol FULL_NAME = const Symbol('fullName');
  static const Symbol ADDRESS_AS = const Symbol('addressAs');
  static const Symbol BORN_ON = const Symbol('bornOn');
  static const Symbol CONTACT_INFO = const Symbol('contactInfo');
  static const Symbol KEY = const Symbol('key');
  
  @observable
  int key;
  
  @observable
  String fullName;
  
  @observable
  String addressAs;
  
  @observable
  String bornOn;
  
  @observable
  ContactInfo contactInfo;
  
  Profile({this.key, this.fullName:'',this.addressAs:'', this.bornOn:'', contactInfo}){
    contactInfo = valueOrDefault(contactInfo, (){return new ContactInfo();});
  }
  
}

class ContactInfo extends Object with ObservableMixin  {
  
  static const Symbol PHONE = const Symbol('phone');
  static const Symbol EMAIL = const Symbol('email');
  static const Symbol MAILING_ADDRESS = const Symbol('mailingAddress');

  @observable
  String phone;
  
  @observable
  String email;
  
  @observable
  Address mailingAddress;
  
  ContactInfo({this.email:'', this.phone:'', mailingAddress}){
    mailingAddress = valueOrDefault(mailingAddress,(){return new Address();});
  }
  
}

class Address extends Object with ObservableMixin  {
  
  static const Symbol STREET_OR_BOX = const Symbol('streetOrBox');
  static const Symbol CITY = const Symbol('city');
  static const Symbol STATE_OR_REGION = const Symbol('stateOrRegion');
  static const Symbol POSTAL_CODE = const Symbol('postalCode');
  
  @observable
  String streetOrBox;
  
  @observable
  String city;
  
  @observable
  String stateOrRegion;

  @observable
  String postalCode;
  
  Address({this.streetOrBox:'',this.city:'', this.stateOrRegion:'', this.postalCode:''});
  
}

valueOrDefault(value, defaultGetter){
  if(value != null){
    return value;
  }
  return defaultGetter();
}