// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.everyday_persistence_load;

import 'dart:async';
import 'dart:html';
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import '../polymer/polyfills.dart';
import 'entity_manager.dart';
import '../mirrors/mirrors.dart';

@CustomTag('everyday-persistence-find-all')
class EverydayPersistenceFindAll extends PolymerElement with ObservableMixin, CustomEventsMixin, AsynchronousEventsMixin {
  
  static const Symbol AUTO = const Symbol('auto');
  static const Symbol ENTITY_TYPE = const Symbol('entityType');
  static const Symbol ENTITY_MANAGER= const Symbol('entityManager');
  static const Symbol RESULTS = const Symbol('results');
  
  StreamSubscription _selfSub;
  Map _subs = {};
  
  @observable
  bool auto;
  
  @observable
  Type entityType;
  
  List results;
  
  @observable
  EntityManager entityManager;
  
  inserted(){
    _selfSub = this.changes.listen(_propertyChanged);
    if(auto){
      go();
    }
  }
  
  removed(){
    _selfSub.cancel();
  }
  
  _propertyChanged(List<ChangeRecord> records){
    print(records);
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
    return cr.field == ENTITY_TYPE || cr.field == ENTITY_MANAGER || AUTO;
  }
  
  go(){
    if(_requiredAttributesSet){
      entityManager.findByKey(convertSymbolToString(reflectClass(entityType).simpleName), null).then((results){
        results.toList().then((list){
          if(list.isNotEmpty){
            results = this.notifyPropertyChange(RESULTS, results, list);
            this.dispatchSuccess(results);
          }
        });
      }, 
      onError:(error){
        this.dispatchError(error);
      });
    }
  }
  
  

  get _requiredAttributesSet => entityManager != null && entityType != null;
  
  
}
