// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.user.everyday_rpc_signin;

import 'dart:async';

import 'package:polymer/polymer.dart';

import '../../shared/user/user.dart';
import '../../shared/rpc/invoker.dart';

import '../polymer/polyfills.dart';


@CustomTag('everyday-rpc-signin')
class EverydayRpcSignin extends PolymerElement with 
  ObservableMixin, AsynchronousEventsMixin, CustomEventsMixin {
  
  static const Symbol RESPONSE = const Symbol('response');
  
  InvocationType get INVOCATION_TYPE => InvocationType.INVOKE;
  
  bool _inDom;
  
  @published
  bool auto = false;
  
  @published
  Invoker invoker;
  
  @published
  AuthToken token;
  
  @published
  User user;
  
  @published
  int timeout = 1000;
  
  @published
  Map positionalParameters;
  
  @published
  String endpoint;
  
  StreamSubscription _selfSub;
  
  var __call;
  
  get _call {
    if(__call == null){
      __call = this.shadowRoot.query('#call').xtag;
    }
    return __call;
  }
  
  inserted(){
    _configure();
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  removed(){
    _unconfigure();
    _selfSub.cancel();
  }
  
  _propertyChanged(List records){
    for(var cr in records){
      if(_changeRequiresReconfigure(cr)){
        _unconfigure();
        _configure();
        break;
      }
    }  
  }
  
  _changeRequiresReconfigure(cr){
    return cr.field != RESPONSE;
  }
  
  _configure(){
    _call.invoker = invoker;
    _call.endpoint = endpoint;
    _call.method = 'signIn';
    _call.timeout = timeout;
    _call.invocationType = InvocationType.INVOKE;
    _call.positionalParameters = [token];   
    if(auto){
      go();
    }
  }
  
  _unconfigure(){
    
  }
  
  get _attributesSet => invoker != null && token != null && endpoint != null;
  
  go(){
    if(_attributesSet) {  
    var subs = [];
     subs.add(_call.onSuccess.listen((event){
        this.callSucceeded(event, event.detail, this);
      }));
      subs.add(_call.onError.listen((event){
        this.callFailed(event, event.detail, this);
      }));
      subs.add(_call.onComplete.listen((event){
        this.user = event.detail;
        subs.forEach((s){s.cancel();});
      }));
      _call.go();
    }
  }
  
  callSucceeded(event, detail, target){
    this.dispatchSuccess(detail);  
  }
  
  callFailed(event, detail, target){
    this.dispatchError(detail);
  }
  
  set onEverydaySuccess(value){
    super.onEverydaySuccess = value;
  }
  
  set onEverydayError(value){
    super.onEverydayError = value;
  }
  
}