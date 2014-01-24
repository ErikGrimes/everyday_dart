// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.async.stream;

import 'dart:async';
import 'dart:convert';

class ConverterStream extends Stream implements StreamConsumer {
  
  StreamController _controller = new StreamController();
  
  Converter _converter;
  
  ConverterStream(this._converter);
  
  Future addStream(Stream stream) {
    var completer = new Completer();
    stream.listen((data){
        _controller.add(_converter.convert(data));
        }, onError: (error){
          _controller.addError(error);
          completer.completeError(error);
      } 
      ,onDone: (){
        if(!completer.isCompleted){
          completer.complete();
        }
      }, cancelOnError: false);
    return completer.future;
  }

  Future close() {
    _controller.close();
    return new Future.value();
  }

  /*
  StreamSubscription listen(void onData(event), {void onError(error, [st]), void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  */

  @override
  StreamSubscription listen(void onData(event), {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
