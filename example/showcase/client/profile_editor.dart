// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

import 'dart:async';

import 'package:polymer/polymer.dart';
import 'package:everyday_dart/client/polymer/polyfills.dart';

import '../shared/model.dart';

@CustomTag('profile-editor')
class ProfileEditor extends PolymerElement with ObservableMixin, CustomEventsMixin {
  
  Stream _onSave;
  
  get onEverydaySave => customEventHandlers['on-everyday-save'];
  
  set onEverydaySave(value){
    customEventHandlers['on-everyday-save'] = value;
  }
  
  Stream get onSave {
    if(_onSave == null){
      _onSave = streamFor('everyday-save');
    }
    return _onSave;
  }
  
  @observable
  Profile profile; 
  
  changed(e){
    //this.dispatchCustomEvent('everyday-save', profile);
  }
  
  save(e){
    this.dispatchCustomEvent('everyday-save', profile);
  }
  
}