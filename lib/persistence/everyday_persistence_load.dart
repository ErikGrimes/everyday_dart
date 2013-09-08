library everyday.persistence.everyday_persistence_load;

import 'dart:async';
import 'dart:html';
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import '../polymer/polyfills.dart';
import 'entity_manager.dart';

@CustomTag('everyday-persistence-load')
class EverydayPersistenceLoad extends PolymerElement with ChangeNotifierMixin, CustomEventsMixin, AsynchronousEventsMixin {
  
  static const Symbol ENTITY_KEY = const Symbol('entityKey');
  static const Symbol ENTITY_TYPE = const Symbol('entityType');
  static const Symbol ENTITY_MANAGER= const Symbol('entityManager');
  static const Symbol ENTITY = const Symbol('entity');
  
  StreamSubscription _selfSub;
  var _entityKey;
  Type _entityType;
  Entity _entity;
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
  
  inserted(){
    _configure(); 
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  removed(){
    _detachEntity();
    _selfSub.cancel();
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
              _entity = this.notifyPropertyChange(ENTITY, _entity, list[0]);
              this.dispatchSuccess(_entity);
            }
          });
        }, 
          onError:(error){
            this.dispatchError(error);
        });
      } else {
        _entity = this.notifyPropertyChange(ENTITY, _entity, 
            reflectClass(_entityType).newInstance(const Symbol(''), []).reflectee);
        this.dispatchSuccess(_entity);
      }
    }
  }
  
  _detachEntity(){
    if(_entity != null && _entityManager != null){
      _entityManager.detach(_entity);
      _entity = null;
    }
  }
  
  get _requiredAttributesSet => entityManager != null && entityType != null;
  
}
