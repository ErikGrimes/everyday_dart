// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.client.everyday_showcase;

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
  var entityManager;
  
  @observable
  var codec;
  
  @observable
  var socket;
  
  @observable
  var rpc;
  
  @observable
  var _profilePersist;
  
  @observable
  var _profileObserver;
  
  @observable
  var userService;
  
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
  var profileKey;
  
  @observable
  List profileBuffer = [];

  List profileChanged = [];
  
  final PlacesTransformer placesTransformer = new PlacesTransformer([new ProfilesPlaceTransformer(), new ProfilePlaceTransformer()]);
  
  EverydayShowcase.created(): super.created();
  
  enteredView(){
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_logToConsole);
    
    super.enteredView();
    
    //https://code.google.com/p/dart/issues/detail?id=14172
    _workaroundBug14172();
    
    _bindPlaces();
    
    place.value = new ProfilesPlace();
    
    Observable.dirtyCheck();
    
   
  } 
  
  _workaroundBug14172(){
    rpc = $['rpc'];
    codec = $['codec'];
    socket = $['socket'];
    entityManager = $['entity-manager'];
    userService = $['user-service'];
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
    profile = target.xtag.entity; 
    profileKey = target.xtag.entity.key;
  
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
    
    this.shadowRoot.query('#profile-persist').xtag.changed = profileChanged;
    this.shadowRoot.query('#profile-observer').xtag.changed = profileBuffer;

    Observable.dirtyCheck();
  }
  
  addProfile(event){
    place.value = new ProfilePlace.newProfile();
    Observable.dirtyCheck();
  }
  
  editProfile(event){
    place.value = new ProfilePlace(event.target.attributes['profile-key']);
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
  
}

_logToConsole(LogRecord lr){
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  if(lr.exception != null){
    json['exception'] = lr.exception;
  }
  print(json);
}

