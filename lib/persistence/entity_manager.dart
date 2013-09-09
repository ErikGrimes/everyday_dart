library everyday.persistence.entity_manager;

import 'dart:async';
import 'package:observe/observe.dart';
import '../patch/patch.dart';

abstract class Entity implements Observable {
  var key;
}

abstract class EntityManager {
  
  Future<Stream<Entity>> findByKey(Type type, List keys, {Duration timeout});
  
  Future<Stream> namedQuery(String name, Type type, Map params, {Duration timeout});
  
  Future<Entity> persist(Type type, var key, List<ObjectPatchRecord> changes, {Duration timeout});
   
}
