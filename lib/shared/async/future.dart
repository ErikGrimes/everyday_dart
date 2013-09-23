library everyday.shared.async.future;

import 'dart:async';

class TimedOutException implements Exception {
  
}

class TimedCompleter implements Completer {
  
  Completer _completer = new Completer();
  
  final DateTime finish; 
  
  Duration get timeRemaining {
    return finish.difference(new DateTime.now());
  }
 
  Timer _timer;
  
  TimedCompleter(Duration timeout): finish = new DateTime.now().add(timeout){
    
    _timer = new Timer(timeout,(){
      if(!isCompleted){
        _completer.completeError(new TimedOutException());
      }
    });
  }
  
  void complete([value]) {
    if(!isCompleted){
      _completer.complete(value);
    }
  }

  void completeError(Object exception, [Object stackTrace]) {
    if(!isCompleted){
      _completer.completeError(exception, stackTrace);
    }
  }

  Future get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;
}