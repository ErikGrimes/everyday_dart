library everyday.rpc.everyday_rpc_call;

import 'dart:async';
import 'package:polymer/polymer.dart';
import '../rpc/invoker.dart';
import '../polymer/polyfills.dart';

@CustomTag('everyday-rpc-call')
class EverydayRpcCall extends PolymerElement with ObservableMixin, CustomEventsMixin, AsynchronousEventsMixin {
 
  Invoker invoker;
  
  bool auto = false;
  
  String endpoint;
  
  String method;
  
  InvocationType invocationType;
  
  List positionalParameters;
  
  Map namedParameters;
 
  int timeout;
  
  var result;
  
  bool _inDom = false;
  inserted(){   
    _inDom = true;

    if(auto){
      go();
    }
    
  }
  
  removed(){
    _inDom = false;
  }
  
  set onEverydayError(value){
    super.onEverydayError = value;
  }
  
  go(){
    _assertValid();
    invoker.call(endpoint, 
        method, 
        invocationType, 
        positional: positionalParameters, 
        named: namedParameters, 
        timeout: new Duration(milliseconds:timeout)).then((_result){
          if(_inDom){
            result = _result;
            this.dispatchCustomEvent('everyday-success', result);
            this.dispatchCustomEvent('everyday-complete', result);
          }
        }).catchError((error){
          if(_inDom){
            result = error;
            this.dispatchCustomEvent('everyday-error', result);
            this.dispatchCustomEvent('everyday-complete', result);
          }
        });
  }
  
  _assertValid(){
    if(invoker == null ||  endpoint == null || method == null || invocationType == null) throw new StateError('Required attributes not set');
  }
  
}