library everyday.showcase.model;

import 'package:observe/observe.dart';
import 'package:everyday_dart/persistence/entity_manager.dart';


class Profile extends Object with ChangeNotifierMixin implements Entity {
  
  static const Symbol FULL_NAME = const Symbol('fullName');
  static const Symbol ADDRESS_AS = const Symbol('addressAs');
  static const Symbol BORN_ON = const Symbol('bornOn');
  static const Symbol CONTACT_INFO = const Symbol('contactInfo');
  static const Symbol KEY = const Symbol('key');
  
  int _key;
  String _fullName;
  String _addressAs;
  String _bornOn;
  ContactInfo _contactInfo;
  
  Profile({key, fullName:'',addressAs:'', bornOn:'', contactInfo}):
    _key = key,
    _fullName = fullName,
    _addressAs = addressAs,
    _bornOn = bornOn {
    _contactInfo = valueOrDefault(contactInfo, (){return new ContactInfo();});
  }
  
  get key => _key;
  
  set key(int value){
    _key = this.notifyPropertyChange(KEY,_key,value);
  }
  
  get fullName => _fullName;
  
  set fullName(String value) {
    _fullName = this.notifyPropertyChange(FULL_NAME,_fullName,value);
  }
  
  get addressAs => _addressAs;
  
  set addressAs(String value) {
    _addressAs = this.notifyPropertyChange(ADDRESS_AS,_addressAs,value);
  }
  
  get bornOn => _bornOn;
  
  set bornOn(String value) {
    _bornOn = this.notifyPropertyChange(BORN_ON,_bornOn,value);
  }
  
  toString(){
    return super.toString();
  }
  
}

class ContactInfo extends Object with ChangeNotifierMixin  {
  
  static const Symbol PHONE = const Symbol('phone');
  static const Symbol EMAIL = const Symbol('email');
  static const Symbol MAILING_ADDRESS = const Symbol('mailingAddress');

  String _phone; 
  String _email;
  Address _mailingAddress;
  
  ContactInfo({email:'', phone:'', mailingAddress}):
    _email = email, 
    _phone = phone {
    _mailingAddress = valueOrDefault(mailingAddress,(){return new Address();});
  }
  
  String get phone => _phone;
  
  set phone(String value){
    _phone = this.notifyPropertyChange(PHONE, _phone, value);
  }
  
  String get email => _email;
  
  set email(String value){
    _email = this.notifyPropertyChange(EMAIL, _phone, value);
  }
  
  Address get mailingAddress => _mailingAddress;
  
  set mailingAddress(Address value){
    _mailingAddress = this.notifyPropertyChange(MAILING_ADDRESS, _phone, value);
  }  
}

class Address extends Object with ChangeNotifierMixin  {
  
  static const Symbol STREET_OR_BOX = const Symbol('streetOrBox');
  static const Symbol CITY = const Symbol('city');
  static const Symbol STATE_OR_REGION = const Symbol('stateOrRegion');
  static const Symbol POSTAL_CODE = const Symbol('postalCode');
  
  String _streetOrBox;
  String _city;
  String _stateOrRegion;
  String _postalCode;
  
  Address({streetOrBox:'',city:'', stateOrRegion:'', postalCode:''}): 
    _streetOrBox = streetOrBox,
    _city = city,
    _stateOrRegion = stateOrRegion,
    _postalCode=postalCode;
  
  String get streetOrBox => _streetOrBox;
  
  set streetOrBox(String value){ 
    _streetOrBox = this.notifyPropertyChange(STREET_OR_BOX, _streetOrBox, value);
  }
  
  String get city => _city;
  
  set city(String value){ 
    _city = this.notifyPropertyChange(CITY, _city, value);
  }
  
  String get stateOrRegion => _stateOrRegion;
  
  set stateOrRegion(String value){ 
    _stateOrRegion = this.notifyPropertyChange(STATE_OR_REGION, _stateOrRegion, value);
  }
  
  String get postalCode => _postalCode;
  
  set postalCode(String value){ 
    _postalCode = this.notifyPropertyChange(POSTAL_CODE, _postalCode, value);
  }
  
}

valueOrDefault(value, defaultGetter){
  if(value != null){
    return value;
  }
  return defaultGetter();
}