library everyday.server.io.websocket;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import '../../server/io/message_handler.dart';

class WebSocketServerSettings {

  static final String CERT_DB_KEY = 'cert_db';
  static final String DEFAULT_CERT_DB =  'certdb';

  static final String CERT_NAME_KEY = 'cert_name';
  static final String DEFAULT_CERT_NAME =  'provider';

  static final String LISTEN_ON_KEY = 'listen_on';
  static final String DEFAULT_LISTEN_ON = 'localhost:8443';
  static final int DEFAULT_LISTEN_ON_PORT = 8443;

  static final String DISABLE_SSL_KEY = 'disable_ssl';

  static final String ENABLE_ISOLATE_POOL_KEY= 'enable_isolate_pool';
  
  static final String MAX_CLIENTS_PER_ISOLATE_KEY= 'max_clients_isolate';
  static final String DEFAULT_MAX_CLIENTS_PER_ISOLATE  = null;
  
  static final String MIN_ISOLATES_KEY= 'min_isolates';
  static final String DEFAULT_MIN_ISOLATES = '0';

  static final String MAX_ISOLATES_KEY= 'max_isolates';
  static final String DEFAULT_MAX_ISOLATES = '1';

  Map<String, String> _args;
  
  WebSocketServerSettings(this._args);
  
  bool get disableSsl {
    return _args[DISABLE_SSL_KEY] != null ? (_args[DISABLE_SSL_KEY] == 'true' ? true : false): false;
  }


  String get listenOnAddress {
    var listenOn =  _args[LISTEN_ON_KEY] != null ? _args[LISTEN_ON_KEY] : DEFAULT_LISTEN_ON;
    var parts = listenOn.split(':');
    var port = parts.length > 1 ? int.parse(parts[1]) : DEFAULT_LISTEN_ON_PORT;
    return parts[0];
  }

  int get listenOnPort {
    var listenOn =  _args[LISTEN_ON_KEY] != null ? _args[LISTEN_ON_KEY] : DEFAULT_LISTEN_ON;
    var parts = listenOn.split(':');
    var port = parts.length > 1 ? int.parse(parts[1]) : DEFAULT_LISTEN_ON_PORT;
    return port;
  }

  String get certDb {
    return _args[CERT_DB_KEY] != null ? _args[CERT_DB_KEY] : DEFAULT_CERT_DB;
  }

  String get certName {
    return _args[CERT_NAME_KEY] != null ? _args[CERT_NAME_KEY] : DEFAULT_CERT_NAME;
  }
  

  bool get enableIsolatePool {
    return _args[ENABLE_ISOLATE_POOL_KEY] != null ? (_args[ENABLE_ISOLATE_POOL_KEY] == 'true' ? true : false): true;
  }
  
  int get maxClientsPerIsolate {
    return _args[MAX_CLIENTS_PER_ISOLATE_KEY] != null ? int.parse(_args[MAX_CLIENTS_PER_ISOLATE_KEY]) : DEFAULT_MAX_CLIENTS_PER_ISOLATE;
  }
  
  int get minIsolatePoolSize {
    return _args[MIN_ISOLATES_KEY] != null ? int.parse(_args[MIN_ISOLATES_KEY]) : DEFAULT_MIN_ISOLATES;
  }
  
  int get maxIsolatePoolSize {
    return _args[MAX_ISOLATES_KEY] != null ? int.parse(_args[MAX_ISOLATES_KEY]) : DEFAULT_MAX_ISOLATES;
  }
}

class WebSocketServer  {
  
  final Logger _logger;
  
  final MessageHandlerContainer _container;
  
  WebSocketServer._(this._container, this._logger);

  static Future<WebSocketServer> bind(WebSocketServerSettings settings,  TransferableFactory<MessageHandlerContainer> factory){
    var completer = new Completer();
    var logger = new Logger('server');
    
    var containerCreated;
    if(settings.enableIsolatePool){
      containerCreated = new Future.value(new IsolatePoolMessageHandlerContainer(factory));
    }else {
      containerCreated = factory.create();
    }
   
    containerCreated.then((container){
      container.start().then((_){
        _bindHttpServer(settings).then((httpServer){
          logger.info('Server bound');
          httpServer.transform(new WebSocketTransformer()).listen((websocket){
            container.attach(websocket, websocket);
          });
          completer.complete(new WebSocketServer._(container, logger));
        });
      });
    });
    
    return completer.future;
      
  }
  
