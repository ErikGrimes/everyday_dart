// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

import 'dart:async';
import 'dart:io';
import '../../lib/isolate/isolate.dart';

class WillNotDie implements IsolateMainFactory {
  
  Future create(die) {
    new Timer.periodic(new Duration(seconds:1), (timer){
      print('kill me if you can');
    });
    return new Completer().future;
  }

}

class Dies implements IsolateMainFactory {
  
  create(terminate) {
    print('starting');
    throw 'Boom';
  }
 
}

class LoopsForever implements IsolateMainFactory {
  
  create(terminate) {
    runAsync((){
      while(true){
        sleep(new Duration(milliseconds:10));
        print('kill me if you can');
      }
    });
  }
 
}

main(){
  var isolate = new RegeneratingFunctionIsolate(new LoopsForever());

  new Timer.periodic(new Duration(seconds:10), (_){
    isolate.dispose();
  });
  
}
