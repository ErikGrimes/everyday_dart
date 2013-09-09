library everyday.persistence.everyday_rpc_entity_manager;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import '../patch/patch.dart';
import 'entity_manager.dart';
import '../rpc/invoker.dart';

final Logger _logger = new Logger('everyday.entity.everyday_rpc_entity_manager');

const Duration _DEFAULT_TIMEOUT = const Duration(seconds: 1);

@CustomTag('everyday-rpc-entity-manager')
class EverydayRpcEntityManager extends PolymerElement with ObservableMixin 
implements EntityManager {
  
  static const Symbol INVOKER = const Symbol('invoker');
  static const Symbol ENDPOINT = const Symbol('endpoint');
  
  static const String DEFAULT_ENDPOINT = 'entity-manager';
  
  @observable
  String endpoint = DEFAULT_ENDPOINT;
  
  @observable
  Invoker invoker;
  
  inserted(){
    
    this.changes.listen(_propertyChanged);
    
  }
  
  removed(){
  
  }
  
  Future<Stream<Entity>> findByKey(Type type, List keys, {Duration timeout}) {
      return namedQuery('findByKey',type, {'keys': keys}, timeout:timeout);
  }
  
  Future<Stream<Entity>> namedQuery(String name, Type type, Map params, {Duration timeout}) {
    var completer = new Completer();
    invoker.call(endpoint, 'findById',
        InvocationType.INVOKE).then(
            (results){
              StreamController resultStream = new StreamController.broadcast();
              results.forEach((result){
                resultStream.add(result);
              });
            }).catchError((e) {
              completer.completeError(e);
            });
    return completer.future;
  }

  Future persist(Type type, var key, List<ObjectPatchRecord> changes, {Duration timeout}) {
    var completer = new Completer();
    _logger.finest('persist submitting $changes ');
    invoker.call(endpoint, 'persist', InvocationType.INVOKE, positional:[type, key, changes], timeout:timeout).then((_){
      completer.complete(key);
    }).catchError((e){
      completer.completeError(e);
    });
    return completer.future;
  }
  
  _propertyChanged(List<ChangeRecord> records){
    

  }
  
}