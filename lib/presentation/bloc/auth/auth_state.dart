abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String email;
  final String username;
  final String? conversationId;

  AuthSuccess({required this.email, required this.username, this.conversationId});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({required this.message});
}