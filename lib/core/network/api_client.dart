import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    print('>>> BASE URL IS: ${ApiConstants.baseUrl}');
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final friendlyMessage = _extractMessage(error);
        final wrappedError = DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: friendlyMessage,
          message: friendlyMessage,
        );
        handler.next(wrappedError);
      },
    ));
  }

  String _extractMessage(DioException error) {
    // Backend sent a structured error body — use its "message" field
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }

    // No response reached the server at all
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check your connection.';
      case DioExceptionType.connectionError:
        return 'Cannot reach server. Check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return error.response?.statusMessage ?? 'Something went wrong. Please try again.';
    }
  }

  Dio get dio => _dio;
}