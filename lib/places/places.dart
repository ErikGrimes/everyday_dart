// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.places;

import 'package:polymer_expressions/filter.dart';

class Place {
  
}


class PlacesTransformer extends Transformer<String, Place> {
  final List<Transformer<String, Place>> _transformers;
  PlacesTransformer(this._transformers);
  
  String forward(Place p){
    var val;
    for(var t in _transformers){
      val = t.forward(p);
      if(val != null){
        break;
      }
    }
    return val;
    
  }
  Place reverse(String s){
    var val;
    for(var t in _transformers){
      val = t.reverse(s);
      if(val != null){
        break;
      }
    }
    return val;
  }
  
}

