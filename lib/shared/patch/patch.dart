// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.shared.patch.patch;

import 'dart:async';
import 'dart:mirrors';
import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:unmodifiable_collection/unmodifiable_collection.dart';
import '../mirrors/mirrors.dart';


abstract class ObjectPatchRecord {
  String path;
  List<String> _segments;

  ObjectPatchRecord(this.path){
    _segments = path.split('/');
    _segments = _segments.sublist(1, _segments.length);
  }
  
  parent(root){
    var mirror = reflect(root);
    if(_segments.length > 1){
      for(var s in _segments.sublist(_segments.length-2, _segments.length-1)){
        if(s.isNotEmpty){
          mirror = mirror.getField(new Symbol(s));
        }else {
          break;
        }
     }
    }
    return mirror.reflectee;
  }
  
  target(root){ 
    var mirror = reflect(root);
    for(var s in _segments){
      if(s.isNotEmpty){
        mirror = mirror.getField(new Symbol(s));
      }else {
        break;
      }
    }
    return mirror.reflectee;
  }
  
  String get name {
    return _segments.last;
  }
  
  toString(){
    return super.toString() + ' path = $path';
  }
  
}

class PropertyPatchRecord extends ObjectPatchRecord {
  final value;
  PropertyPatchRecord(path, this.value): super(path);
  
  apply(Object o){
    reflect(parent(o)).setField(new Symbol(name),value);     
  }
  
  toString(){
    return super.toString() + ', value =$value';
  }
  
}

class ListPatchRecord extends ObjectPatchRecord {
  final values;
  final index;
  final addedCount;
  final removedCount;
  ListPatchRecord(path, this.index, this.addedCount, this.removedCount, this.values): super(path);

  apply(Object o){
    var list = target(o);
    if(addedCount == 0 && removedCount == 0) return;
    if(addedCount == removedCount){
      list.setAll(index, values);
    } else if (addedCount > 0 && removedCount == 0){
      list.insertAll(index, values);
    } else if(addedCount == 0 && removedCount > 0){
      list.removeRange(index, index+removedCount);
    } else if(addedCount > removedCount){
      list.length += (addedCount - removedCount);
      list.setAll(index, values);
    } else {
      list.setAll(index, values);
      list.length += (addedCount - removedCount);
    }
  }
  
  String toString() {
   return super.toString() + ', index = $index, addedCount = $addedCount removedCount = $removedCount values = $values';
  }
  
}

class _MutableFieldsScan {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._MutableFieldsScan');
  
  static final Map<ClassMirror, _MutableFieldsScan> _cache = {};
  
  final ClassMirror type;
  
  Set _mutableFields;
  
  get mutableFields => _mutableFields;
  
  factory _MutableFieldsScan(ClassMirror type){
    var scan = _cache[type];
    if(scan == null){
      scan = new _MutableFieldsScan._(type); 
      _cache[type] = scan;
    }
    return scan;
  }
  
  _MutableFieldsScan._(this.type){
    InterfacesScanner scanner = new InterfacesScanner(type); 
    var getters = new Set();
    var setters = new Set();
    for(ClassMirror cm in scanner){  
      _LOGGER.finest('Scanning ${cm.simpleName}');
      getters.addAll(cm.getters.keys);
      setters.addAll(cm.setters.keys.map((k) => _toGetterSymbol(k)));
    } 
    _mutableFields = new UnmodifiableSetView(getters.intersection(setters));
  }
  
  _toGetterSymbol(symbol){
    var symbolString = convertSymbolToString(symbol);
    return new Symbol(symbolString.substring(0, symbolString.length-1));
  }
  
}

class _ObjectBinding {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._ObjectBinding');
  
  List _fields;
  StreamSubscription _sub;
  Map<Symbol,dynamic> _bindings = {};

  _ObjectBinding(path, observable, sink){
    _LOGGER.finest('_Binding ${path}');
    
    var mirror = reflect(observable);
    var scan = new _MutableFieldsScan(mirror.type);
    
    scan.mutableFields.forEach((s){
      
      //set initial bindings
      var value = mirror.getField(s).reflectee;
      if(value != null){
        _bindings[s] = _bindingFor(_appendToPath(path, s), value, sink);
      }
    });
      
    _sub = observable.changes.listen((crs){
        List records = [];
        for(var cr in crs){
          var binding = _bindings[cr.field];
          if(binding != null){
              binding.cancel();
          }
          var value = mirror.getField(cr.field).reflectee;
          if(value != null){
            var target = _appendToPath(path, cr.field); 
            _bindings[cr.field] = _bindingFor(target, value, sink);
            records.add(new PropertyPatchRecord(target, value));
          }
        }
        if(records.isNotEmpty){
          sink.add(records);
        }
      });

  }
  
  cancel(){
    _sub.cancel();
    _bindings.values.forEach((b){b.cancel();});
    _bindings.clear();
  }

  _appendToPath(String path, Symbol field){
    if('/' != path){
      return path + '/' + convertSymbolToString(field);
    }else {
      return path + convertSymbolToString(field);
    }
  }
  
}

//TODO observe the observables with the list
class _ListBinding {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._ListBinding');
  
  StreamSubscription _sub;
  
  _ListBinding(path, observable, sink){
    _LOGGER.finest('_ListBinding ${path}');
    var mirror = reflect(observable);
    _sub = observable.changes.listen((crs){
      List records = [];
        for(var cr in crs){
          if(cr is ListChangeRecord){
            var end = cr.index + cr.addedCount;
            if(end >= observable.length){
              end = observable.length;
            }
            records.add(new ListPatchRecord(path,cr.index, cr.addedCount, cr.removedCount, observable.sublist(cr.index, end)));
          }
        }
        sink.add(records);
    });
  }
  
  cancel(){
    _sub.cancel();
  }
}

/**
 * TODO Handle cycles
 * TODO Intelligently handle objects that appear in the graph multiple times
 * TODO Observe observables within lists and maps
 * TODO Support ObservableMap
 * TODO Support Custom data structures
 * TODO extend ChangeNotifierBase if ChangeNotifierMixin makes the lifecycle
 * methods public.
 * TODO Investigate versoning records to make it easy to tell if two data 
 * structures are equal without having to compare them.
 * 
 * This could probably be more like json patch, but we're constrained by
 * observe.
 * 
 */
class ObjectPatchObserver {
  
  StreamController _changes;
  
  final Observable observable;
  
  var _binding;
   
  ObjectPatchObserver(this.observable){
    _changes = new StreamController.broadcast(sync: true,
        onListen: _observed,
        onCancel: _unobserved);
  }
  
  Stream get changes => _changes.stream;
  
  _observed(){
    _binding = _bindingFor('/',observable, _changes);    
  }
  
  _unobserved(){
    _binding.cancel();
  }
  
}

_bindingFor(path, observable, sink){
  if(observable is ObservableList){
    return new _ListBinding(path,observable, sink);
  } else if(observable is Observable){
    return new _ObjectBinding(path,observable, sink);
  }   
}