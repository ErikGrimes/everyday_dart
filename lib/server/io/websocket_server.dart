library everyday.server.io.websocket;

import 'dart:async';
import 'dart:io' as io;

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
  static final String DEFAULT_ENABLE_ISOLATE_POOL = 'false';
  
  static final String MAX_CLIENTS_PER_ISOLATE_KEY= 'max_clients_isolate';
  static final String DEFAULT_MAX_CLIENTS_PER_ISOLATE  = null;
  
  static final String MIN_ISOLATE_POOL_SIZE_KEY= 'min_isolate_pool_size';
  static final String DEFAULT_MIN_ISOLATE_POOL_SIZE = '0';

  static final String MAX_ISOLATE_POOL_SIZE_KEY= 'max_isolate_pool_size';
  static final String DEFAULT_MAX_ISOLATE_POOL_SIZE = '1';

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
    return _args[MIN_ISOLATE_POOL_SIZE_KEY] != null ? int.parse(_args[MIN_ISOLATE_POOL_SIZE_KEY]) : DEFAULT_MIN_ISOLATE_POOL_SIZE;
  }
  
  int get maxIsolatePoolSize {
    return _args[MAX_ISOLATE_POOL_SIZE_KEY] != null ? int.parse(_args[MAX_ISOLATE_POOL_SIZE_KEY]) : DEFAULT_MAX_ISOLATE_POOL_SIZE;
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
      throw new UnimplementedError();
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
      return io.HttpServer.bind(_settings.listenOnAddress, _settings.listenOnPort);
    }else {
      io.SecureSocket.initialize(database: _settings.certDb);
      return io.HttpServer.bindSecure(_settings.listenOnAddress, _settings.listenOnPort, 
          certificateName: _settings.certName);    
    }
  }
}

class _WebSocketTransformSink implements EventSink<io.HttpRequest> {
  static final Logger _LOGGER = new Logger('everyday.server.io.websocket_transformer');
  
  final EventSink<io.WebSocket> _outputSink;
  
  bool _discardRegular;
  
  _WebSocketTransformSink(this._outputSink, this._discardRegular);

  void add(io.HttpRequest request) {
    if(io.WebSocketTransformer.isUpgradeRequest(request)){
      _LOGGER.info('Upgrading websocket');
      _setResponseHeaders(request.response);
      io.WebSocketTransformer.upgrade(request)
        .then((io.WebSocket websocket){
          //websocket.pingInterval = new Duration(seconds:5);

          _outputSink.add(websocket);})
        
          .catchError((error){
            _outputSink.add(error);
          });
   }else if(_discardRegular){
     request.response.statusCode = io.HttpStatus.NOT_FOUND;
     request.response.close();
   }
  }

  void addError(e, [st]) => _outputSink.addError(e, st);
  void close() => _outputSink.close();
  
  void _setResponseHeaders(io.HttpResponse res) {
    res.headers.add("Access-Control-Allow-Origin", "*, ");
    res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  }
  
}

class WebSocketTransformer implements StreamTransformer<io.HttpRequest,io.WebSocket> {
  
  bool _discardRegular;
  
  WebSocketTransformer([discardRegular = true]): this._discardRegular = discardRegular;

  Stream<io.WebSocket> bind(Stream<io.HttpRequest> stream) =>
    new Stream<io.WebSocket>.eventTransformed(
        stream,
        (EventSink sink) => new _WebSocketTransformSink(sink, _discardRegular));
  
}


