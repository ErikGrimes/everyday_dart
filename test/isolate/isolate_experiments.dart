import 'dart:async';
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

main(){
  var isolate = new RegeneratingFunctionIsolate(new WillNotDie());

  new Timer.periodic(new Duration(seconds:10), (_){
    isolate.dispose();
  });
  
}
