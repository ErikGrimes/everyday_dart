// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_persistence_find_by_key;

import 'dart:async';
import 'dart:html';
import 'dart:mirrors';

import 'package:polymer/polymer.dart';

import '../../shared/persistence/entity_manager.dart';
import '../../shared/mirrors/mirrors.dart';

import '../polymer/polyfills.dart';

@CustomTag('everyday-persistence-find-by-key')
class EverydayPersistenceFindByKey extends PolymerElement 
with ObservableMixin, CustomEventsMixin, AsynchronousEventsMixin {
  
  static const Symbol ENTITY_KEY = const Symbol('entityKey');
  static const Symbol ENTITY_TYPE = const Symbol('entityType');
  static const Symbol ENTITY_MANAGER= const Symbol('entityManager');
  static const Symbol ENTITY = const Symbol('entity');
  static const Symbol NEW_IF_ABSENT = const Symbol('newIfAbsent');
  static const Symbol AUTO = const Symbol('auto');
  
  StreamSubscription _selfSub;
  Map _subs = {};
  
  @observable
  bool newIfAbsent = true;
  
  @observable
  bool auto = true;

  @observable
  var entityKey;
  
  @observable
  Type entityType;
  
  @observable
  Entity entity;
  
  @observable
  EntityManager entityManager;

  inserted(){
    _selfSub = this.changes.listen(_propertyChanged);
    if(auto){
      go();
    }
  }
  
  removed(){
    print('removed');
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
    return cr.field == ENTITY_KEY 
        || cr.field == ENTITY_TYPE 
        || cr.field == ENTITY_MANAGER 
        || cr.field == AUTO 
        || cr.field == NEW_IF_ABSENT;
  }
  
  go(){
    if(_requiredAttributesSet){
      if(entityKey != null){
        entityManager.findByKey(convertSymbolToString(reflectClass(entityType).simpleName), entityKey).then((result){
            entity = result;
            this.dispatchSuccess(entity);
            Observable.dirtyCheck();
        }).catchError((error){
            this.dispatchError(error);
        });
      } else if(newIfAbsent) {
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
