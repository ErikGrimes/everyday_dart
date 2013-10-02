// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import '../../shared/user/user.dart';

import '../polymer/polyfills.dart';

@CustomTag('everyday-user-access')
class EverydayUserAccess extends PolymerElement with CustomEventsMixin, ObservableMixin  {
  
  static final Logger _LOGGER = new Logger('everyday.user.everyday_user_access');
  
  bool get applyAuthorStyles => true;
  
  @observable
  String email = '';
  
  @observable
  String password = '';
  
  @observable
  UserService service;
  
  set onEverydaySignIn(value){
    customEventHandlers['on-everyday-sign-in'] = value;
  }
  
  signIn(event){
    event.preventDefault();
    _LOGGER.info('Signin requested');
    service.signIn(new EmailPasswordToken(email, password)).then((user){
      _LOGGER.info('Signin successful');
      this.dispatchCustomEvent('everyday-sign-in', user);
    }).catchError((error){
      _LOGGER.info('Signin unsuccessful');
    });  
  }


  
}
