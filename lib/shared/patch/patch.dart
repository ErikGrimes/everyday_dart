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
      for(var s in _segments.sublist(0, _segments.length-1)){
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

class _ObservableFieldsScan {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._ObservableFieldsScan');
  
  static final Map<ClassMirror, _ObservableFieldsScan> _cache = {};
  
  static final OBSERVABLE = reflectClass(Observable);
  
  static final OBJECT = reflectClass(Object);
  
  static final String OBJECT_WITH_OBSERVABLE = 'dart.core.Object with observe.src.observable.Observable';
  
  final ClassMirror type;
  
  Set _observableFields;
  
  get observableFields => _observableFields;
  
  factory _ObservableFieldsScan(ClassMirror type){
    var scan = _cache[type];
    if(scan == null){
      scan = new _ObservableFieldsScan._(type); 
      _cache[type] = scan;
    }
    return scan;
  }
  
  _ObservableFieldsScan._(this.type){
    InterfacesScanner scanner = new InterfacesScanner(type); 
    var observables = new Set();
    for(ClassMirror cm in scanner){  
      _LOGGER.finest('Scanning ${cm.simpleName}');
      if(cm == OBJECT || cm == OBSERVABLE || MirrorSystem.getName(cm.simpleName) == OBJECT_WITH_OBSERVABLE) break;
      cm.declarations.forEach((symbol, mirror){
        if(mirror is VariableMirror && !mirror.isPrivate && !mirror.isFinal && !mirror.isStatic){
          for(var meta in mirror.metadata){
            if(meta.reflectee is ObservableProperty){
              observables.add(symbol);
            }
          }      
        }
      });
    } 
    _observableFields = new UnmodifiableSetView(observables);
  }
 
}

class _ObjectBinding {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._ObjectBinding');
  
  List _fields;
  StreamSubscription _sub;
  Map<Symbol,dynamic> _bindings = {};

  _ObjectBinding(String path, Observable observable, EventSink sink){
    _LOGGER.finest('_Binding ${path}');
    
    var mirror = reflect(observable);
    var scan = new _ObservableFieldsScan(mirror.type);
    
    scan.observableFields.forEach((s){
      
      //set initial bindings
      var value = mirror.getField(s).reflectee;
      if(value != null && value is Observable){
        _bindings[s] = _bindingFor(_appendToPath(path, s), value, sink);
      }
    });
      
    _sub = observable.changes.listen((crs){
        List records = [];
        for(var cr in crs){
          var binding = _bindings[cr.name];
          if(binding != null){
              binding.cancel();
          }
          var value = mirror.getField(cr.name).reflectee;
          if(value != null){
            var target = _appendToPath(path, cr.name); 
            if(value is Observable){
              _bindings[cr.name] = _bindingFor(target, value, sink);
            }
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

class _ListBinding {
  
  static final _LOGGER = new Logger('ObjectPatchObserver._ListBinding');
  
  StreamSubscription _sub;
  
  _ListBinding(String path, ObservableList observable, EventSink sink){
    _LOGGER.finest('_ListBinding ${path}');
    var mirror = reflect(observable);
    _sub = observable.listChanges.listen((crs){
      List records = [];
        for(var cr in crs){
          if(cr is ListChangeRecord){
            var end = cr.index + cr.addedCount;
            if(end >= observable.length){
              end = observable.length;
            }
            records.add(new ListPatchRecord(path,cr.index, cr.addedCount, cr.removed.length, observable.sublist(cr.index, end)));
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
 * TODO Observe observables within lists and maps
 * TODO Support ObservableMap
 * TODO Support Custom data structures
 * TODO extend ChangeNotifierBase if ChangeNotifierMixin makes the lifecycle
 * methods public.
 */
class ObjectPatchObserver {
  
  static final _LOGGER = new Logger('ObjectPatchObserver');
  
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
    var watch = new Stopwatch()..start();
    _binding = _bindingFor('/',observable, _changes);   
    watch.stop();
    _LOGGER.finest('_observed [${observable.runtimeType}] in ${watch.elapsedMilliseconds} ms');
  }
  
  _unobserved(){
    _binding.cancel();
  }
  
}

_bindingFor(String path, Observable observable, sink){
  if(observable is ObservableList){
    return new _ListBinding(path,observable, sink);
  } else if(observable is Observable){
    return new _ObjectBinding(path,observable, sink);
  }   
}

class _Node {
  
  var value;
  
  Map<String, _Node> _children;
  
  Map<String, _Node> get children {
    if(_children == null){
      _children = {};
    }else {
    }
    return _children;
  }
  
}

/**
 * TODO Look into intelligently summarizing lists
 */
class Summarizer {

  _Node _root = new _Node();
  
  _Node _mostRecent;
  String _mostRecentPath;
  
  add(ObjectPatchRecord record){
   
    var segments = record.path.split('/').sublist(1);
    
    var current;
    
    if(_mostRecentPath != record.path){
      current = _root;
      for(var s in segments){
     
        var next = current.children[s];
        if(next == null){
          next = new _Node();
          current.children[s] = next;
        }
        current = next;
        }
      
    } else {
      current = _mostRecent;
    }
    
    _mostRecent = current;
    
    _mostRecentPath = record.path;
    
    current.children.clear();

    if(record is ListPatchRecord){
      if(current.value is! List){
        current.value = [];
      }
      current.value.add(record);
    }else {
      current.value = record;
    }
    
  }
  
  addAll(Iterable<ObjectPatchRecord> records){
    records.forEach((r){
      add(r);
    });
  }
  
  List<ObjectPatchRecord> summarize(){
    var records = [];
    var unvisited = new List();
    unvisited.add(_root);
    while(unvisited.isNotEmpty){
      var visit = unvisited.removeAt(0);
      if(visit.value != null){
        if(visit.value is! List){
          records.add(visit.value);
        }else {
          records.addAll(visit.value);
        }
      }
      unvisited.addAll(visit.children.values);
    }
    return records;
    
  }
}