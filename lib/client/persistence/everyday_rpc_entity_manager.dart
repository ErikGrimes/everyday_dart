// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.persistence.everyday_rpc_entity_manager;

import 'dart:async';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/patch/patch.dart';
import 'package:everyday_dart/shared/rpc/invoker.dart';
import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/shared/mirrors/mirrors.dart';

final Logger _LOGGER = new Logger('everyday.entity.everyday_rpc_entity_manager');

const Duration _DEFAULT_TIMEOUT = const Duration(seconds: 1);

@CustomTag('everyday-rpc-entity-manager')
class EverydayRpcEntityManager extends PolymerElement 
implements EntityManager {
  
  static const Symbol INVOKER = const Symbol('invoker');
  static const Symbol ENDPOINT = const Symbol('endpoint');
  
  static const String DEFAULT_ENDPOINT = 'entity-manager';
  
  @published
  String endpoint = DEFAULT_ENDPOINT;
  
  @published
  Invoker invoker;
  
  EverydayRpcEntityManager.created() : super.created();
  
 
  Future<Entity> findByKey(String type, var key, {Duration timeout}) {
    return invoker.call(endpoint, 'findByKey',
        InvocationType.INVOKE, positional:[type, key]);
  }
  
  Future<List<Entity>> findByKeys(String type, List keys, {Duration timeout}) {
    return invoker.call(endpoint, 'findByKeys',
        InvocationType.INVOKE, positional:[keys]);
  }
  
  Future<List<Entity>> findAll(String type, {Duration timeout}) {
    return invoker.call(endpoint, 'findAll',
        InvocationType.INVOKE, positional:[type]);
  }
  
  Future<List<Entity>> namedQuery(String name, String type, {Map params, Duration timeout}) {
    return invoker.call(endpoint, 'namedQuery',
        InvocationType.INVOKE, positional:[name, type], named: {'params': params});
  }

  Future persist(String type, var key, List<ObjectPatchRecord> changes, {Duration timeout}) {
    return invoker.call(endpoint, 'persist', InvocationType.INVOKE, positional:[type, key, changes], timeout:timeout);
  }
  
  
  
}
