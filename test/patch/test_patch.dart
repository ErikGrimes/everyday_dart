import 'package:observe/observe.dart';
import 'dart:async';

import '../../lib/shared/patch/patch.dart';

class _Node {
  
  var value;
  
  Map<String, _Node> _children;
  
  Map<String, _Node> get children {
    if(_children == null){
      _children = {};
      print('children is null');
    }else {
      print('children isnt null');
    }
    return _children;
  }
  
}

class Summarizer {

  _Node _root = new _Node();
  
  _Node _mostRecent;
  
  add(ObjectPatchRecord record){
    var segments = record.path.split('/').sublist(1);
    
    var current = _root;
    for(var s in segments){
     
      var next = current.children[s];
      print('processing segment $s $next');
      if(next == null){
        next = new _Node();
        current.children[s] = next;
        print('added child $s');
      }
      current = next;
    }
    
    current.children.clear();
    print('processing record $record ${current.value}');
    if(record is ListPatchRecord){
      if(current.value is! List){
        current.value = [];
      }
      current.value.add(record);
    }else {
      current.value = record;
    }
    
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

_summarizeList(List records){
 int length = 0;
 
 for(var r in records){
   length+= r.removedCount - r.addedCount;
 }
 
 print('length $length');
 
}

class Test1 extends Object with ObservableMixin {
  @observable
  String field1;
  
  @observable
  Test2 test2;
  
  @observable
  ObservableList list = new ObservableList();
}

class Test2 extends Object with ObservableMixin {
  @observable
  String field1;
}

main(){
  

  var test1 = new Test1();
  
  var summarizer = new Summarizer();
  
  var observer = new ObjectPatchObserver(test1);
  
  observer.changes.listen((crs){
  //  print('crs $crs');
    crs.forEach((cr){
      summarizer.add(cr);
    });

  });
  new Timer(new Duration(seconds:1),(){
  //  test1.field1 = 'test1.field1a';
  //  test1.test2 = new Test2();
   // test1.test2.field1 = 'test2.field1a';
    test1.list.addAll(['a','b']);
    test1.list.removeAt(1);
    test1.list.insertAll(0, ['c', 'd', 'e']);
    Observable.dirtyCheck();
  });
  
  new Timer(new Duration(seconds:2),(){
  //  print('timer2');
  //  test1.field1 = 'test1.field1b';
  //  test1.test2.field1 = 'test2.field1b';
    test1.list.removeRange(1, 3);
    test1.list.insert(1, 'f');
    Observable.dirtyCheck();
  });
  
  new Timer(new Duration(seconds:3),(){
    print(summarizer.summarize());
  });
  

  
  


  
}


