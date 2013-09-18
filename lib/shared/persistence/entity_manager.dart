// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.persistence.entity_manager;

import 'dart:async';

import 'package:observe/observe.dart';

import '../patch/patch.dart';


class EntityNotFoundException implements Exception {
  final message;
  EntityNotFoundException(key): message = 'Entity matching [${key.toString()}] not found';
}

abstract class Entity implements Observable {
  var key;
}

abstract class EntityManager {
  
  Future<Entity> findByKey(String type, key, {Duration timeout});
  
  Future<List<Entity>> findByKeys(String type, List keys, {Duration timeout});
  
  Future<List<Entity>> findAll(String type, {Duration timeout});
  
  Future namedQuery(String name, String type, {Map params, Duration timeout});
  
  Future persist(String type, var key, List<ObjectPatchRecord> changes, {Duration timeout});
   
}
