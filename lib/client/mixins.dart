library everyday.client.mixins;

import 'package:polymer/polymer.dart';

abstract class AsynchronousEventsMixin implements PolymerElement {

  dispatchSuccess(result){
    this.fire('everydaysuccess', detail: result);  
    this.fire('everydaycomplete'); 
  }
  
  dispatchError(error){
    this.fire('everydayerror', detail:error);  
    this.fire('everydaycomplete');  
  }
    
}