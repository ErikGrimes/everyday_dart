import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'model.dart';

@CustomTag('profile-form')
class ProfileForm extends PolymerElement with ObservableMixin {
  
  @observable
  Profile profile; 
  
  Timer _timer;
  
  inserted(){
    super.inserted();
  //  print('profile form inserted ${this.host}');
    //TODO Remove this hack once https://code.google.com/p/dart/issues/detail?id=12722 is fixed.
    _timer = new Timer.periodic(new Duration(seconds:5),(_){
      this.dispatchEvent(new Event('change')); 
    });
  }
  
  removed(){
  //  print('profile form removed');
    _timer.cancel();
    super.removed();
  }
  
  changed(e){
    this.dispatchEvent(new Event('change')); 
  }
  
}