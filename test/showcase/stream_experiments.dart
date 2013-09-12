import 'dart:async';
import 'dart:convert';

import '../../example/showcase/shared.dart';
import '../../example/showcase/model.dart';

main(){
  var codec = new EverydayShowcaseCodec();
  
  StreamController channel = new StreamController();
  StreamController handler = new StreamController();

  handler.stream.listen((data){
    print('data $data');
  }, onError: (error){
    print('error $error');
  }, onDone: (){
    print('done');
  });
  
  
  new Timer.periodic(new Duration(seconds:1), (time) {
    channel.add(codec.encode(new Profile()));
  });
  
  //this will signal done after only one event
  var converter = new ConverterStream(codec.decoder);
  converter.pipe(handler);
  channel.stream.pipe(converter);
}

class ConverterStream extends Stream implements StreamConsumer {
  
  StreamController _controller = new StreamController();
  
  Converter _converter;
  
  ConverterStream(this._converter);
  
  Future addStream(Stream stream) {
    var completer = new Completer();
    stream.listen((data){
        _controller.add(_converter.convert(data));
        }, onError: (error){
          _controller.addError(error);
          completer.completeError(error);
      } 
      ,onDone: (){
        if(!completer.isCompleted){
          completer.complete();
        }
      }, cancelOnError: false);
    return completer.future;
  }

  Future close() {
    print('closed');
    _controller.close();
    return new Future.value();
  }

  StreamSubscription listen(void onData(event), {void onError(error), void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}