// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.persistence_handlers;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/server/persistence/postgresql_entity_manager.dart';
import 'package:everyday_dart/shared/patch/patch.dart';
import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart';

import '../shared/model.dart';

class ProfileEntityHandler extends Object with PostgresqlIdGeneratorMixin implements PostgresqlEntityHandler {
 
  static const CREATE_PROFILE_SEQUENCE_= 'create sequence profile_sequence;';

  static const String CREATE_PROFILE_TABLE = '''

      create table profile (
      id bigint,
      data text,
      primary key(id)
      );
      ''';

  static const String INSERT_PROFILE= '''
      insert into profile 
      values(@id, @data);
      ''';

  static const UPDATE_PROFILE= '''
      update profile 
      set data = @data
      where id = @id;
      ''';

  static const FIND_PROFILES_BY_ID = '''
      select * 
      from profile 
      where id in
      ''';
  
  static const FIND_PROFILE_BY_ID = '''
      select * 
      from profile 
      where id = @id;
      ''';

  static const FIND_ALL_PROFILES = '''
      select * 
      from profile;
      ''';
  
  static final Logger _LOGGER = new Logger('everyday.showcase.persistence_handlers.profile_entity_handler');
  
  Codec _codec;
  
  Map _cache = new Map();
  
  ProfileEntityHandler(this._codec);
  
  Future<Entity> findByKey(int key, Connection connection, {Duration timeout}) {
    var completer = new Completer();
    var result;
    _LOGGER.finest('Finding profile [$key]');
    try {
      connection.query(FIND_PROFILE_BY_ID,{'id':key}).listen((row){
      _LOGGER.finest('Found profile [$key]');
      result = _codec.decode(row.data);
    }, onDone:(){
      if(!completer.isCompleted){
        completer.complete(result);
      }
    }, onError:(error){
      _LOGGER.finest('Error finding profile [$key]');
      completer.completeError(error);
    });
    }catch(error){
      _LOGGER.finest('Error [$error] finding profile [$key]');
      completer.completeError(error);
    }
    
    return completer.future;
  }
  
  Future namedQuery(String name, Map params, Connection connection, {Duration timeout}) {
    return new Future.value(new ArgumentError('No query named $name'));
  }

  Future persist(key, List<ObjectPatchRecord> changes, Connection connection, {Duration timeout}) {
    var completer = new Completer();
    if(key == null){
      this.generateId('profile_sequence', connection).then((id){
        _LOGGER.finest('Inserting profile [$id]');
        var profile = new Profile(key:id);    
        _updateAndSave(INSERT_PROFILE, changes, profile, connection).then((_){
          _cache[id] = profile;
          completer.complete(id);
        }).catchError((error){
          completer.completeError(error);
        });
      }).catchError((error) {
        completer.completeError(error);
      });
    }else {
      _LOGGER.finest('Updating profile [$key] with changes [$changes]');
      _profileFor(key, connection).then((profile){
        _LOGGER.finest('Found profile [$key]');
        _cache[key] = profile;
        _updateAndSave(UPDATE_PROFILE, changes, profile, connection).then((_){
          completer.complete(key);
        }).catchError((error) {
          completer.completeError(error);
        });
      }).catchError((error){
        completer.completeError(error);
      });
      
    }
    return completer.future;
  }
  
  Future<List<Entity>> findByKeys(keys, connection, {timeout}){
    var completer = new Completer();
    List results = [];
    connection.query(_buildFindByKeysSql(FIND_PROFILES_BY_ID, keys.length),keys).listen((row){
      var profile = _codec.decode(row.data);
      results.add(profile);
    }, onDone:(){
      if(!completer.isCompleted){
        completer.complete(results);
      }
    }, onError:(error){
      completer.completeError(error);
    });
    return completer.future;
  }
  

  
  Future<List<Entity>> findAll(Connection connection, {Duration timeout}) {
    var completer = new Completer();
    List results = [];
    connection.query(FIND_ALL_PROFILES).listen((row){
      var profile = _codec.decode(row.data);
      results.add(profile);
    }, onDone:(){
      completer.complete(results);
    }, onError:(error){
      completer.completeError(error);
    });
    return completer.future;
  }
  
  Future _profileFor(key, connection){
    var profile = _cache[key];
    if(profile != null){
      return new Future.value(profile); 
    }
    _LOGGER.finest('Profile [$key] not in cache');
    return findByKey(key, connection);
  }
  
  Future _updateAndSave(sql, changes, profile, connection){
    changes.forEach((cr){
      cr.apply(profile);
    });

    return connection.execute(sql,{'id': profile.key,'data':_codec.encode(profile)});
    
  }

}

String _buildFindByKeysSql(String sql, int length){
  var buffer = new StringBuffer(sql);
  buffer.write('(');
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