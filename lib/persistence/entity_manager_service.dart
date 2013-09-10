// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.entity_manager_service;

import 'package:postgresql/postgresql.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'entity_manager.dart';
import '../patch/patch.dart';

import 'dart:async';

abstract class PostgresqlEntityHandler {
  
  Future<List<Entity>> findByKey(List keys, Connection connection, {Duration timeout});

  Future namedQuery(String name, Map params, Connection connection, {Duration timeout});

  Future persist(var key, List<ObjectPatchRecord> changes, Connection connection, {Duration timeout});
  
}

class PostgresqlEntityManagerService implements EntityManager {
  
  Pool _pool;
  
  Map<String, PostgresqlEntityHandler> _handlers;
  
  PostgresqlEntityManagerService(this._pool, this._handlers);
  
  Future<List<Entity>> findByKey(String type, List keys, {Duration timeout}) {
    var handler = [type];
    if(handler == null){
      return new Future.error(new ArgumentError('Unknown type $type'));
    }
    return handler.findByKey(keys, timeout:timeout);
  }

  Future namedQuery(String name, String type, Map params, {Duration timeout}) {
    var handler = [type];
    if(handler == null){
      return new Future.error(new ArgumentError('Unknown type $type'));
    }
    return handler.namedQuery(params, timeout:timeout);
  }

  Future persist(String type, key, List<ObjectPatchRecord> changes, {Duration timeout}) {
    var handler = [type];
    if(handler == null){
      return new Future.error(new ArgumentError('Unknown type $type'));
    }
    return handler.persist(key, changes, timeout:timeout);
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