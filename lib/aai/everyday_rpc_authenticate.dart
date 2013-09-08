library everyday.aai.everyday_rpc_authenticate;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:everyday_dart/aai/shared.dart';
import '../rpc/invoker.dart';
import '../polymer/polyfills.dart';


@CustomTag('everyday-rpc-authenticate')
class EverydayRpcAuthenticate extends PolymerElement with 
  ObservableMixin, AsynchronousEventsMixin, CustomEventsMixin {
  
  static const Symbol RESPONSE = const Symbol('response');
  
  InvocationType get INVOCATION_TYPE => InvocationType.INVOKE;
  
  bool _inDom;
  
  @observable
  bool auto = false;
  
  @observable
  Invoker invoker;
  
  @observable
  AuthToken token;
  
  @observable
  int timeout = 1000;
  
  @observable
  var response;
  
  @observable
  Map positionalParameters;
  
  @observable
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
    print('inserted');
    //_configure();
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
   // _call.invoker = invoker;
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
        callSucceeded(event, event.detail, this);
      }));
      subs.add(_call.onError.listen((event){
        callFailed(event, event.detail, this);
      }));
      subs.add(_call.onComplete.listen((event){
        this.response = event.detail;
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
  
  set onEverydayError(value){
    super.onEverydayError = value;
  }
  
}