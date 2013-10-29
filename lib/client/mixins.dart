library everyday.client.mixins;

import 'package:polymer/polymer.dart';

abstract class AsynchronousEventsMixin implements PolymerElement {

  dispatchSuccess(result){
    this.fire('everyday-success', detail: result);  
    this.fire('everyday-complete'); 
  }
  
  dispatchError(error){
    this.fire('everyday-error', detail:error);  
    this.fire('everyday-complete');  
  }
    
}