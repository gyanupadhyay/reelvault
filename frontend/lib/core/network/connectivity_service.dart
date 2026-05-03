import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;
  bool _seeded = false;

  ConnectivityService() {
    // Seed with the actual current state — without this, isOnline stays true
    // until the first connectivity *change* event, which masks cold-start offline.
    // The double-guard below (check `_seeded` BOTH before mutating state AND before
    // emitting) closes a narrow race where the platform listener fires the same
    // value at almost the same instant as the seed Future resolving, which would
    // otherwise trigger two `syncPending` ticks back-to-back.
    Connectivity().checkConnectivity().then((result) {
      if (_seeded) return; // listener beat us to it
      final next = _hasNetwork(result);
      _seeded = true;
      _online = next;
      debugPrint('[conn] initial state: ${_online ? "ONLINE" : "OFFLINE"} ($result)');
      _controller.add(_online);
    });

    // Only emit when the boolean actually flips. The platform stream re-fires
    // with the current value on subscribe, which would otherwise trigger a
    // duplicate syncPending right after the seed above.
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
