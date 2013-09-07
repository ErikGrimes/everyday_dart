library everyday.isolate;

import 'dart:isolate';
import 'dart:async';

class IsolateSocket extends Stream implements StreamSink {
  
  StreamController _controller = new StreamController();
  SendPort _outbound;
  ReceivePort _inbound;
  SendPort _replyTo;
  Completer _done = new Completer();
  
  IsolateSocket(this._inbound, this._outbound){
    _replyTo = _inbound.toSendPort();
  }
  
  void add(event) {
    _outbound.send(event, _replyTo);
  }

  void addError(errorEvent) {
    // TODO implement this method
    throw new UnimplementedError();
  }

  Future addStream(Stream stream) {
      stream.listen((data){
        add(data);
      }, onError: (error){
        throw new UnimplementedError();
      }, onDone:(){});
  }

  Future close() {
    _inbound.close();
    _done.complete();
  }

  Future get done => _done.future;

  StreamSubscription listen(void onData(event), {void onError(error), void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError:onError, onDone: onDone, cancelOnError:cancelOnError);
  }
  
  _receive(message, replyTo){
    _controller.add(message);
  }
}


abstract class IsolateMainFactory {
    Future create(Future terminate);
}

class IsolateAbortedException implements Exception {
  
}

class RegeneratingFunctionIsolate {
  
  static const Duration DEFAULT_KEEPALIVE = const Duration(seconds:1);
  
  static const Duration DEFAULT_MAX_WAIT = const Duration(seconds:1);
  
  IsolateMainFactory _main;
  
  SendPort _isolateMainSend;
  
  ReceivePort _controlReceive;
  
  SendPort _controlSend;
  
  Timer _pingTimer;
  
  int _maxOverdue;
  
  int _currentOverdue = 0;
  
  Duration _maxWait;
  
  RegeneratingFunctionIsolate(this._main, {keepAlive: DEFAULT_KEEPALIVE, maxOverdue: 1, maxWait: DEFAULT_MAX_WAIT}): 
    this._maxOverdue = maxOverdue, 
    this._maxWait = maxWait {
    _regenerate();
    _controlReceive = new ReceivePort();
    _controlReceive.receive((message, replyTo){
      _currentOverdue = 0;
    });
    _controlSend = _controlReceive.toSendPort();
    _pingTimer = new Timer.periodic(keepAlive, (timer){
      if(_alive){
        _currentOverdue++;
        _ping();
      } else {
        _currentOverdue = 0;
        _regenerate();
      }
    });
  }
  
  _regenerate(){
    if(_isolateMainSend != null){
      _isolateMainSend.send(new _Die(_maxWait));
    }
    _isolateMainSend = spawnFunction(_isolateMain);
    _isolateMainSend.send(_main);
  }
  
  get _alive => _currentOverdue < _maxOverdue;
  
  _ping(){
    _isolateMainSend.send('ping', _controlSend);
  }
 
  dispose(){
    _pingTimer.cancel();
    _isolateMainSend.send(new _Die(_maxWait));
    _controlReceive.close();
  }
  
}

class _Die {
  final Duration wait;
  
  _Die(this.wait);
}

_isolateMain(){
  var die = new Completer();
  Future done;
  port.receive((message, replyTo){
    if(message == 'ping'){
      replyTo.send('pong');
    }else if (message is _Die){
      port.close();
      die.complete();
      var graceful = new Completer();
      var withPrejudice = new Timer(message.wait,(){
        if(!graceful.isCompleted){
          throw new IsolateAbortedException();
        }
      });
      done.whenComplete((){
        graceful.complete();
      });
    }else if (message is IsolateMainFactory){
      done = message.create(die);
    }
  });
}