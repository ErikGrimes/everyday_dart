import 'dart:html';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:everyday_dart/rpc/invoker.dart';
import 'package:everyday_dart/aai/shared.dart';

@CustomTag('everyday-showcase-access-panel')
class EverydayShowcaseAccessPanel extends PolymerElement with ObservableMixin  {
  
  static final Logger _logger = new Logger('access_panel');
  
  //TODO treat this like a form with inline validation
  //TODO show password toggle
  //TODO hide delay
  @observable
  String email = '';
  
  @observable
  String password = '';
  
  @observable
  bool disabled = false;
  
  @observable
  Invoker invoker;
  
  signIn(MouseEvent event){
   disabled = true;
    var authToken = new EmailPasswordToken(email, password);
    _logger.info('Sign in requested.');
    invoker.call('access', 'signIn', InvocationType.INVOKE, positional:[authToken],timeout: timeout).then((e){
      disabled = false; 
      _logger.info('Sign in successful.');
      Observable.dirtyCheck();
    }).catchError((e){
      //TODO display error
      disabled = false; 
      _logger.info('Sign in unsuccessful. ${e}');
      Observable.dirtyCheck();
    });

   
  }
  
}
