// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.places.everyday_place_history;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:polymer_expressions/filter.dart';

import 'package:everyday_dart/client/places/places.dart';


@CustomTag('everyday-place-history')
class PlaceHistory extends PolymerElement {

  final Logger _LOGGER = new Logger('everyday.client.places.everyday_place_history');
 
   StreamSubscription _selfSub;
   StreamSubscription _placeSub;
   StreamSubscription _locationSub;
  
   @published
   ObservableBox place;
   
   @published
   Transformer<String,Place> transformer;
   
   PlaceHistory.created() : super.created();
  
  enteredView(){
    super.enteredView();
    _configure();
    _selfSub = this.changes.listen(_propertyChanged);
  }
  
  _configure(){
    if(_requiredAttributesSet){
      _locationSub = window.onPopState.listen((_){
        _locationChanged(window.location.pathname);
      });
      _placeSub = place.changes.listen((crs){
       _placeChanged();
      });
    }
  }
  
  bool get _requiredAttributesSet {
    return place != null && transformer != null;
  }
  
  _unconfigure(){
    _cancelPlaceSub();
    _locationSub.cancel();
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

  _placeChanged(){
    _LOGGER.fine('Place change ${place.value}');
    String placePathname = transformer.forward(place.value);
    if(placePathname != window.location.pathname){
      //_router.gotoPath(placePathname,'');
      window.history.pushState(null, title, placePathname);
    }
  }
  
  _locationChanged(String location){
    var next = transformer.reverse(location); 
    if(place.value != next){
      _LOGGER.fine('Location change ${location}');
      place.value = next;
      Observable.dirtyCheck();
    }
  }
  
  leftView(){
    _unconfigure();
    _selfSub.cancel();
    super.leftView();
  }
   
}
