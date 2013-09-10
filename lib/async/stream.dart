// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.


library everyday.async.stream;

import 'dart:async';

Future pipeStream(Stream src, StreamSink dst){
  var completer = new Completer();
  src.listen((data){
    try {
      print('pipeStream adding $data');
      dst.add(data);
    }catch(error){
      completer.completeError(error);
    }
  }, onError:(error){
    completer.completeError(error);
  }, onDone: (){
    if(!completer.isCompleted){
      completer.complete();
    }
  });
  return completer.future;
}
