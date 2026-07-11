import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      print('╔══════════════════════════════════════╗');
      print('║         REGISTER REQUEST              ║');
      print('╚══════════════════════════════════════╝');
      print('>>> URL   : ${ApiConstants.baseUrl}${ApiConstants.register}');
      print('>>> BODY  : email=$email | username=$username | fullName=$fullName');

      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'username': username,
          'password': password,
          'fullName': fullName,
        },
      );

      print('✅ REGISTER SUCCESS');
      print('>>> STATUS : ${response.statusCode}');
      print('>>> DATA   : ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveToken(authResponse.token);
      return authResponse;

    } on DioException catch (e) {
      print('❌ REGISTER FAILED — DioException');
      print('>>> TYPE    : ${e.type}');
      print('>>> MESSAGE : ${e.message}');
      print('>>> URL     : ${e.requestOptions.uri}');
      print('>>> STATUS  : ${e.response?.statusCode}');
      print('>>> BODY    : ${e.response?.data}');

      // Give a meaningful message based on error type
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          print('>>> HINT: Backend unreachable or too slow. Check IP and port.');
          break;
        case DioExceptionType.connectionError:
          print('>>> HINT: Cannot connect. Is backend running? Is IP correct?');
          print('>>> HINT: Real device needs PC local IP, not 10.0.2.2');
          break;
        case DioExceptionType.badResponse:
          print('>>> HINT: Server responded with error ${e.response?.statusCode}');
          print('>>> HINT: Check Spring Boot logs for the full error.');
          break;
        default:
          print('>>> HINT: Unknown Dio error. Check stack trace.');
      }

      rethrow;

    } catch (e, stackTrace) {
      print('❌ REGISTER FAILED — Unknown Error');
      print('>>> ERROR      : $e');
      print('>>> STACKTRACE : $stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      print('╔══════════════════════════════════════╗');
      print('║           LOGIN REQUEST               ║');
      print('╚══════════════════════════════════════╝');
      print('>>> URL  : ${ApiConstants.baseUrl}${ApiConstants.login}');
      print('>>> BODY : email=$email');

      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('✅ LOGIN SUCCESS');
      print('>>> STATUS : ${response.statusCode}');
      print('>>> DATA   : ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveToken(authResponse.token);
      return authResponse;

    } on DioException catch (e) {
      print('❌ LOGIN FAILED — DioException');
      print('>>> TYPE    : ${e.type}');
      print('>>> MESSAGE : ${e.message}');
      print('>>> URL     : ${e.requestOptions.uri}');
      print('>>> STATUS  : ${e.response?.statusCode}');
      print('>>> BODY    : ${e.response?.data}');

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          print('>>> HINT: Timeout. Is backend running on the correct port?');
          break;
        case DioExceptionType.connectionError:
          print('>>> HINT: Cannot connect. Real device needs your PC local IP.');
          print('>>> HINT: Run `ipconfig` → IPv4 → use that as baseUrl.');
          break;
        case DioExceptionType.badResponse:
          print('>>> HINT: HTTP ${e.response?.statusCode} from server.');
          if (e.response?.statusCode == 401) {
            print('>>> HINT: Wrong credentials.');
          } else if (e.response?.statusCode == 404) {
            print('>>> HINT: Endpoint not found. Check ApiConstants paths.');
          } else if (e.response?.statusCode == 500) {
            print('>>> HINT: Backend threw an exception. Check Spring Boot logs.');
          }
          break;
        default:
          print('>>> HINT: Unknown Dio error.');
      }

      rethrow;

    } catch (e, stackTrace) {
      print('❌ LOGIN FAILED — Unknown Error');
      print('>>> ERROR      : $e');
      print('>>> STACKTRACE : $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    print('>>> TOKEN SAVED: ${token.substring(0, 20)}...');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    print('>>> TOKEN CLEARED — User logged out');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString(AppConstants.tokenKey) != null;
    print('>>> IS LOGGED IN: $hasToken');
    return hasToken;
  }
}