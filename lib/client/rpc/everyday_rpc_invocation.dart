// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.rpc.everyday_rpc_invocation;

import 'dart:async';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/rpc/invoker.dart';

import 'package:everyday_dart/client/mixins.dart';

@CustomTag('everyday-rpc-invocation')
class EverydayRpcInvocation extends PolymerElement with AsynchronousEventsMixin {
 
  Invoker invoker;
  
  @published
  bool auto = false;
  
  @published
  String endpoint;
  
  @published
  String method;
  
  @published
  InvocationType invocationType;
  
  @published
  List positionalParameters;
  
  Map namedParameters;
 
  @published
  int timeout;
  
  @published
  var result;
  
  EverydayRpcInvocation.created() : super.created();
  
  bool _inDom = false;
  
  enteredView(){  
    
    super.enteredView();
    
    _inDom = true;

    if(auto){
      go();
    }
    
  }
  
  leftView(){
    _inDom = false;
    super.leftView();
  }
  
  go(){
    _assertValid();
    invoker.invoke(endpoint, 
        method, 
        invocationType, 
        positional: positionalParameters, 
        named: namedParameters, 
        timeout: new Duration(milliseconds:timeout)).then((_result){
          if(_inDom){
            result = _result;
            this.dispatchSuccess(result);
          }
        }).catchError((error){
          if(_inDom){
            result = error;
            this.dispatchError(error);
          }
        });
  }
  
  _assertValid(){
    if(invoker == null ||  endpoint == null || method == null || invocationType == null) throw new StateError('Required attributes not set');
  }
  
}