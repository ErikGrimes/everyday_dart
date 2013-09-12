import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:everyday_dart/rpc/server.dart';
import 'package:logging/logging.dart';
import 'package:everyday_dart/aai/aai_service.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'package:everyday_dart/persistence/entity_manager_service.dart';
import 'package:everyday_dart/isolate/isolate.dart';
import 'package:everyday_dart/async/stream.dart';

import '../../example/showcase/persistence_handlers.dart';
import '../../example/showcase/shared.dart';

String _databaseUrl = 'postgres://dev:dev@dev.local:5432/dev';

Pool _pool;

main(){
  _initializePersistence().then((pool){
    _pool = pool;
    var entityManager = new PostgresqlEntityManagerService(_pool, {'profile': new ProfileEntityHandler(new EverydayShowcaseCodec())});
    
      entityManager.persist('profile', null, []).then((key) {
        print('success $key');
        entityManager.findByKey('profile', [15]).then((profiles){
          print('found profiles ${profiles[0].key}');
        }).catchError((error){
          print('error $error');
        }).whenComplete((){
          _pool.destroy();
        });
      }).catchError((error){
        print('error $error');}
      );
    });
}

_initializePersistence(){
  var completer = new Completer();
  var pool = new Pool(_databaseUrl, min: 1, max: 1);
  //TODO Pool is starting event when connections fails
  pool.start().then((v){
    completer.complete(pool);
  }).catchError((e){
    completer.completeError(e);
  });
  return completer.future;
}