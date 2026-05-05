import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;
  bool _seeded = false;

  ConnectivityService() {
    // Seed before the listener fires, otherwise isOnline reads `true` until
    // the first connectivity *change* — which hides cold-start offline.
    // _seeded gates both branches so they don't double-emit if the listener
    // and the seed Future race.
    Connectivity().checkConnectivity().then((result) {
      if (_seeded) return;
      _seeded = true;
      _online = _hasNetwork(result);
      debugPrint('[conn] initial state: ${_online ? "ONLINE" : "OFFLINE"} ($result)');
      _controller.add(_online);
    });

    // Skip re-emits with the same boolean — the platform stream replays the
    // current value on subscribe and we don't want a phantom syncPending.
    Connectivity().onConnectivityChanged.listen((result) {
      final next = _hasNetwork(result);
      if (_seeded && next == _online) return;
      final wasOnline = _online;
      _online = next;
      _seeded = true;
      debugPrint(
          '[conn] transition: ${wasOnline ? "ONLINE" : "OFFLINE"} → ${_online ? "ONLINE" : "OFFLINE"} ($result)');
      _controller.add(_online);
    });
  }

  bool _hasNetwork(List<ConnectivityResult> results) => results.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet);

  bool get isOnline => _online;
  Stream<bool> get changes => _controller.stream;
}
