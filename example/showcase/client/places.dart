// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.showcase.client.places;

import 'package:polymer_expressions/filter.dart';
import 'package:everyday_dart/client/places/places.dart';
import 'package:route/client.dart';

class ProfilesPlace extends Place {
  operator ==(other){
    if(identical(this,other)) return true;
    if(other is! ProfilesPlace) return false;
    return true;
  }
}

class ProfilePlace extends Place {
    final int key;    
    ProfilePlace(this.key);
    ProfilePlace.newProfile(): this(null);
    operator ==(other){
      if(identical(this,other)) return true;
      if(other is! ProfilePlace) return false;
      return this.key == other.key;
    }
}

class ProfilesPlaceTransformer extends Transformer<String, Place>{
   
  UrlPattern _pattern = new UrlPattern('/profiles');
   
  String forward(Place p){
    if(p is ProfilesPlace){
      return '/profiles';
    }
  }
  Place reverse(String t){
    if(_pattern.matches(t)) return new ProfilesPlace();
    return null;
  }

}

class ProfilePlaceTransformer extends Transformer<String, Place>{
  
  UrlPattern _pattern = new UrlPattern(r'/profile/((new)|(\d+))');
   
  String forward(Place p){
    if(p is ProfilePlace){
      if(p.key != null){
        return '/profile/${p.key.toString()}';
      }else {
        return '/profile/new';
      }
    }
  }
  Place reverse(String t){
    if(_pattern.matches(t)){
      var segments = _pattern.parse(t);
      if(segments[0].isNotEmpty){
        if(segments[0] == 'new'){
          return new ProfilePlace.newProfile();
        }else {
          return new ProfilePlace(int.parse(segments[0]));
        }
      }
    }
    return null;
  }

}