library everyday.persistence.entity_manager;

import 'dart:async';
import 'package:observe/observe.dart';
import '../patch/patch.dart';

abstract class Entity implements Observable {
  var key;
}

abstract class EntityManager {
  
  Future<List<Entity>> findByKey(String type, List keys, {Duration timeout});
  
  Future namedQuery(String name, String type, Map params, {Duration timeout});
  
  Future persist(String type, var key, List<ObjectPatchRecord> changes, {Duration timeout});
   
}
