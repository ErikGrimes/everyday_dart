// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.shared.model;

import 'package:observe/observe.dart';
import 'package:everyday_dart/shared/persistence/entity_manager.dart';


class Profile extends Object with Observable implements Entity {
  
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
  
  Profile() : this.from(contactInfo: new ContactInfo());
  
  Profile.from({this.key, this.fullName, this.addressAs, this.bornOn, this.contactInfo});
  
  String toString(){
    return 'Profile {key: $key}';
  }
  
}

class ContactInfo extends Object with Observable  {

  @observable
  String phone;
  
  @observable
  String email;
  
  @observable
  Address mailingAddress;
  
  ContactInfo() : this.from(mailingAddress: new Address());
  
  ContactInfo.from({this.email, this.phone, this.mailingAddress});
  
}

class Address extends Object with Observable  {
  
  @observable
  String streetOrBox;
  
  @observable
  String city;
  
  @observable
  String stateOrRegion;

  @observable
  String postalCode;
  
  Address() : this.from();
  
  Address.from({this.streetOrBox, this.city, this.stateOrRegion, this.postalCode});
  
}
