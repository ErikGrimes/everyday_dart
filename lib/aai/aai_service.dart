library everyday.aai._aai_service.dart;

import 'dart:async';
import 'shared.dart';


//TODO have a look at http://shiro.apache.org/ and other pleasant security frameworks
abstract class AAIService {
  Future signIn(AuthToken token);
}


class DefaultAAIService implements AAIService {
  
  Future signIn(AuthToken authToken){
    var completer = new Completer();
    if(authToken is EmailPasswordToken){
      completer.complete();
    }else {
      completer.completeError(new ArgumentError('Invalid token type.'));
    }
    return completer.future;
  }
  
}