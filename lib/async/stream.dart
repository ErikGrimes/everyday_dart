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
