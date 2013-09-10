// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.patch.everyday_patch_observer;

import 'dart:async';
import 'package:polymer/polymer.dart';
import '../polymer/polyfills.dart';
import '../patch/patch.dart';
import 'entity_manager.dart';

@CustomTag('everyday-persistence-persist')
class EverydayPersistencePersist extends PolymerElement with 
  ObservableMixin, CustomEventsMixin, AsynchronousEventsMixin {
  
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
  
  Future _pendingSave;
  
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
      if(_pendingSave != null){
        _changedWhilePending = true;
      }else {
        _save();
      }
    }
  }
  
  _changed(){
    _unsaved.addAll(changed);
    if(_pendingSave != null){
      _changedWhilePending = true;
    }else {
      _save();
    }
  }
  
  _isChanged(cr){
    return cr.field == CHANGED;
  }
  
  _save(){
    var submit = _unsaved;
    _unsaved = new List();
    _pendingSave = entityManager.persist(entityType, entityKey, submit);
    
    _pendingSave.then((_){
      if(_changedWhilePending){
        _changedWhilePending = false;
        _save();
      }else {
        _pendingSave = null;
      }
      this.dispatchSuccess(_);
    }).catchError((error){
      submit.addAll(_unsaved);
      _unsaved = submit;
      _pendingSave = null;
      this.dispatchError(error);
    });
  }
  
  
  get _attributesSet => entityType != null && entityManager != null;
  
 
}