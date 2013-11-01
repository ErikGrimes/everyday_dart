// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_persistence_find_by_key;

import 'dart:async';
import 'dart:mirrors';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/shared/mirrors/mirrors.dart';

import 'package:everyday_dart/client/mixins.dart';

@CustomTag('everyday-persistence-find-by-key')
class EverydayPersistenceFindByKey extends PolymerElement 
with AsynchronousEventsMixin {
  
  @published
  bool createIfAbsent = true;
  
  @published
  bool auto = true;

  @published
  var entityKey;
  
  @published
  Type entityType;
  
  @published
  Entity entity;
  
  @published
  EntityManager entityManager;

  EverydayPersistenceFindByKey.created() : super.created();
  
  Timer _autoGoJob;
  
  enteredView(){
    
    super.enteredView();
   
    _autoGo();
    
  }
  
  _autoGo(){
    if(!auto) return;
    if(this._autoGoJob != null) return;
   _autoGoJob = new Timer(Duration.ZERO, go);
  }
  
  
  entityKeyChanged(old){
    _autoGo();
  }
  
  entityTypeChanged(old){
    _autoGo();
  }
  
  entityManagerChanged(old){
    _autoGo();
  }
  
  autoChanged(old){
    _autoGo();
  }
  
  createIfAbsentChanged(old){
    _autoGo();
  }
  

  
  go(){
    _autoGoJob = null;
    if(_requiredAttributesSet){
      if(entityKey != null){
        entityManager.findByKey(convertSymbolToString(reflectClass(entityType).simpleName), entityKey).then((result){
            entity = result;
            this.dispatchSuccess(entity);
            Observable.dirtyCheck();
        }).catchError((error){
            this.dispatchError(error);
        });
      } else if(createIfAbsent) {
        entity = reflectClass(entityType).newInstance(const Symbol(''), []).reflectee;
        this.dispatchSuccess(entity);
        Observable.dirtyCheck();
      } else {
        this.dispatchError(new EntityNotFoundException(entityKey));
      }
    }
  }
  
  get _requiredAttributesSet => entityManager != null && entityType != null;
  
}
