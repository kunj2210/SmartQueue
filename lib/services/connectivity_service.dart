import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'hive_service.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final FirebaseService _firebaseService;
  final HiveService _hiveService;

  ConnectivityService(this._firebaseService, this._hiveService) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      if (wasOffline && _isOnline) {
        _firebaseService.syncPendingAppointments(_hiveService);
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }
}
