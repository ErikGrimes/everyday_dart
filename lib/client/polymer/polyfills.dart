// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.client.polymer.polyfills;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';

class CustomEvent_ {
  final CustomEvent event;
  final dynamic detail;
  final Node src;
  
  CustomEvent_(this.event, this.detail, this.src);
  
}

abstract class CustomEventsMixin implements PolymerElement {
  
  Map<String, dynamic> _customEventHandlers;
  StreamController _customEventController;
  
  Map<String, dynamic> get customEventHandlers {
    if(_customEventHandlers == null){
      _customEventHandlers = new Map();
    }
    return _customEventHandlers;
  }
  
  StreamController<CustomEvent_> get customEventController {
    if(_customEventController == null){
      _customEventController = new StreamController.broadcast();
    }
    return _customEventController;
  }
  
  dispatchCustomEvent(type, [detail]){
    var delegate = this.customEventHandlers['on-$type'];
    var event = new CustomEvent(type);
    customEventController.add(new CustomEvent_(event, detail,this));
    if(delegate != null){
      delegate([event, detail, this]);
    }
    return event;
  }
  
  Stream<CustomEvent_> streamFor(type){
    return customEventController.stream.where((e){ return e.event.type == type;});
  }
  
}

abstract class AsynchronousEventsMixin {
  Map<String, dynamic> get customEventHandlers;
  Stream<CustomEvent> streamFor(type);
  
  
  Stream _onError;
  Stream _onSuccess;
  Stream _onComplete;
  
  bool test = false;
  
  dispatchCustomEvent(type, detail);
  
  @published
  get onEverydayError => customEventHandlers['on-everyday-error'];
  
  set onEverydayError(value){
    customEventHandlers['on-everyday-error'] = value;
  }
  
  @published
  get onEverydayComplete => customEventHandlers['on-everyday-complete'];
  
  set onEverydayComplete(value){
    customEventHandlers['on-everyday-complete'] = value;
  }
  
  @published
  get onEverydaySuccess => customEventHandlers['on-everyday-success'];
  
  set onEverydaySuccess(value){
    customEventHandlers['on-everyday-success'] = value;
  }
  
 
  Stream get onError {
    if(_onError == null){
      _onError = streamFor('everyday-error');
    }
    return _onError;
  }
  
  Stream get onSuccess {
    if(_onSuccess == null){
      _onSuccess = streamFor('everyday-success');
    }
    return _onSuccess;
  }
  
  Stream get onComplete {
    if(_onComplete == null){
      _onComplete = streamFor('everyday-complete');
    }
    return _onError;
  }
  
  dispatchSuccess(result){
    this.dispatchCustomEvent('everyday-success', result);  
    this.dispatchCustomEvent('everyday-complete', result); 
  }
  
  dispatchError(error){
    this.dispatchCustomEvent('everyday-error', error);  
    this.dispatchCustomEvent('everyday-complete', error);  
  }
    
}