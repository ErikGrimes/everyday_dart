// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.places.everyday_place_history;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:route/client.dart';
import 'package:polymer_expressions/filter.dart';

import 'places.dart';

final Logger _logger = new Logger('view-router');

class _DisposableRouter extends Router {
  dispose(){
    _handlers.clear();
  }
}

@CustomTag('everyday-place-history')
class PlaceHistory extends PolymerElement with ObservableMixin {

  static final UrlPattern _ANYTHING = new UrlPattern(r'/(.*)');
 
   StreamSubscription _selfSub;
   StreamSubscription _placeSub;
  
   @observable
   ObservableBox place;
   
   Transformer<String,Place> transformer;
  
  _DisposableRouter _router;
  
  inserted(){
    _configure();
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  _configure(){
    if(_requiredAttributesSet){
      _router = new _DisposableRouter();   
      _router.addHandler(_ANYTHING, _handle); 
      _router.listen();
      _placeSub = place.changes.listen((crs){
        _router.gotoPath(transformer.forward(place.value),'');
      });
    }
  }
  
  bool get _requiredAttributesSet {
    return place != null;
  }
  
  _unconfigure(){
    _cancelPlaceSub();
    _router.dispose();
  }
  
  _propertyChanged(List crs){
    _unconfigure();
    _configure();
  }
  
  _cancelPlaceSub() {
    if(_placeSub != null){
      _placeSub.cancel();
    }
  }

  _handle(String location){
    var next = transformer.reverse(location); 
    if(place.value != next){
      place.value = next;
      Observable.dirtyCheck();
    }
  }
  
  removed(){
    _unconfigure();
    _selfSub.cancel();
  }
   
}
