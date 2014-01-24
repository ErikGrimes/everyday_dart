library everyday.server.io.websocket;

import 'dart:async';
import 'dart:collection';
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
      containerCreated = new Future.value(new IsolatePoolMessageHandlerContainer(factory));
    }else {
      containerCreated = factory.create();
    }
   
    containerCreated.then((container){
      container.start().then((_){
        _bindHttpServer(settings).then((httpServer){
          logger.info('Server bound');
          httpServer.transform(new WebSocketTransformer()).listen((WebSocket websocket){
            container.attach(websocket).pipe(websocket).then((_){
              if(websocket.readyState == WebSocket.OPEN){
                websocket.close();
              }
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

class _IsolateInfo implements Comparable<_IsolateInfo> {
  
  final SendPort replyTo;
  final ReceivePort receiveFrom;
  
  Map<String, StreamSink> clients = new Map<String, StreamSink>();
 
  _IsolateInfo(this.receiveFrom, this.replyTo);

  @override
  int compareTo(_IsolateInfo other) {
    return this.clients.length.compareTo(other.clients.length); 
  }
}

class IsolatePoolMessageHandlerContainer implements MessageHandlerContainer {
  
  int _maxClientsPerIsolate;
  int _minIsolates;
  int _maxIsolates;
  TransferableFactory<MessageHandlerContainer> _factory;
  Set<_IsolateInfo> _isolates = new SplayTreeSet<_IsolateInfo>();
  
  IsolatePoolMessageHandlerContainer(this._factory,{maxClientsPerIsolate:null, minIsolates:1, maxIsolates:1}) : 
    _maxClientsPerIsolate = maxClientsPerIsolate, 
    _minIsolates = minIsolates, _maxIsolates = minIsolates;
  
  @override
  Stream attach(Stream target) {
    // TODO: implement attach
    // 1. Find an available isolate
    var containerOut = new StreamController(); //this needs to be per client

    if(_isolates.first.clients.length < _maxClientsPerIsolate){
      _assign(_isolates.first, target, containerOut);
    }else if(_isolates.length < _maxIsolates){
      var completer = new Completer();
      _spawnIsolate().then((isolate){
        _isolates.add(isolate);
        _assign(isolate, target, containerOut );
      });
    }
    // 2. Pipe messages
    // 3. Detach when socket closes or isolate signals client is done
    return containerOut.stream;
  }
  
  _assign(_IsolateInfo isolate, Stream target, StreamSink destination){
    var id = _nextId.toString();
    isolate.clients[id] = destination;
    target.listen((targetMessage){
      isolate.replyTo.send(new _Forward(id, targetMessage));},
      onDone:(){
        isolate.clients.remove(id);
      }); 
  }

  int __nextId = 0;
  
  int get _nextId {
    return __nextId++;
  }
  
  @override
  Future start() {
    var completer = new Completer();
    for(int i=0; i< _minIsolates;i++){
      _spawnIsolate().then((info){
        _isolates.add(info);
        if(_isolates.length >= _minIsolates){
          completer.complete();
        }
      });
    }
    return completer.future;
  }

  Future<_IsolateInfo>_spawnIsolate(){
    var receiveFrom = new ReceivePort();
    var completer = new Completer();
    Isolate.spawn(_containerIsolate, new _Hello(receiveFrom.sendPort, _factory)).then((isolate){
      //   print('spawned');
      receiveFrom.first.then((_Ready msg){
        var info = new _IsolateInfo(receiveFrom, msg.replyTo);
        receiveFrom.listen((isolateMessage){
          if(isolateMessage is _Forward){
            info.clients[isolateMessage.client].add(isolateMessage.data);
          }else if(isolateMessage is _Cancel){
            info.clients.remove(isolateMessage.client).close();           
          }
        });
        completer.complete(info); 
      });
    });
    return completer.future;
  }
  
  @override
  stop() {
    for(var i in _isolates){
      i.replyTo.send(new _GoodBye());
    }
    _isolates.clear();
  }
}

class _ClientInfo {

  StreamController inbound;
  StreamSubscription containerSub;
  bool isActive = false;
  
  _ClientInfo();
  
}

_containerIsolate(initialMessage){
  var receiveFrom = new ReceivePort();
  var hello = initialMessage as _Hello;
  var clients = new Map<String, _ClientInfo>();

  hello.factory.create().then((MessageHandlerContainer container){
 //  print('created');
    container.start().then((_){
      
      receiveFrom.listen((poolMessage){
        if(poolMessage is _Forward){
          clients[poolMessage.client].inbound.add(poolMessage.data); 
        } else if(poolMessage is _Assign){

          var client = new _ClientInfo();
          client.inbound = new StreamController();
          var outbound = container.attach(client.inbound);
          var sub = outbound.listen((containerMessage){
            if(client.isActive) {
              hello.replyTo.send(new _Forward(poolMessage.client,containerMessage));
            }
          }, onDone:(){
            //container canceled
            if(client.isActive){
              client.isActive = false;
              client.inbound.close();
              clients.remove(poolMessage.client);
              hello.replyTo.send(new _Cancel(poolMessage.client));
            }
          });
          clients[poolMessage.client] = client;
        } else if (poolMessage is _Cancel){
          //server canceled
          var client = clients.remove(poolMessage.client);
          client.isActive = false;
          client.containerSub.cancel();
          client.inbound.close();
        }
        else  {
          container.stop();
        }
      });
     // print('online');
      hello.replyTo.send(new _Ready(receiveFrom.sendPort));
      
    });
      
    
  });
  
  
}