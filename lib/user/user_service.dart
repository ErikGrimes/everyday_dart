// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.


library everyday.user.user_service.dart;

import 'dart:async';
import 'shared.dart';


//TODO have a look at http://shiro.apache.org/ and other pleasant security frameworks
abstract class UserService {
  Future<User> signIn(AuthToken token, [timeout]);
}


class DefaultUserService implements UserService {
  
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds:1);
  
  Future<User> signIn(AuthToken authToken, [timeout = DEFAULT_TIMEOUT]){
    var completer = new Completer();
    if(authToken is EmailPasswordToken){
      completer.complete(new User());
    }else {
      completer.completeError(new ArgumentError('Invalid token type.'));
    }
    return completer.future;
  }
  
}