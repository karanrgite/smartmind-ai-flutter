import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _saveSession(String email, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _onLogin(
      LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      await _saveSession(response.email, response.username);

      String? conversationId;
      try {
        final convo = await ChatRepository().createConversation(response.username);
        conversationId = convo.id;
      } catch (e) {
        print('❌ CREATE CONVERSATION FAILED: $e');
      }
      emit(AuthSuccess(
        email: response.email,
        username: response.username,
        conversationId: conversationId,
      ));
    } catch (e) {
      emit(AuthFailure(message: 'Invalid email or password'));
    }
  }

  Future<void> _onRegister(
      RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.register(
        email: event.email,
        username: event.username,
        password: event.password,
        fullName: event.fullName,
      );
      await _saveSession(response.email, response.username);

      String? conversationId;
      try {
        final convo = await ChatRepository().createConversation(response.username);
        conversationId = convo.id;
      } catch (e) {
        print('❌ CREATE CONVERSATION FAILED: $e');
      }

      emit(AuthSuccess(
        email: response.email,
        username: response.username,
        conversationId: conversationId,
      ));
    } catch (e) {
      emit(AuthFailure(message: 'Registration failed. Try again.'));
    }
  }

  Future<void> _onLogout(
      LogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(AuthInitial());
  }
}