library everyday.rpc.everyday_rpc_entity_manager;

import 'dart:async';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'entity_manager.dart';
import '../mirrors/mirrors.dart';
import '../patch/patch.dart';
import '../rpc/invoker.dart';

final Logger _logger = new Logger('everyday.entity.everyday_rpc_entity_manager');

const Duration _DEFAULT_TIMEOUT = const Duration(seconds: 1);

class _EntityEntry {

  StreamSubscription _sub;
  Map<String, ObjectPatchRecord> _unsaved = new Map();
  String _type;
  Invoker _invoker;
  Entity _entity;
  String _endpoint;
  
  _EntityEntry(this._endpoint, this._type, this._entity, this._invoker){
    var obs = new ObjectPatchObserver(_entity);
    obs.changes.listen((records){
      print('model changed $records');
      for(var r in records){
        _unsaved[r.path] = r;
       }
    });
  }
  
  Future save({Duration timeout : _DEFAULT_TIMEOUT}){
    var completer = new Completer();
    var submit = _unsaved;
    _unsaved = new Map();
    _logger.finest('save submitting $submit ');
    _invoker.call(_endpoint, 'save', InvocationType.INVOKE, positional:[_type, _entity.key, submit.values.toList()], timeout:timeout).then((_){
      _entity.key = _;
      completer.complete(this);
    }).catchError((e){
      submit.addAll(_unsaved);
      _unsaved = submit;
      completer.completeError(e);
    });
    return completer.future;
  }
  
  //TODO cancel pending operations
  detach(){
    _sub.cancel();
  }
  
}
//TODO Make an EntityManagerMixin
//TODO Support offline scenarios & synchronization
//TODO Handle concurrency (lock-based & non-lockbased)
@CustomTag('everyday-rpc-entity-manager')
class EverydayRpcEntityManager extends PolymerElement with ChangeNotifierMixin 
implements EntityManager {
  
  static const Symbol INVOKER = const Symbol('invoker');
  static const Symbol ENDPOINT = const Symbol('endpoint');
  
  Invoker _invoker;
  
  String _endpoint;
  
  Map<Entity, _EntityEntry> _observedEntities = {};
  
  Invoker get invoker => _invoker;
  
  set invoker(Invoker value){
    _invoker = this.notifyPropertyChange(INVOKER, _invoker, value);
  }
  
  String get endpoint => _endpoint;
  
  set endpoint(String value){
    _endpoint = this.notifyPropertyChange(ENDPOINT, _endpoint, value);
  }
  
  inserted(){
   

    
    _configure();
    
    this.changes.listen(_propertyChanged);
    
  }
  
  removed(){
    _unconfigure();
  }
  
  Future<Stream<Entity>> findByKey(Type type, List keys, {Duration timeout}) {
      return namedQuery('findByKey',type, {'keys': keys}, timeout:timeout);
  }
  
  Future<Stream<Entity>> namedQuery(String name, Type type, Map params, {Duration timeout}) {
    var completer = new Completer();
    invoker.call(_endpoint, 'findById',
        InvocationType.INVOKE).then(
            (results){
              StreamController resultStream = new StreamController.broadcast();
              results.forEach((result){
                _attach(reflectClass(type).simpleName, result);
                resultStream.add(result);
              });
            }).catchError((e) {
              completer.completeError(e);
            });
    return completer.future;
  }

  Future<Entity> save(Entity entity,{Duration timeout}) {
    var entry = _observedEntities[entity];
    if(entry == null){
      entry = _attach(reflect(entity).type.simpleName, entity);
    }
    return entry.save(timeout:timeout);
  }
  
  _attach(Symbol type, Entity entity){
    var entry = new _EntityEntry(endpoint, convertSymbolToString(type), entity,invoker);
    _observedEntities[entity] = entry;
    return entry;
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
    return false; 
  }
  
  _configure(){
    
  }
  
  _unconfigure(){
    _detachEntities();
  }
  
  _detachEntities(){
    //TODO Decide what to do with incomplete operations
    _observedEntities.values.forEach((entity){
      entity.detach();
    });
    _observedEntities.clear();
  }
  
  detach(Entity entity) {
    _observedEntities.remove(entity).detach();
  }
}