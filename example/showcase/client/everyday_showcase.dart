// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.client.everyday_showcase;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/client/places/places.dart';
import 'package:everyday_dart/shared/user/user.dart';

import '../shared/model.dart';

import 'places.dart';

@CustomTag('everyday-showcase')
class EverydayShowcase extends PolymerElement {
  
  static final Logger _LOGGER = new Logger('everyday.showcase.everyday_showcase');
  
  Type profileType = Profile;
  
  @observable
  var _profilePersist;
  
  @observable
  var _profileObserver;
  
  @observable
  var profile;
  
  final ObservableBox<Place> place = new ObservableBox<Place>();

  @observable 
  bool displayUserAccess = true;
  
  @observable 
  bool displayMain = false;
  
  @observable
  bool isProfilesPlace = true;
  
  @observable
  bool isProfilePlace = false;
  
  @observable
  List profiles;
  
  @observable
  AuthToken token = new EmailPasswordToken('email','password');
  
  @observable
  bool online = false;
  
  @observable
  int profileKey;
  
  @observable
  List profileBuffer = [];

  List profileChanged = [];
  
  Timer _logTimer;

  StringBuffer _logBuffer = new StringBuffer();
  
  final PlacesTransformer placesTransformer = new PlacesTransformer([new ProfilesPlaceTransformer(), new ProfilePlaceTransformer()]);
  
  EverydayShowcase.created(): super.created();
  
  enteredView(){
    
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen(_logToConsole);
    
    _logTimer = new Timer.periodic(new Duration(seconds:1),(timer){
      if(_logBuffer.isNotEmpty){
        print(_logBuffer.toString());
        _logBuffer.clear();
      }
    });
    
    super.enteredView();
    
    _bindPlaces();
    
    place.value = new ProfilesPlace();
    
    Observable.dirtyCheck();   
   
  } 
  
  leftView(){
    _logTimer.cancel();
  }
  
  _bindPlaces(){
    onPropertyChange(place, #value,(){
      isProfilePlace = place.value is ProfilePlace;
      isProfilesPlace = place.value is ProfilesPlace;
      if(isProfilePlace){
        profileKey = place.value.key;
        profileBuffer = [];
      }
      Observable.dirtyCheck();
    });
  }
  
  profileLoaded(event,  detail, target){
    _LOGGER.info('Profile loaded');
    profile = target.entity; 
    profileKey = target.entity.key;
  
    Observable.dirtyCheck();
  }
  
  profileNotLoaded(event,  detail, target){
    _LOGGER.info('Profile not loaded [$detail]');
    profile = target.xtag.entity; 
    Observable.dirtyCheck();
  }
  
  profilesLoaded(event,  detail, target){
    _LOGGER.info('Profiles loaded');
    profiles = target.xtag.results; 
    profile = null;
    Observable.dirtyCheck();
  }
  
  profilesNotLoaded(event,  detail, target){
    _LOGGER.info('Profiles not loaded [$detail]');
    Observable.dirtyCheck();
  }
  
  persistProfile(event, detail, target){
    _LOGGER.info('Persisting profile');

    profileChanged = profileBuffer;
    profileBuffer = new List();
    
    this.shadowRoot.querySelector('#profile-persist').changed = profileChanged;
    this.shadowRoot.querySelector('#profile-observer').changed = profileBuffer;

    Observable.dirtyCheck();
  }
  
  addProfile(event){
    place.value = new ProfilePlace.newProfile();
    Observable.dirtyCheck();
  }
  
  editProfile(event){
    place.value = new ProfilePlace(int.parse(event.target.attributes['profileKey']));
    Observable.dirtyCheck();
  }
  
  profilePersisted(event, detail, target){
    profile.key = detail;
    profileKey = detail;
    _LOGGER.info('Profile persisted');
  }
  
  profileNotPersisted(event, detail, target){
    _LOGGER.info('Profile not persisted [$detail]');
  }
  
  socketError(event, detail, target){
    _LOGGER.warning('Socket generated an error');
  }
  
  authenticationFailed(event, detail, source){
    _LOGGER.info('Unable to authenticate user');
  }
  
  signedIn(event, detail, source){
    _LOGGER.info('Signed in');
    displayUserAccess = false;
    displayMain = true;
    Observable.dirtyCheck();
  }
  
  authenticationSucceeded(event, detail, source){
    _LOGGER.info('User authenticated');
  }
  
  setOffline(event, detail, source){
    _LOGGER.info('Server has gone offline');
    online = false;
    Observable.dirtyCheck();
  }
  
  setOnline(event, detail, source){
    _LOGGER.info('Server has come online');
    online = true;
    Observable.dirtyCheck();
  }
  
  _logToConsole(LogRecord lr){
    if(lr.loggerName.startsWith('polymer')) return;
    var json = new Map();
    json['time'] = lr.time.toLocal().toString();
    json['logger'] = lr.loggerName;
    json['level'] = lr.level.name;
    json['message'] = lr.message;
    if(lr.error != null){
      json['error'] = lr.error;
    }
    _logBuffer.writeln(json);
  }
  
}



