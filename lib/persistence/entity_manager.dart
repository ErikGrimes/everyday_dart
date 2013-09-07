library everyday.model.entity_manager;

import 'dart:async';
import 'package:observe/observe.dart';

abstract class Entity implements Observable {
  var key;
}

abstract class EntityManager {
  
  Future<Stream<Entity>> findByKey(Type type, List keys, {Duration timeout});
  
  Future<Stream> namedQuery(String name, Type type, Map params, {Duration timeout});
  
  Future<Entity> save(Entity model, {Duration timeout});
  
  detach(Entity model);
  
}
