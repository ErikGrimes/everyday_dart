// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.


library everyday.shared.user.user;

import 'dart:async';

//TODO have a look at http://shiro.apache.org/ and other pleasant security frameworks
abstract class UserService {
  Future<User> signIn(AuthToken token, [timeout]);
}

class User {
  
}

abstract class AuthToken {
  
}

class EmailPasswordToken extends AuthToken {
  final String email;
  final String password;
  
  EmailPasswordToken(this.email, this.password);
  EmailPasswordToken.empty():this('','');
  
}
