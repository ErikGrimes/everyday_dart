library everyday.aai.shared;

abstract class AuthToken {
  
}

class EmailPasswordToken extends AuthToken {
  final String email;
  final String password;
  
  EmailPasswordToken(this.email, this.password);
  EmailPasswordToken.empty():this('','');
  
}
