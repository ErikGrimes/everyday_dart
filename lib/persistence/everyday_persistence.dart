// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.persistence;

import 'dart:async';
import 'dart:html';
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'entity_manager.dart';

@CustomTag('everyday-persistence')
//TODO Think through how to behave when someone changes modelManager
class EverydayPersistence extends PolymerElement with ChangeNotifierMixin {
  
  static const Symbol ENTITY_KEY = const Symbol('entityKey');
  static const Symbol ENTITY_TYPE = const Symbol('entityType');
  static const Symbol ENTITY_MANAGER= const Symbol('entityManager');
  
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('everyday-load');
  static const EventStreamProvider<Event> loadErrorEvent = const EventStreamProvider<Event>('everyday-load-error');
  static const EventStreamProvider<Event> persistEvent = const EventStreamProvider<Event>('everyday-persist');
  static const EventStreamProvider<Event> persistErrorEvent = const EventStreamProvider<Event>('everyday-persist-error');
   
  bool _changedWhilePending = false;
  
  StreamSubscription _selfSub;
  var _entityKey;
  Type _entityType;
  Entity _entity;
  Future _pendingPersist;
  EntityManager _entityManager;
  Map _subs = {};
  
  int get modelKey => _entityKey;
  
  set modelKey(var value){
    _detachEntity();
    _entityKey = this.notifyPropertyChange(ENTITY_KEY, _entityKey, value);
  }
  
  Type get entityType => _entityType;
  
  set entityType(Type value){
    _detachEntity();
    _entityType = this.notifyPropertyChange(ENTITY_TYPE, _entityType, value);
  }
  
  Entity get entity => _entity;

  EntityManager get entityManager => _entityManager;
  
  set entityManager(EntityManager value){
    _detachEntity();
    _entityManager = this.notifyPropertyChange(ENTITY_MANAGER, _entityManager, value);
  }

  Stream<Event> get onLoad => loadEvent.forElement(this);
  
  Stream<Event> get onLoadError => loadErrorEvent.forElement(this);
  
  Stream<Event> get onPersist => persistEvent.forElement(this);
  
  Stream<Event> get onPersistError => persistErrorEvent.forElement(this);
  
  // simulate declarative custom event binding
  var _onEverydayLoad_;
  var _onEverydayLoadError_;
  var _onEverydayPersist_;
  var _onEverydayPersistError_;
  
  get onEverydayLoad_ => _onEverydayLoad_;
  
  set onEverydayLoad_(value){
    _onEverydayLoad_ = _replaceHandler('load', onLoad, value);
  }
  
  get onEverydayError_ => _onEverydayLoad_;
  
  set onEverydayError_(value){
    _onEverydayLoadError_ = _replaceHandler('load-error', onLoadError, value);
  }
  
  set onEverydayPersist_(value){
    _onEverydayPersist_ = _replaceHandler('persist', onPersist, value);
  }
  
  get onEverydayPersistError_ => _onEverydayPersistError_;
  
  set onEverydayPersistError_(value){
    _onEverydayPersistError_ = _replaceHandler('persist-error', onPersistError, value);
  }
  
  _replaceHandler(key, stream, handler){
    var sub = _subs.remove(key);
    if(sub != null){
      sub.cancel();
    }
    if(handler != null){
      _subs[key] = stream.listen((e){
        handler([e, null, this.host]);
      });
    }
  }
  
  inserted(){
    _configure(); 
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  removed(){
    _detachEntity();
    _selfSub.cancel();
  }
  
  persist(){
    _entity.deliverChanges();
    if(_pendingPersist != null){
      _changedWhilePending = true;
    }else {
      _persist();
    }
  }
  
  _propertyChanged(List<ChangeRecord> records){
    for(var cr in records){
      if(_changeRequiresReconfigure(cr)){
        _unconfigure();
        _configure();
        break;
      }
    }
  }
  
  _changeRequiresReconfigure(cr){
    return cr.field == ENTITY_KEY || cr.field == ENTITY_TYPE || cr.field == ENTITY_MANAGER;
  }
  
  _unconfigure(){
    _detachEntity();
  }
  
  _configure(){
    if(_requiredAttributesSet){
      if(_entityKey != null){
        entityManager.findByKey(_entityType, [_entityKey]).then((results){
          results.toList().then((list){
            if(list.isNotEmpty){
              _entity = list[0];
              this.dispatchEvent(new CustomEvent('everyday-load'));         
            }
          });
        }, 
          onError:(error){
            this.dispatchEvent(new CustomEvent('everyday-load-error'));
        });
      } else {
        _entity = reflectClass(_entityType).newInstance(const Symbol(''), []).reflectee;
        this.dispatchEvent(new CustomEvent('everyday-load'));
      }
    }
  }
  
  _detachEntity(){
    if(_entity != null && _entityManager != null){
      _entityManager.detach(_entity);
      _entity = null;
    }
  }
  
  _persist(){
    _pendingPersist = _entityManager.save(_entity);
    _pendingPersist.then((_){
      if(_changedWhilePending){
        _changedWhilePending = false;
        _persist();
      }else {
        _pendingPersist = null;
        this.dispatchEvent(new CustomEvent('everyday-persist'));
      }
    }).catchError((e){
      _pendingPersist = null;
      this.dispatchEvent(new CustomEvent('everyday-persist-error'));
    });
  }
  
  get _requiredAttributesSet => entityManager != null && entityType != null;
  
}
