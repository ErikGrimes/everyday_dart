// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.client.profile_editor;

import 'package:polymer/polymer.dart';

import '../shared/model.dart';

@CustomTag('profile-editor')
class ProfileEditor extends PolymerElement {
  
  ProfileEditor.created() : super.created();
  
  @published
  Profile profile; 
  
  changed(e){
    //this.dispatchCustomEvent('everyday-save', profile);
  }
  
  save(e){
    e.preventDefault();
    this.fire('everyday-save', detail: profile);
  }
  
}