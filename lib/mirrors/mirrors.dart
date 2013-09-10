// Copyright (c) 2013, the Everyday Dart project authors.  Please see the AUTHORS 
// file for details. All rights reserved. Use of this source code is licenced 
// under the Apache License, Version 2.0.  See the LICENSE file for details.

library everyday.patch.mirrors;

import 'dart:collection';
import 'dart:mirrors';

const String _SYMBOL_START = 'Symbol("';
const String _SYMBOL_END = '")';

convertSymbolToString(symbol){
  var symbolString = symbol.toString();
  return symbolString.substring(_SYMBOL_START.length,symbolString.length-_SYMBOL_END.length);
}

ClassMirror _OBJECT_MIRROR = reflectClass(Object);

class _TypeMirrorEntry extends LinkedListEntry<_TypeMirrorEntry> {
  final TypeMirror value;

  _TypeMirrorEntry(this.value);

  String toString() => value.toString();
}


class InterfacesScanner extends IterableBase<ClassMirror>{
  
  ClassMirror _root;
  
  InterfacesScanner(this._root);
  
  get iterator => new _InterfacesScannerIterator(_root);
  
}

class _InterfacesScannerIterator implements Iterator {
  
  Queue _queue = new Queue();
  ClassMirror _current;
  
  _InterfacesScannerIterator(ClassMirror root){
    _queue.add(root); 
  }
  
  ClassMirror get current => _current;
  
  bool moveNext(){
    if(_queue.isNotEmpty){
      _current = _queue.removeFirst();  
      _queue.addAll(_current.superinterfaces);
      if(_current.superclass != null){
        _queue.add(_current.superclass);
      }
      return true;
    }
    return false;
  }
  
}
