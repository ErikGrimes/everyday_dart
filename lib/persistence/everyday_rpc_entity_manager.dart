// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.everyday_rpc_entity_manager;

import 'dart:async';
import 'dart:mirrors';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import '../patch/patch.dart';
import 'entity_manager.dart';
import '../rpc/invoker.dart';
import '../mirrors/mirrors.dart';

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
  
  Future<Stream<Entity>> findByKey(String type, List keys, {Duration timeout}) {
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
  
  Future<Stream<Entity>> namedQuery(String name, String type, Map params, {Duration timeout}) {
    var completer = new Completer();
    invoker.call(endpoint, 'namedQuery',
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

  Future persist(String type, var key, List<ObjectPatchRecord> changes, {Duration timeout}) {
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

typeToString(Type type){
  return convertSymbolToString(reflectClass(type).simpleName);
}