// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_persistence_persist;

import 'dart:async';
import 'dart:mirrors';

import 'package:polymer/polymer.dart';

import '../polymer/polyfills.dart';
import '../../shared/persistence/entity_manager.dart';
import '../../shared/mirrors/mirrors.dart';

@CustomTag('everyday-persistence-persist')
class EverydayPersistencePersist extends PolymerElement with 
  ObservableMixin, CustomEventsMixin, AsynchronousEventsMixin {
  
  static int nextId = 0;
  
  static const Symbol ENTITY_MANAGER = const Symbol('entityManager');
  static const Symbol CHANGED = const Symbol('changed');
  
  StreamSubscription _selfSub;
  
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds: 1);
  
  @observable
  int timeout;
  
  @observable
  List changed = [];
  
  @observable 
  Type entityType;
  
  @observable 
  var entityKey;
  
  @observable
  EntityManager entityManager;
  
  List _unsaved = [];
  
  Future _pending;
  
  bool _changedWhilePending = false;
  

 
  inserted(){ 
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  removed(){
    _selfSub.cancel();
  }
  
  _propertyChanged(List records){
    for(var cr in records){
      if(_isChanged(cr)){
        go();
      }
    }  
  }
  
  go(){
    if(_attributesSet){
      if(_pending != null){
        _changedWhilePending = true;
      }else {
        _persist();
      }
    }
  }
  
  _isChanged(cr){
    return cr.field == CHANGED;
  }
  
  _persist(){
    //TODO compact changes targeting the same path
    _unsaved.addAll(changed);
    var submit = _unsaved;
    _unsaved = new List();
    _pending = entityManager.persist(convertSymbolToString(reflectClass(entityType).simpleName), entityKey, submit);
    
    _pending.then((_){
      if(_changedWhilePending){
        _changedWhilePending = false;
        _persist();
      }else {
        _pending = null;
      }
      this.dispatchSuccess(_);
    }).catchError((error){
      submit.addAll(_unsaved);
      _unsaved = submit;
      _pending = null;
      this.dispatchError(error);
    });
  }
  
  
  get _attributesSet => entityType != null && entityManager != null;
  
 
}