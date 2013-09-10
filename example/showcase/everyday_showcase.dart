// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/places/places.dart';
import 'package:everyday_dart/aai/shared.dart';
import 'places.dart';
import 'model.dart';

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
  Entity profile;
  
  final ObservableBox<Place> place = new ObservableBox<Place>();
  
  @observable
  bool isProfilesPlace;
  
  @observable
  bool isProfilePlace;
  
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
   
    // simulate automatic attribute finding & binding
    showcaseRpc = this.shadowRoot.query('#showcase-rpc').xtag;
    showcaseCodec = this.shadowRoot.query('#showcase-codec').xtag;
    showcaseSocket = this.shadowRoot.query('#showcase-socket').xtag;
    showcaseEntityManager = this.shadowRoot.query('#showcase-entity-manager').xtag;

    showcaseRpc.codec = showcaseCodec;
    showcaseRpc.socket = showcaseSocket;
    showcaseEntityManager.invoker = showcaseRpc;
    
    showcaseSocket.onOnline.listen((data){
      setOnline();
    });
    
    showcaseSocket.onOffline.listen((data){
      setOffline();
    });
    
    
    
   // this.shadowRoot.query('#auth').xtag.auto=true;
    //profilePersistence = this.shadowRoot.query('#profile-persistence').xtag;
    
    //this.shadowRoot.query('#profile-persistence').xtag.entityManager = showcaseEntityManager;
    
    Observable.dirtyCheck();
  } 
  
  profileLoaded(event,  detail, target){
    _LOGGER.info('Profile loaded');
    profile = target.xtag.entity; 
   // profilePersist = this.shadowRoot.query('#profile-persist').xtag;
   // profileObserver = this.shadowRoot.query('#profile-observer').xtag;
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
    print(identical(profilePersist.changed,profileChanged));
    profilePersist.changed = profileChanged;
    profileObserver.changed = profileBuffer;
    Observable.dirtyCheck();
  }
  
  profilePersisted(event, detail, target){
    _LOGGER.info('Profile persisted');
  }
  
  profileNotPersisted(event, detail, target){
    _LOGGER.info('Profile not persisted');
  }
  
  socketError(event, detail, target){
    _LOGGER.warning('Socket generated an error');
  }
  
  authenticationFailed(event, detail, source){
    _LOGGER.info('Unable to authenticate user');
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
   // print(this.shadowRoot.children);
   // loadProfile.entityManager = showcaseEntityManager;
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

