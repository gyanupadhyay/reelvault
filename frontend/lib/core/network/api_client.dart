// lib/core/network/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl, String userId = 'demo-user'})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'x-user-id': userId, 'content-type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) {
        // Surface a normalized error so repos can fall back to cache.
        return handler.next(err);
      },
    ));
  }
}