  close(){
    _container.stop();
  }
  
  static Future _bindHttpServer(WebSocketServerSettings _settings){
    if(_settings.disableSsl){
      return HttpServer.bind(_settings.listenOnAddress, _settings.listenOnPort);
    }else {
      SecureSocket.initialize(database: _settings.certDb);
      return HttpServer.bindSecure(_settings.listenOnAddress, _settings.listenOnPort, 
          certificateName: _settings.certName);    
    }
  }
}

class _WebSocketTransformSink implements EventSink<HttpRequest> {
  static final Logger _LOGGER = new Logger('everyday.server.io.websocket_transformer');
  
  final EventSink<WebSocket> _outputSink;
  
  bool _discardRegular;
  
  _WebSocketTransformSink(this._outputSink, this._discardRegular);

  void add(HttpRequest request) {
    if(WebSocketTransformer.isUpgradeRequest(request)){
      _LOGGER.info('Upgrading websocket');
      _setResponseHeaders(request.response);
      WebSocketTransformer.upgrade(request)
        .then((WebSocket websocket){
          //websocket.pingInterval = new Duration(seconds:5);

          _outputSink.add(websocket);})
        
          .catchError((error){
            _outputSink.add(error);
          });
   }else if(_discardRegular){
     request.response.statusCode = HttpStatus.NOT_FOUND;
     request.response.close();
   }
  }

  void addError(e, [st]) => _outputSink.addError(e, st);
  void close() => _outputSink.close();
  
  void _setResponseHeaders(HttpResponse res) {
    res.headers.add("Access-Control-Allow-Origin", "*, ");
    res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  }
  
}

class _WebSocketTransformer implements StreamTransformer<HttpRequest,WebSocket> {
  
  bool _discardRegular;
  
  _WebSocketTransformer([discardRegular = true]): this._discardRegular = discardRegular;

  Stream<WebSocket> bind(Stream<HttpRequest> stream) =>
    new Stream<WebSocket>.eventTransformed(
        stream,
        (EventSink sink) => new _WebSocketTransformSink(sink, _discardRegular));
  
}


class _Hello {
  
  final SendPort replyTo;
  final TransferableFactory factory;
  
  _Hello(this.replyTo, this.factory);
  
}

class _Online {
  final SendPort replyTo;
  _Online(this.replyTo);
}

class _GoodBye {
  
}

class _Message {
  final dynamic data;
  _Message(this.data);
}

class _IsolateInfo {
  
}

class IsolatePoolMessageHandlerContainer implements MessageHandlerContainer {
  
  int _maxClientsPerIsolate;
  int _minIsolates;
  int _maxIsolates;
  TransferableFactory<MessageHandlerContainer> _factory;
  List _available = [];
  List _isolates = [];
  
  IsolatePoolMessageHandlerContainer(this._factory,{maxClientsPerIsolate:null, minIsolates:1, maxIsolates:1}) : 
    _maxClientsPerIsolate = maxClientsPerIsolate, 
    _minIsolates = minIsolates, _maxIsolates = minIsolates;
  
  @override
  Future attach(Stream inbound, StreamSink outbound) {
    // TODO: implement attach
    // 1. Find an available isolate
    // 2. Forward messages
  }

  @override
  Future start() {
    var completer = new Completer();
    for(int i=0; i< _minIsolates;i++){
      var me = new ReceivePort();
      Isolate.spawn(_handlerIsolate, new _Hello(me.sendPort, _factory)).then((isolate){
     //   print('spawned');
        me.first.then((msg){
      //    print('first');
          _isolates.add(msg);
          _available.add(msg);
          if(_available.length >= _minIsolates){
            completer.complete();
      //      print('online');
          }
        });
     
      });
    
    }
    return completer.future;
  }

  @override
  stop() {
    for(var i in _isolates){
      i.send();
    }
  }
}

_handlerIsolate(message){
  var me = new ReceivePort();
  var hello = message as _Hello;
  
  hello.factory.create().then((MessageHandlerContainer container){
 //  print('created');
    container.start().then((_){
      var inbound = new StreamController();
      var outbound = new StreamController();
     container.attach(inbound.stream, outbound);
      
      me.listen((data){
        if(data is _Message){
          inbound.add(_Message.data);
        }else {
          container.stop();
        }
      });
     // print('online');
      hello.replyTo.send(new _Online(me.sendPort));
      
    });
      
    
  });
  
  
}