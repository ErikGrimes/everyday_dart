library everyday.client.user.everyday_rpc_user_service;

import 'dart:async';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/user/user.dart';
import 'package:everyday_dart/shared/rpc/invoker.dart';

@CustomTag('everyday-rpc-user-service')
class EverydayRpcUserService extends PolymerElement 
implements UserService {
  
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds:1);
  
  static const String DEFAULT_ENDPOINT = 'user';
  
  @published
  String endpoint = DEFAULT_ENDPOINT;
  
  @published
  var invoker;
  
  EverydayRpcUserService.created() : super.created();
  
  Future<User> signIn(AuthToken token, [timeout= DEFAULT_TIMEOUT]) {
    return invoker.invoke(endpoint, 
        'signIn', 
        InvocationType.INVOKE, 
        positional: [token], 
        timeout: timeout);
  }
}