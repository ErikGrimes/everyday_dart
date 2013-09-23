// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.persistence.postgresql_entity_manager;

import 'package:postgresql/postgresql.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'package:logging/logging.dart';

import '../../shared/async/future.dart';
import '../../shared/persistence/entity_manager.dart';
import '../../shared/patch/patch.dart';

import 'dart:async';

const Duration DEFAULT_TIMEOUT = const Duration(seconds:1);

abstract class PostgresqlEntityHandler {
  
  Future<Entity> findByKey(key, Connection connection);
  
  Future<List<Entity>> findByKeys(List keys, Connection connection);
  
  Future<List<Entity>> findAll(Connection connection);

  Future namedQuery(String name, Map params, Connection connection);

  Future<Entity> insert(List<ObjectPatchRecord> changes, Connection connection);
  
  Future update(Entity entity, List<ObjectPatchRecord> changes, Connection connection);
  
}

_cacheKey(String type, var key){
  return type + '_' + key.toString();
}

class PostgresqlEntityManager implements EntityManager {
  
  static final Logger _LOGGER = new Logger('everyday.persistence.postgresql_entity_manager');
  
  Map _cache = new Map();
  
  Pool _pool;
  
  Map<String, PostgresqlEntityHandler> _handlers;
  
  PostgresqlEntityManager(this._pool, this._handlers);
  
  Future<Entity> findByKey(String type, key, {Duration timeout: DEFAULT_TIMEOUT}) {
    
    var entity = _cache[_cacheKey(type,key)];
    
    if(entity != null){
      return new Future.value(entity); 
    }
    
    _LOGGER.finest('Entity [$key] not in cache');
    
    var handler = _handlers[type];
    
    if(handler == null){
     return new Future.error(new ArgumentError('Unknown type $type'));
    }
    
    var completer = new TimedCompleter(timeout);
    
    _pool.connect(timeout.inMilliseconds).then((connection){
      if(!completer.isCompleted){
            handler.findByKey(key, connection).then((value){
              if(value != null){
                _cache[_cacheKey(type, key)] = value;
              }        
            completer.complete(value); 
          }).catchError((error) {  
            completer.completeError(error);
          })
            .whenComplete((){
              connection.close();  
            });
      } else {
        connection.close();
      }
    }).catchError((error){
      completer.completeError(error);
    });
    
    
  }
  
  Future namedQuery(String name, String type, {Map params, Duration timeout: DEFAULT_TIMEOUT}) {
 
    var handler = _handlers[type];
    
    if(handler == null){
      new Future.error(new ArgumentError('Unknown type $type'));
    }

    var completer = new TimedCompleter(timeout);
    
    _pool.connect(timeout.inMilliseconds).then((connection){
      
      if(!completer.isCompleted){
        handler.namedQuery(name, params, connection).then((result){
          if(result is Entity){
            _cache[_cacheKey(type,result.key)] = result;
          }
          if(result is List){
            result.forEach((e){
              if(e is Entity){
                _cache[_cacheKey(type, e.key)] = e;
              }
            });
          }         
          completer.complete(result);
        }).catchError((error) {
          completer.completeError(error);
        }).whenComplete((){
          connection.close();
        });
        
      }else {
        connection.close();
      }
      
      }).catchError((error) {
        completer.completeError(error);
      });
    return completer.future;
  }

  Future persist(String type, key, List<ObjectPatchRecord> changes, {Duration timeout: DEFAULT_TIMEOUT}) {
   
    if(key == null){
      return _insertEntity(type, changes, timeout);
    }else {
      return _updateEntity(type, key, changes, new Duration(days:1));
    }

  }
  
  Future _insertEntity(String type, List<ObjectPatchRecord> changes, Duration timeout){
    var handler = _handlers[type];
    
    if(handler == null){
      new Future.error(new ArgumentError('Unknown type $type'));
    }
    
    var completer = new TimedCompleter(timeout);
    
    _pool.connect(timeout.inMilliseconds).then((connection){
      if(!completer.isCompleted){
       handler.insert(changes, connection).then((result){
          _cache[_cacheKey(type, result.key)] = result;    
          completer.complete(result.key);
        }).catchError((error) {     
          completer.completeError(error);
        }).whenComplete((){
          connection.close();
        });
      }
    }).catchError((error){
      completer.completeError(error);
    });
    
    return completer.future;
  }
  
  Future _updateEntity(String type, key, List<ObjectPatchRecord> changes, Duration timeout){
    var handler = _handlers[type];
    if(handler == null){
      new Future.error(new ArgumentError('Unknown type $type'));
    }
    
    var completer = new TimedCompleter(timeout);
    
    _pool.connect(timeout.inMilliseconds).then((connection){
      
      var loaded;
      
      var entity = _cache[_cacheKey(type, key)];
      
      if(entity != null){
        loaded = new Future.value(entity);
      }else {
        loaded = handler.findByKey(key, connection);
      }
      
      loaded.then((entity){
        
        changes.forEach((cr){
          cr.apply(entity);
        }); 
        
        handler.update(entity, changes, connection).then((_){  
          completer.complete(entity.key); 
        }).catchError((error){ 
          completer.completeError(error);          
        });
        
      }).catchError((error){
        completer.completeError(error);
      }).whenComplete((){
        connection.close();
      });
    }).catchError((error){
      completer.completeError(error);
    });
      
    return completer.future;
  }

  Future<List<Entity>> findAll(String type, {Duration timeout: DEFAULT_TIMEOUT}) {
    var completer = new TimedCompleter(timeout);
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }
    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.findAll(connection)
         .then((results){
           results.forEach((result){
             _cache[_cacheKey(type, result.key)] = result;
           });
           completer.complete(results);
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
    var completer = new TimedCompleter(timeout);
    var handler = _handlers[type];
    if(handler == null){
      completer.completeError(new ArgumentError('Unknown type $type'));
    }

    _pool.connect(timeout.inMilliseconds).then((connection){
       handler.findByKeys(keys, connection)
         .then((results){
           results.forEach((result){
             _cache[_cacheKey(type, result.key)] = result;
           });
           completer.complete(results);
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


Future generateSequenceId(String name, Connection c){
  var completer = new Completer();
  c.query('select nextval(\'$name\')').listen((rows){
    completer.complete(rows[0]);
    }, onError: (e){
      completer.completeError(e);
    });
  return completer.future;
}

String appendInSql(String sql, int length){
  var buffer = new StringBuffer(sql);
  buffer.write('in (');
  buffer.write(_buildInString(length));
  buffer.write(');');
  return buffer.toString();
}

String _buildInString(int length){
  var buffer = new StringBuffer();
  for(int i=0; i< length;i++){
    buffer.write('@');
    buffer.write(i.toString());
    buffer.write(',');
  }
  if(length >0){
    return buffer.toString().substring(0, buffer.length-1);
  }
  return buffer.toString();
}
