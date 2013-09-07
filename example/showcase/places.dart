library everyday.showcase.places;

import 'package:polymer_expressions/filter.dart';
import 'package:everyday_dart/places/places.dart';
import 'package:route/client.dart';

class ProfilesPlace extends Place {
  operator ==(other){
    if(identical(this,other)) return true;
    if(other is! ProfilesPlace) return false;
    return true;
  }
}

class ProfilePlace extends Place {
    final String key;    
    ProfilePlace(this.key);
    
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
  
  UrlPattern _pattern = new UrlPattern(r'/profile/(\d+)');
   
  String forward(Place p){
    if(p is ProfilePlace){
      return '/profile/${p.key}';
    }
  }
  Place reverse(String t){
    if(_pattern.matches(t)){
      var segments = _pattern.parse(t);
      return new ProfilePlace(segments[0]);
    }
    return null;
  }

}