import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

import '../../../lib/shared/patch/patch.dart';

class QuicklyObserved extends Object with Observable  {

  @observable
  String observedString;
  
  String ignoredString;
  
  String _observedGetter;
  
  @observable
  ChildObserved childObserved;
  
  @observable
  MixinObserved mixinObserved;
  
  @observable
  EnormousObserved enormousObserved;
  
  @observable
  CompositorObserved1 compositorObserved1;
  
  @observable
  CompositorObserved2 compositorObserved2;
  
  @observable
  CompositorObserved3 compositorObserved3;
  
}

abstract class SuperObserved extends Object with Observable {

  @observable
  String observed1;
  
  @observable
  String observed2;
  
}

class ChildObserved extends Object with Observable {

  @observable
  String observed1;
  
  @observable
  String observed2;
  
}

abstract class ObserveMeMixin {
  
  @observable
  String observed1;
  
  @observable
  String observed2;
  
}


class MixinObserved extends Object with Observable, ObserveMeMixin {

  @observable
  String observed3;
  
}

class EnormousObserved extends Object with Observable {

  @observable
  String observed1;
  
  @observable
  String observed2;
  
  @observable
  String observed3;
  
  @observable
  String observed4;
  
  @observable
  String observed5;
  
  @observable
  String observed6;
  
  @observable
  String observed7;
  
  @observable
  String observed8;
  
  @observable
  String observed9;
  
  @observable
  String observed10;
  
  @observable
  String observed11;
  
  @observable
  String observed12;
  
  @observable
  String observed13;
  
  @observable
  String observed14;
  
  @observable
  String observed15;
  
  @observable
  String observed16;
  
  @observable
  String observed17;
  
  @observable
  String observed18;
  
  @observable
  String observed19;
  
  @observable
  String observed20;
  
  @observable
  String observed21;
  
  @observable
  String observed22;
  
  @observable
  String observed23;
  
  @observable
  String observed24;
  
  @observable
  String observed25;
  
  @observable
  String observed26;
  
  @observable
  String observed27;
  
  @observable
  String observed28;
  
  @observable
  String observed29;
  
  @observable
  String observed30;
  
}

class CompositorObserved1 extends Object with Observable {

  @observable
  NestedObserved1 observed1;
  
}

class NestedObserved1 extends Object with Observable {
  @observable
  String value;
}

class CompositorObserved2 extends Object with Observable {

  @observable
  NestedObserved2 observed1;
  
}

class NestedObserved2 extends Object with Observable {
  @observable
  String value;
}

class CompositorObserved3 extends Object with Observable {

  @observable
  NestedObserved3 observed1;
  
}

class NestedObserved3 extends Object with Observable {
  @observable
  String value;
}

class SimpleObserved extends Object with Observable {
  
  @observable
  String observedInstanceVariable;
  
  String ignoredString;
  
  @observable
  String get ignoreMethod => 'ignored';
  
  @observable
  final String IGNORE_FINAL = 'ignored';
  
  @observable
  static String IGNORE_STATIC = 'ignored';
  
  @observable get noSetter => 'ignored';
  
}


main(){
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(_logToConsole);
  
  //test('observes simple object',_observesSimpleObject);
  test('observes quickly',_observesQuickly);
  
}

_observesSimpleObject(){
  var orig= new SimpleObserved();
   
  orig.changes.listen((records){
    print(records);
  });
  
  var observer = new ObjectPatchObserver(orig);
  
  //TODO Make sure the order of records is reasonable
  var listener = (crs){
    expect(crs.length, equals(1));
  };
  
  var watch = new Stopwatch();
  
  observer.changes.listen(expectAsync1(listener));
  
  watch.stop();
  
  print('observe SimpleObserved took ${watch.elapsedMilliseconds} ms');
  
  orig.observedInstanceVariable = 'variable observed';
  SimpleObserved.IGNORE_STATIC = 'changed static';
  
  //TODO Come up with a test for making sure something is ignored
  
  Observable.dirtyCheck();
  
}


_observesQuickly() {
  var orig= new QuicklyObserved();
  orig.childObserved = new ChildObserved();
  orig.compositorObserved1 = new CompositorObserved1();
  orig.compositorObserved1.observed1 = new NestedObserved1();
  orig.compositorObserved2 = new CompositorObserved2();
  orig.compositorObserved2.observed1 = new NestedObserved2();
  orig.compositorObserved3 = new CompositorObserved3();
  orig.compositorObserved3.observed1 = new NestedObserved3();
  orig.enormousObserved = new EnormousObserved();
  
  orig.changes.listen((records){
    print(records);
  });
  
  var observer = new ObjectPatchObserver(orig);
  
  //TODO Make sure the order of records is reasonable
  var listener = (crs){
    expect(crs.length, equals(1));
  };
  
  var watch = new Stopwatch();
  
  watch.start();
  
  observer.changes.listen(expectAsync1(listener));
  
  Observable.dirtyCheck();
  
  watch.stop();
  
  print('observe QuicklyObserved took ${watch.elapsedMilliseconds} ms');
  
  expect(watch.elapsedMilliseconds, lessThan(50));
  
}

_logToConsole(LogRecord lr){
  var json = new Map();
  json['time'] = lr.time.toLocal().toString();
  json['logger'] = lr.loggerName;
  json['level'] = lr.level.name;
  json['message'] = lr.message;
  if(lr.error != null){
    json['error'] = lr.error;
  }
  print(json);
}