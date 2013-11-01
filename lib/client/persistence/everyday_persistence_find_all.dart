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
  
  @published
  bool auto;
  
  @published
  Type entityType;
  
  @published
  List results;
  
  @published
  EntityManager entityManager;
  
  Timer _autoGoJob;
  
  EverydayPersistenceFindAll.created() : super.created();
  
  enteredView(){
    
    super.enteredView();
    
    _autoGo();
  }
  
  
  autoChanged(old){
    _autoGo();
  }
  
  entityManagerChanged(old){
    _autoGo();  
  }
  
  entityTypeChanged(old){
    _autoGo();
  }
  
  _autoGo(){
    if(!auto) return;
    if(this._autoGoJob != null) return;
   _autoGoJob = new Timer(Duration.ZERO, go);
  }
  
  go(){
    _autoGoJob = null;
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
