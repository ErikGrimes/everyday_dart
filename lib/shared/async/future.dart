library everyday.shared.async.future;

import 'dart:async';

class TimedOutException implements Exception {
  
}

class TimedCompleter implements Completer {
  
  Completer _completer = new Completer();
  
  final DateTime completeBy; 
  final DateTime createdAt;
  
  DateTime _completedAt;
  
  DateTime get completedAt => _completedAt;
  
  Duration get timeLeft {
    if(_completer.isCompleted){
      return Duration.ZERO;
    }else {
      return completeBy.difference(new DateTime.now());
    }
  }
  
  Duration get timeTaken {
    if(_completer.isCompleted){
      return completedAt.difference(createdAt);
    }
    return new DateTime.now().difference(createdAt);
  }
  

  
  Timer _timer;
  
  TimedCompleter(Duration timeout): createdAt = new DateTime.now(), completeBy = new DateTime.now().add(timeout){
    
    _timer = new Timer(timeout,(){
      if(!isCompleted){
        _completedAt = new DateTime.now();
        _completer.completeError(new TimedOutException());
      }
    });
  }
  
  void complete([value]) {
    if(!isCompleted){
      _completedAt = new DateTime.now();
      _completer.complete(value);
    }
  }

  void completeError(Object exception, [Object stackTrace]) {
    if(!isCompleted){
      _completedAt = new DateTime.now();
      _completer.completeError(exception, stackTrace);
    }
  }

  Future get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;
}


class LimitedWaitFuture<T> implements Future<T> {
  
  TimedCompleter _completer;
  
  LimitedWaitFuture.from(Future other, Duration maxWait){
    _completer = new TimedCompleter(maxWait);
    
    other.then((value){
      _completer.complete(value);
    }).catchError((error){
      _completer.completeError(error);
    });
    
  }
  
  Duration get timeRemaining {
    return _completer.timeRemaining;
  }
  
  Future then(onValue(T value), { onError(Object error) }) {
    return _completer.future.then(onValue, onError: onError);
  }


  Future catchError(onError(Object error),
                    {bool test(Object error)}) {
    return _completer.future.catchError(onError, test: test);
                    }


  Future<T> whenComplete(action()){
    return _completer.future.whenComplete(action);
  }

 
  Stream<T> asStream(){
    return _completer.future.asStream();
  }
}

wrapFutureWithTimeout(Future future, Duration timeout){
  var completer = new TimedCompleter(timeout);
  
  future.then((value){
    completer.complete(value);
  }).catchError((error){
    completer.completeError(error);
  });
  
  return completer.future;
  
}
