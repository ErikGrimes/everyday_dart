// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

import 'dart:async';
import 'dart:io';
import '../../lib/isolate/isolate.dart';

class TestMain implements FunctionIsolateMain {
  
  Future run(die) {
    new Timer.periodic(new Duration(seconds:1), (timer){
      
    });
    return new Completer().future;
  }

}


main(){
  var isolate = new FunctionIsolate(new TestMain());

  new Timer.periodic(new Duration(seconds:10), (_){
    isolate.dispose();
  });
  
}
