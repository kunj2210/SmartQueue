import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';

class QueueProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  QueueModel? _queueModel;
  StreamSubscription? _subscription;

  QueueProvider(this._firebaseService);

  QueueModel? get queueModel => _queueModel;

  int getEstimatedWait(int userQueuePosition) {
    if (_queueModel == null) return 0;
    final ahead = userQueuePosition - _queueModel!.currentToken - 1;
    if (ahead <= 0) return 0;
    return ahead * _queueModel!.avgServiceTimeMinutes;
  }

  void listenToQueue(String date, String serviceType) {
    _subscription?.cancel();
    _subscription =
        _firebaseService.listenToQueue(date, serviceType).listen((queue) {
      _queueModel = queue;
      notifyListeners();
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _queueModel = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
