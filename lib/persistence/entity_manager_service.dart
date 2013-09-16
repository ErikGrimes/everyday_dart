// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.entity_manager_service;

import 'package:postgresql/postgresql.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'entity_manager.dart';
import '../patch/patch.dart';

import 'dart:async';

const Duration DEFAULT_TIMEOUT = const Duration(seconds:1);

abstract class PostgresqlEntityHandler {
  
  Future<Entity> findByKey(key, Connection connection, {Duration timeout: DEFAULT_TIMEOUT});
  
  Future<List<Entity>> findByKeys(List keys, Connection connection, {Duration timeout: DEFAULT_TIMEOUT});
  
  Future<List<Entity>> findAll(Connection connection, {Duration timeout: DEFAULT_TIMEOUT});

  Future namedQuery(String name, Map params, Connection connection, {Duration timeout: DEFAULT_TIMEOUT});

  Future persist(var key, List<ObjectPatchRecord> changes, Connection connection, {Duration timeout: DEFAULT_TIMEOUT});
  
}

class PostgresqlEntityManagerService implements EntityManager {
  
  Pool _pool;
  
  Map<String, PostgresqlEntityHandler> _handlers;
  
  PostgresqlEntityManagerService(this._pool, this._handlers);
  
  Future<Entity> findByKey(String type, key, {Duration timeout: DEFAULT_TIMEOUT}) {
    var completer = new Completer();
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.findByKey(key, connection, timeout: timeout)
         .then((value){
           completer.complete(value);
         }).catchError((error) {
           completer.completeError(error);
         })
           .whenComplete((){
              connection.close();  
           });
    }).catchError((error){
      completer.completeError(error);
    });
    return completer.future;
  }

  Future namedQuery(String name, String type, {Map params, Duration timeout: DEFAULT_TIMEOUT}) {
    var completer = new Completer();
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.namedQuery(name, params, connection, timeout: timeout);}).then((key)
           {
              completer.complete(key);         
           }).catchError((error){
        completer.completeError(error);
      }).catchError((error) {
        completer.completeError(error);
      });
    return completer.future;
  }

  Future persist(String type, key, List<ObjectPatchRecord> changes, {Duration timeout: DEFAULT_TIMEOUT}) {
    var completer = new Completer();
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
      handler.persist(key, changes, connection, timeout: timeout).then((key){
        completer.complete(key);
      }).catchError((error){
        completer.completeError(error);
      }).whenComplete((){
        connection.close();
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<List<Entity>> findAll(String type, {Duration timeout}) {
    var completer = new Completer();
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.findAll(connection, timeout: timeout)
         .then((value){
           completer.complete(value);
         }).catchError((error) {
           completer.completeError(error);
         })
           .whenComplete((){
              connection.close();  
           });
    }).catchError((error){
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<List<Entity>> findByKeys(String type, List keys, {Duration timeout}) {
    var completer = new Completer();
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.findByKeys(keys, connection, timeout: timeout)
         .then((value){
           completer.complete(value);
         }).catchError((error) {
           completer.completeError(error);
         })
           .whenComplete((){
              connection.close();  
           });
    }).catchError((error){
      completer.completeError(error);
    });
    return completer.future;
  }
}

abstract class PostgresqlIdGeneratorMixin {
  Future generateId(String type, Connection c){
    var completer = new Completer();
    c.query('select nextval(\'$type\')').listen((rows){
      completer.complete(rows[0]);
    }, onError: (e){
      completer.completeError(e);
    });
    return completer.future;
  }
}