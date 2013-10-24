// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.patch.everyday_patch_observer;

import 'dart:async';

import 'package:polymer/polymer.dart';

import 'package:everyday_dart/shared/patch/patch.dart';

@CustomTag('everyday-patch-observer')
class EverydayPatchObserver extends PolymerElement {
  
  @published
  Observable observe;
  
  @published
  List changed = new List();
  
  EverydayPatchObserver.created() : super.created();
  
  StreamSubscription _patches;
  
  inserted(){
    _configure();
  }
  
  removed(){
    _unconfigure();
  }
  
  observeChanged(oldValue){
    _unconfigure();   
    _configure();
  }
  
  _configure(){
    if(observe != null){
      var watch = new Stopwatch();
      watch.start();
      _patches = new ObjectPatchObserver(observe).changes.listen((patches){
        changed.addAll(patches);
      });
      watch.stop();
    }
  }
  
  _unconfigure(){
    if(_patches != null){
      _patches.cancel();
    }
  }
  
  get _attributesSet => observable != null;
  
 
}