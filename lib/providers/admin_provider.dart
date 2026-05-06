import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final HiveService _hiveService;

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  bool _isLoading = false;
  String? _selectedDate;
  String? _selectedServiceType;
  StreamSubscription? _subscription;

  AdminProvider(this._firebaseService, this._hiveService);

  List<AppointmentModel> get allAppointments =>
      _filteredAppointments.isNotEmpty ||
              _selectedDate != null ||
              _selectedServiceType != null
          ? _filteredAppointments
          : _allAppointments;

  bool get isLoading => _isLoading;

  String get todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int get totalToday =>
      _allAppointments.where((a) => a.preferredDate == todayStr).length;

  int get completedToday => _allAppointments
      .where((a) =>
          a.preferredDate == todayStr &&
          a.status == AppointmentStatus.completed)
      .length;

  int get pendingToday => _allAppointments
      .where((a) =>
          a.preferredDate == todayStr &&
          a.status == AppointmentStatus.scheduled)
      .length;

  int get inProgressToday => _allAppointments
      .where((a) =>
          a.preferredDate == todayStr &&
          a.status == AppointmentStatus.inProgress)
      .length;

  void listenToAllAppointments() {
    _isLoading = true;
    notifyListeners();
    _subscription?.cancel();
    _subscription = _firebaseService.getAllAppointments().listen((list) {
      print('=== AdminProvider: Received ${list.length} appointments ===');
      _allAppointments = list;
      _isLoading = false;
      _applyAdminFilters();
      notifyListeners();
    }, onError: (e) {
      print('=== AdminProvider Error: $e ===');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsCompleted(
    String aptId,
    String date,
    String serviceType,
  ) async {
    await _firebaseService.updateStatus(aptId, AppointmentStatus.completed);
    await _firebaseService.moveQueueForward(date, serviceType);
    final idx = _allAppointments.indexWhere((a) => a.appointmentId == aptId);
    if (idx != -1) {
      _allAppointments[idx].status = AppointmentStatus.completed;
      notifyListeners();
    }
  }

  Future<void> markAsInProgress(String aptId) async {
    await _firebaseService.updateStatus(aptId, AppointmentStatus.inProgress);
    final idx = _allAppointments.indexWhere((a) => a.appointmentId == aptId);
    if (idx != -1) {
      _allAppointments[idx].status = AppointmentStatus.inProgress;
      notifyListeners();
    }
  }

  Future<void> moveQueueForward(String date, String serviceType) async {
    await _firebaseService.moveQueueForward(date, serviceType);
  }

  Future<void> cancelAppointment(String aptId) async {
    await _firebaseService.cancelAppointment(aptId);
    final idx = _allAppointments.indexWhere((a) => a.appointmentId == aptId);
    if (idx != -1) {
      _allAppointments[idx].status = AppointmentStatus.cancelled;
      notifyListeners();
    }
  }

  Future<void> rescheduleAppointment(
    String aptId,
    String newDate,
    String newTimeSlot,
  ) async {
    await _firebaseService.rescheduleAppointment(aptId, newDate, newTimeSlot);
    final idx = _allAppointments.indexWhere((a) => a.appointmentId == aptId);
    if (idx != -1) {
      _allAppointments[idx].preferredDate = newDate;
      _allAppointments[idx].timeSlot = newTimeSlot;
      notifyListeners();
    }
  }

  void filterByDate(String? date) {
    _selectedDate = date;
    _applyAdminFilters();
    notifyListeners();
  }

  void filterByServiceType(String? serviceType) {
    _selectedServiceType = serviceType;
    _applyAdminFilters();
    notifyListeners();
  }

  void searchAppointments(String query) {
    if (query.isEmpty) {
      _filteredAppointments = [];
    } else {
      final q = query.toLowerCase();
      _filteredAppointments = _allAppointments
          .where((a) =>
              a.userName.toLowerCase().contains(q) ||
              a.appointmentId.toLowerCase().contains(q) ||
              a.userEmail.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  void clearAdminFilters() {
    _selectedDate = null;
    _selectedServiceType = null;
    _filteredAppointments = [];
    notifyListeners();
  }

  void _applyAdminFilters() {
    if (_selectedDate == null && _selectedServiceType == null) {
      _filteredAppointments = [];
      return;
    }
    _filteredAppointments = _allAppointments.where((a) {
      if (_selectedDate != null && a.preferredDate != _selectedDate) {
        return false;
      }
      if (_selectedServiceType != null &&
          a.serviceType != _selectedServiceType) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
