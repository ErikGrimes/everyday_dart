// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_persistence_persist;

import 'dart:async';
import 'dart:mirrors';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/shared/patch/patch.dart';

import 'package:everyday_dart/client/mixins.dart';

@CustomTag('everyday-persistence-persist')
class EverydayPersistencePersist extends PolymerElement with AsynchronousEventsMixin {
  
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds: 1);
  
  @published
  bool auto = false;
  
  @published
  int timeout;
  
  @published
  List changed = [];
  
  @published 
  Type entityType;
  
  @published 
  var entityKey;
  
  @published
  EntityManager entityManager;
  
  List _unsaved = [];
  
  Future _pending;
  
  bool _changedWhilePending = false;
  
  Timer _autoGoJob;
  
  EverydayPersistencePersist.created() : super.created();
 
  changedChanged(old){
    _autoGo();
  }
  
  _autoGo(){
    if(!auto) return;
    if(_autoGoJob != null) return;
    _autoGoJob = new Timer(Duration.ZERO, go);
  }
  
  go(){
    _autoGoJob = null;
    if(_attributesSet && changed != null && changed.isNotEmpty){
      if(_pending != null){
        _changedWhilePending = true;
      }else {
        _persist();
      }
    }
  }
   
  _persist(){
    
    var summarizer = new Summarizer()..addAll(changed);
    
    _unsaved.addAll(summarizer.summarize());
    
    var submit = _unsaved;
    
    _unsaved = new List();
    _pending = entityManager.persist(MirrorSystem.getName(reflectClass(entityType).simpleName), entityKey, submit);
    
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