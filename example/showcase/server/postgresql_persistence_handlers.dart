// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.persistence_handlers;

import 'dart:async';
import 'dart:convert';

import 'package:everyday_dart/shared/persistence/entity_manager.dart';
import 'package:everyday_dart/server/persistence/postgresql_entity_manager.dart';
import 'package:everyday_dart/shared/patch/patch.dart';
import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart';

import '../shared/model.dart';

class ProfileConverterTransformer extends StreamEventTransformer {
  
  final Converter _converter;
  
  ProfileConverterTransformer(this._converter);
  
  handleData(row, sink){
    sink.add(_converter.convert(row[1]));
  }
  
}

class ProfileEntityHandler extends Object implements PostgresqlEntityHandler {
 
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
      where id 
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
  
  static final Logger _LOGGER = new Logger('everyday.showcase.postgresql_persistence_handlers.profile_entity_handler');
  
  Codec _codec;
  
  ProfileEntityHandler(this._codec);

  Future<List<Entity>> findAll(Connection connection) {
    return connection.query(FIND_ALL_PROFILES).transform(new ProfileConverterTransformer(_codec.decoder)).toList();
  }

  Future<Entity> findByKey(key, Connection connection) {
    var completer = new Completer();
    connection.query(FIND_PROFILE_BY_ID,{'id':key}).transform(new ProfileConverterTransformer(_codec.decoder)).toList().then((list){
      if(list.isNotEmpty){
        completer.complete(list[0]);
      }else {
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<List<Entity>> findByKeys(List keys, Connection connection) {
    return connection.query(appendInSql(FIND_PROFILES_BY_ID, keys.length),keys).transform(new ProfileConverterTransformer(_codec.decoder)).toList();
  }

  Future<Entity> insert(List<ObjectPatchRecord> changes, Connection connection) {
    var completer = new Completer();
    generateSequenceId('profile_sequence', connection).then((id){
      _LOGGER.finest('Inserting profile [$id]');
      var profile = new Profile(key:id);    
      connection.execute(INSERT_PROFILE,{'id': profile.key,'data':_codec.encode(profile)}).then((_){
        completer.complete(profile);
      }).catchError((error){
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future namedQuery(String name, Map params, Connection connection) {
    return new Future.value(new ArgumentError('No query named $name'));
  }

  Future update(Entity profile, List<ObjectPatchRecord> changes, Connection connection) {
    var completer = new Completer();
    connection.execute(UPDATE_PROFILE,{'id': profile.key,'data':_codec.encode(profile)}).then((_){
      completer.complete(profile);
    }).catchError((error){
      completer.completeError(error);
    });
    return completer.future;
  }
}

