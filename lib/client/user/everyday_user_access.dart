// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.user.everyday_user_access;

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/user/user.dart';


@CustomTag('everyday-user-access')
class EverydayUserAccess extends PolymerElement {
  
  static final Logger _LOGGER = new Logger('everyday.user.everyday_user_access');
  
  bool get applyAuthorStyles => true;
  
  @published
  String email = '';
  
  @published
  String password = '';
  
  @published
  bool autocomplete = false;
  
  @published
  UserService service;
  
  EverydayUserAccess.created() : super.created();
  
  signIn(event){
    event.preventDefault();
    _LOGGER.info('Signin requested');
    service.signIn(new EmailPasswordToken(email, password)).then((user){
      _LOGGER.info('Signin successful');
      this.fire('everydaysignin', detail:user);
    }).catchError((error){
      _LOGGER.info('Signin unsuccessful', error);
    });  
  }


  
}
