// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_persistence_find_all;

import 'dart:async';
import 'dart:mirrors';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/shared/mirrors/mirrors.dart';

import 'package:everyday_dart/client/mixins.dart';

@CustomTag('everyday-persistence-find-all')
class EverydayPersistenceFindAll extends PolymerElement with AsynchronousEventsMixin {
  
  static const Symbol AUTO = const Symbol('auto');
  static const Symbol ENTITY_TYPE = const Symbol('entityType');
  static const Symbol ENTITY_MANAGER= const Symbol('entityManager');
  static const Symbol RESULTS = const Symbol('results');
  
  StreamSubscription _selfSub;
  Map _subs = {};
  
  @published
  bool auto;
  
  @published
  Type entityType;
  
  @published
  List results;
  
  @published
  EntityManager entityManager;
  
  EverydayPersistenceFindAll.created() : super.created();
  
  enteredView(){
    if(auto){
      go();
    }
  }
  
  leftView(){
    _selfSub.cancel();
  }
  
  _propertyChanged(List<ChangeRecord> records){
    for(var cr in records){
        if(_isExternallySetProperty(cr)){
          if(auto){
            go();
          }
          break;
      }
    }
  }
  
  _isExternallySetProperty(cr){
    return cr.field == ENTITY_TYPE || cr.field == ENTITY_MANAGER || cr.field == AUTO;
  }
  
  go(){
    if(_requiredAttributesSet){
      entityManager.findAll(convertSymbolToString(reflectClass(entityType).simpleName)).then((results){
        this.results = results;
        this.dispatchSuccess(results);
        Observable.dirtyCheck();
      }).catchError((error){
        this.dispatchError(error);
      });
    }
  }
  
  

  get _requiredAttributesSet => entityManager != null && entityType != null;
  
  
}
