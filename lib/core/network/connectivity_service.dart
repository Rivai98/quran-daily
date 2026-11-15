import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device currently has a usable network connection.
abstract class ConnectivityService {
  Stream<bool> get online;
  Future<bool> get isOnline;
}

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool>? _online;

  @override
  Stream<bool> get online {
    return _online ??= _connectivity.onConnectivityChanged.map(_isConnected);
  }

  @override
  Future<bool> get isOnline async =>
      _isConnected(await _connectivity.checkConnectivity());

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
