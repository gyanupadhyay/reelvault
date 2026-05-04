// lib/core/network/api_client.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio dio;

  // Separate Dio instance for prefetch warmup. We don't want prefetch to
  // share interceptors / inherit the base URL constraint (videos are absolute
  // URLs that may not be relative to baseUrl), and we want a tighter timeout
  // so a slow prefetch can't queue up behind the active reel's network needs.
  final Dio _prefetchDio;

  // Track in-flight prefetches by URL so we don't double-fetch. Cleared on
  // completion (success or failure).
  final Set<String> _prefetchInFlight = <String>{};
  // Track URLs we've already prefetched in this session so we don't waste
  // bandwidth re-warming the same bytes.
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
          // Receive raw bytes — we throw them away, just want them in the OS
          // HTTP cache for ExoPlayer to pick up.
          responseType: ResponseType.bytes,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) {
        // Surface a normalized error so repos can fall back to cache.
        return handler.next(err);
      },
    ));
  }

  /// Prefetch the first [bytes] of [url] into the OS HTTP cache via a Range
  /// request. ExoPlayer (which video_player uses internally on Android) and
  /// AVPlayer (iOS) share the OS-level HTTP cache, so when the user actually
  /// swipes to this reel, the bytes are already on disk and `initialize()`
  /// resolves much faster.
  ///
  /// 256KB is enough to cover the mp4 moov atom + a few seconds of frames
  /// for short reel clips. Bigger wastes bandwidth if the user swipes past;
  /// smaller risks not covering the moov.
  ///
  /// No-op if [url] is empty, already done, or already in flight.
  /// Errors are swallowed — prefetch is best-effort by design.
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
          // Accept 200 (full body) as well as 206 (partial). Some proxies
          // strip the Range header and return the whole file; we still warm
          // the cache, just with a heavier payload.
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      _prefetchDone.add(url);
      final ms = DateTime.now().difference(start).inMilliseconds;
      final got = r.data?.length ?? 0;
      final shortUrl = url.length > 60 ? '...${url.substring(url.length - 60)}' : url;
      debugPrint('[prefetch] ⚡ $shortUrl  range 0-$bytes  got=${got}B  in ${ms}ms');
    } catch (e) {
      // Best-effort — don't surface errors. The actual play will do its own
      // request if the prefetched bytes aren't usable.
      final shortUrl = url.length > 60 ? '...${url.substring(url.length - 60)}' : url;
      debugPrint('[prefetch] ⚠ $shortUrl  failed (will recover on play): $e');
    } finally {
      _prefetchInFlight.remove(url);
    }
  }
}
