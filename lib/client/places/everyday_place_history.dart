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
class EverydayPlaceHistory extends PolymerElement {

  final Logger _LOGGER = new Logger('everyday.client.places.everyday_place_history');
  
   @published
   ObservableBox place;
   
   @published
   Transformer<String,Place> transformer;
  
   Timer _reconfigureJob;
   
   StreamSubscription _placeSub;
   
   StreamSubscription _locationSub;
   
   EverydayPlaceHistory.created() : super.created();
  
  enteredView(){
    super.enteredView();
    _queueReconfigure();
  }
  
  leftView(){
    _unconfigure();
    super.leftView();
  }
  
  _queueReconfigure(){
    if(_reconfigureJob != null) return;
    _reconfigureJob = new Timer(Duration.ZERO, _reconfigure);
  }
  
  _reconfigure(){
    _reconfigureJob = null;
    _unconfigure();
    _configure();
  }
  
  _configure(){
    if(_requiredAttributesSet){
      _locationSub = window.onPopState.listen((_){
        _updatePlace(window.location.pathname);
      });
      _placeSub = place.changes.listen((crs){
       _updateHistory();
      });
      _updateHistory();
    }
  }
  
  bool get _requiredAttributesSet {
    return this.place != null && this.transformer != null;
  }
  
  _unconfigure(){
    _cancelPlaceSub();
    _cancelLocationSub();
  }
  
  _cancelPlaceSub() {
    if(_placeSub != null){
      _placeSub.cancel();
    }
    _placeSub = null;
  }
  
  _cancelLocationSub(){
    if(_locationSub != null){
      _locationSub.cancel();
    }
    _locationSub = null;
  }

  _updateHistory(){
    _LOGGER.fine('Place change ${place.value}');
    String placePathname = transformer.forward(place.value);
    if(placePathname != window.location.pathname){
      window.history.pushState(null, title, placePathname);
    }
  }
  
  _updatePlace(String location){
    var next = transformer.reverse(location); 
    if(place.value != next){
      _LOGGER.fine('Location change ${location}');
      place.value = next;
      Observable.dirtyCheck();
    }
  }
  

   
}
