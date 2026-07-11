abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String username;
  final String password;
  final String fullName;

  RegisterEvent({
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
  });
}

class LogoutEvent extends AuthEvent {}