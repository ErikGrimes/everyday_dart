library everyday.patch.everyday_patch_observer;

import 'dart:async';
import 'package:polymer/polymer.dart';
import '../polymer/polyfills.dart';
import 'patch.dart';

@CustomTag('everyday-patch-observer')
class EverydayPatchObserver extends PolymerElement with 
  ObservableMixin {
  
  static const Symbol OBSERVE = const Symbol('observe');
  
  @observable
  Observable observe;
  
  List changed = new List();
  
  StreamSubscription _patches;
  
  StreamSubscription _selfSub;
  
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
    return cr.field == OBSERVE;
  }
  
  _configure(){
    if(observe != null){
      new ObjectPatchObserver(observe).changes.listen((patches){
        changed.add(patches);
      });
    }
  }
  
  _unconfigure(){
    if(_patches != null){
      _patches.cancel();
    }
  }
  
  get _attributesSet => observable != null;
  
 
}