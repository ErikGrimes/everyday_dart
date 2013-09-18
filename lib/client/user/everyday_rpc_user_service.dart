library everyday.client.user.everyday_rpc_user_service;

import 'dart:async';

import 'package:polymer/polymer.dart';

import '../../shared/user/user.dart';
import '../../shared/rpc/invoker.dart';

import '../polymer/polyfills.dart';

@CustomTag('everyday-rpc-user-service')
class EverydayRpcUserService extends PolymerElement 
with ObservableMixin, CustomEventsMixin implements UserService {
  
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds:1);
  
  static const String DEFAULT_ENDPOINT = 'user';
  
  @observable
  String endpoint = DEFAULT_ENDPOINT;
  
  @observable
  Invoker invoker;
  
  Future<User> signIn(AuthToken token, [timeout= DEFAULT_TIMEOUT]) {
    return invoker.call(endpoint, 
        'signIn', 
        InvocationType.INVOKE, 
        positional: [token], 
        timeout: timeout);
  }
}