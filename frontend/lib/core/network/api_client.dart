import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio dio;

  // Separate Dio for prefetch — different timeouts and we don't want it
  // sharing the API client's interceptors (it hits absolute video URLs, not
  // baseUrl-relative paths).
  final Dio _prefetchDio;

  final Set<String> _prefetchInFlight = <String>{};
  final Set<String> _prefetchDone = <String>{};

  ApiClient({required String baseUrl, String userId = 'demo-user'})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'x-user-id': userId, 'content-type': 'application/json'},
        )),
        _prefetchDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
          responseType: ResponseType.bytes,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) => handler.next(err),
    ));
  }

  /// Warm the OS HTTP cache with the first chunk of [url] so a later
  /// VideoPlayerController.initialize() finds bytes locally instead of going
  /// over the network. 512KB covers the moov atom + first few seconds for
  /// reel-sized mp4s; 256KB sometimes wasn't enough on bigger clips.
  ///
  /// Best-effort. Dedup'd by URL — same URL won't be re-prefetched in a session.
  Future<void> prefetchRange(String url, {int bytes = 262143}) async {
    if (url.isEmpty) return;
    if (_prefetchDone.contains(url)) return;
    if (_prefetchInFlight.contains(url)) return;
    _prefetchInFlight.add(url);
    final start = DateTime.now();
    try {
      final r = await _prefetchDio.get<List<int>>(
        url,
        options: Options(
          headers: {'Range': 'bytes=0-$bytes'},
          // Some proxies strip Range and return the whole file. Still useful —
          // the cache is warmer either way.
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      _prefetchDone.add(url);
      final ms = DateTime.now().difference(start).inMilliseconds;
      final got = r.data?.length ?? 0;
      final shortUrl = url.length > 60 ? '...${url.substring(url.length - 60)}' : url;
      debugPrint('[prefetch] ⚡ $shortUrl  range 0-$bytes  got=${got}B  in ${ms}ms');
    } catch (e) {
      final shortUrl = url.length > 60 ? '...${url.substring(url.length - 60)}' : url;
      debugPrint('[prefetch] ⚠ $shortUrl  failed (will recover on play): $e');
    } finally {
      _prefetchInFlight.remove(url);
    }
  }
}
