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
    return _args[ENABLE_ISOLATE_POOL_KEY] != null ? (_args[ENABLE_ISOLATE_POOL_KEY] == 'true' ? true : false): false;
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
      containerCreated = new Future.value(new _IsolatePoolMessageHandlerContainer(factory));
    }else {
      containerCreated = factory.create();
    }
   
    containerCreated.then((container){
      container.start().then((_){
        _bindHttpServer(settings).then((httpServer){
          logger.info('Server bound');
          httpServer.transform(new WebSocketTransformer()).listen((WebSocket websocket){;
            container.attach(websocket).then((stream){
              stream.pipe(websocket).then((_){
                if(websocket.readyState == WebSocket.OPEN){
                  websocket.close();
                }
              });
            });
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

class _Ready {
  final SendPort replyTo;
  _Ready(this.replyTo);
}

class _GoodBye {
  
}

class _Forward {
  final dynamic data;
  final String client;
  _Forward(this.client, this.data);
}

class _Assign {
  final String client;
  _Assign(this.client);
}

class _Cancel {
  final String client;
  _Cancel(this.client);
}

/* 
 * TODO Look for a more general purpose approach to isolates.
 */
class _IsolatePoolMessageHandlerContainer implements MessageHandlerContainer {
  
  List<_PoolIsolate> _isolates = [];
  
  int _maxClientsPerIsolate;
  int _minIsolates;
  int _maxIsolates;

  TransferableFactory<MessageHandlerContainer> _factory;
  
  _IsolatePoolMessageHandlerContainer(this._factory,{maxClientsPerIsolate:null, minIsolates:1, maxIsolates:1}) : 
    _maxClientsPerIsolate = maxClientsPerIsolate, 
    _minIsolates = minIsolates, _maxIsolates = minIsolates;
  
  @override
  Future<Stream> attach(Stream inbound) {
    var completer = new Completer();
   if(_maxClientsPerIsolate == null || _leastClients.numClients < _maxClientsPerIsolate){
      completer.complete(_leastClients.attach(inbound));
    }else if(_isolates.length < _maxIsolates){
      _PoolIsolate.spawn(_factory).then((isolate){
        _isolates.add(isolate);
        completer.complete(isolate.attach(inbound));    
      });

    }
   var list = new List();
    return completer.future;
  }

  @override
  Future start() {
    var completer = new Completer();
    for(int i=0; i< _minIsolates;i++){
      _PoolIsolate.spawn(_factory).then((_PoolIsolate isolate){
        _isolates.add(isolate);
        if(_isolates.length >= _minIsolates){
          completer.complete();
        }
      });
    }
    return completer.future;
  }

  @override
  stop() {
    for(var i in _isolates){
      i.dispose();
    }
    _isolates.clear();
  }
  
  _PoolIsolate get _leastClients {
    var least = _isolates.first;
    for(var current in _isolates){
      if(current.numClients < least.numClients){
        least = current;
      }
    }
    return least;
    
  }
  
}

class _PoolIsolate {
  
  ReceivePort _receiveFrom;
  SendPort _replyTo;
  Map<String, StreamSink> _clients = new Map<String, StreamSink>();
  
  _PoolIsolate._(this._receiveFrom, this._replyTo);
  
  static Future<_PoolIsolate> spawn(_factory){
    var receiveFrom = new ReceivePort();
    var sub = receiveFrom.listen(null);
    var completer = new Completer();
    sub.onData((message){
      var poolIsolate = new _PoolIsolate._(receiveFrom, (message as _Ready).replyTo);
      sub.onData((message){
        if(message is _Forward){
          poolIsolate._clients[message.client].add(message.data);
        }else if(message is _Cancel){
          poolIsolate._clients.remove(message.client).close();           
        }
      });
      completer.complete(poolIsolate); 
    });
 
    Isolate.spawn(_poolIsolate, new _Hello(receiveFrom.sendPort, _factory)).catchError((error){
      completer.completeError(error);
    });
 
    return completer.future;
  }
  
  Stream attach(Stream inbound){
    var outbound = new StreamController();
    var id = _nextId.toString();
    _clients[id] = outbound;
    inbound.listen((targetMessage){
      _replyTo.send(new _Forward(id, targetMessage));},
      onDone:(){
        _replyTo.send(new _Cancel(id));
        _clients.remove(id);
      }); 
    _replyTo.send(new _Assign(id));
    return outbound.stream;
  }
  
  
  int __nextId = 0;
  
  int get _nextId {
    return __nextId++;
  }
  
  dispose(){
    _replyTo.send(new _GoodBye());
    for(var client in _clients){
      client.close();
    }
    _clients.clear();
  }
  
  int get numClients => _clients.length;
  
}

class _PoolIsolateSpawn {
 

  Map<String, StreamSink> _clients = new Map();

  MessageHandlerContainer _container;
  ReceivePort _receiveFrom;
  SendPort _replyTo;
  
  _PoolIsolateSpawn(this._receiveFrom, this._replyTo, this._container);
  
  
  static bind(initialMessage){
    (initialMessage as _Hello).factory.create().then((container){
      var receiveFrom = new ReceivePort();
      var spawn = new _PoolIsolateSpawn(receiveFrom, (initialMessage as _Hello).replyTo, container);
      spawn._replyTo.send(new _Ready(receiveFrom.sendPort));
      receiveFrom.listen(spawn._handlePoolMessage);
    }).catchError((error){
      //TODO Handle errors
      print('error');
    });;
  }
  
  _handlePoolMessage(message){
    if(message is _Assign){
      var pool = new StreamController();
       _container.attach(pool.stream).then((Stream container){
        container.listen((containerMessage){
          _replyTo.send(new _Forward(message.client, containerMessage));
        }, onDone:(){
          var sink = _clients.remove(message.client);
          if(sink != null){
            sink.close();
            _receiveFrom.sendPort.send(new _Cancel(message.client));
          }
        }); 
       });    
       _clients[message.client] = pool;
    }else if(message is _Forward){
        _clients[message.client].add(message.data);
    }else if(message is _Cancel){
      _clients.remove(message.client).close();
      
    }else if (message is _GoodBye){ 
      _receiveFrom.close();
      _clients.clear();
      _container.stop();
    }
 
  }
}



_poolIsolate(initialMessage){
    
    _PoolIsolateSpawn.bind(initialMessage); 
  
}
