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
class EverydayShowcase extends PolymerElement with ObservableMixin {
  
  static final Logger _LOGGER = new Logger('everyday.showcase.everyday_showcase');
  
  Type profileType = Profile;
  
  @observable
  EntityManager showcaseEntityManager;
  
  @observable
  var showcaseCodec;
  
  @observable
  var showcaseSocket;
  
  @observable
  var showcaseRpc;
  
  @observable
  var profilePersist;
  
  @observable
  var profileObserver;
  
  @observable
  var showcaseUserService;
  
  @observable
  Entity profile;
  
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
  
  inserted(){
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_logToConsole);
    
    super.inserted();
    
    // polyfill automatic attribute finding & binding
    _polyfillBinding();
    
    _bindPlaces();
    
    place.value = new ProfilesPlace();
    
    Observable.dirtyCheck();
  } 
  
  _polyfillBinding(){

    showcaseRpc = this.shadowRoot.query('#showcase-rpc').xtag;
    showcaseCodec = this.shadowRoot.query('#showcase-codec').xtag;
    showcaseSocket = this.shadowRoot.query('#showcase-socket').xtag;
    showcaseEntityManager = this.shadowRoot.query('#showcase-entity-manager').xtag;

    showcaseRpc.codec = showcaseCodec;
    showcaseRpc.socket = showcaseSocket;
    showcaseEntityManager.invoker = showcaseRpc;
    showcaseUserService = this.shadowRoot.query('#showcase-user-service').xtag;
    showcaseUserService.invoker = showcaseRpc;
    
    showcaseSocket.onOnline.listen((data){
      setOnline();
    });
    
    showcaseSocket.onOffline.listen((data){
      setOffline();
    });
  }
  
  _bindPlaces(){
    bindProperty(place, const Symbol('value'),(){
      isProfilePlace = place.value is ProfilePlace;
      isProfilesPlace = place.value is ProfilesPlace;
      Observable.dirtyCheck();
    });
  }
  
  profileLoaded(event,  detail, target){
    _LOGGER.info('Profile loaded');
    profile = target.xtag.entity; 
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
    Observable.dirtyCheck();
  }
  
  persistProfile(event, detail, target){
    _LOGGER.info('Persisting profile');

    if(profilePersist == null){
      profilePersist = this.shadowRoot.query('#profile-persist').xtag;
    }
    if(profileObserver == null){
      profileObserver = this.shadowRoot.query('#profile-observer').xtag;
    }
    profileChanged = profileBuffer;
    profileBuffer = new List();
    profilePersist.changed = profileChanged;
    profileObserver.changed = profileBuffer;
    Observable.dirtyCheck();
  }
  
  addProfile(event){
    place.value = new ProfilePlace.newProfile();
    Observable.dirtyCheck();
  }
  
  profilePersisted(event, detail, target){
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
  
  setOffline(){
    _LOGGER.info('Server has gone offline');
    online = false;
    Observable.dirtyCheck();
  }
  
  setOnline(){
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

