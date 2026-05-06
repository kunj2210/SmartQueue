import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';
import '../services/connectivity_service.dart';
import '../utils/app_constants.dart';
import '../utils/id_generator.dart';

class AppointmentProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final HiveService _hiveService;
  final ConnectivityService _connectivityService;

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterDate;
  AppointmentStatus? _filterStatus;
  String? _filterServiceType;
  StreamSubscription? _firestoreSubscription;

  AppointmentProvider(
    this._firebaseService,
    this._hiveService,
    this._connectivityService,
  );

  List<AppointmentModel> get appointments {
    final hasFilters = _searchQuery.isNotEmpty ||
        _filterDate != null ||
        _filterStatus != null ||
        _filterServiceType != null;
    return hasFilters ? _filteredAppointments : _appointments;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserAppointments(String userId) async {
    _isLoading = true;
    notifyListeners();

    _appointments = await _hiveService.getUserAppointments(userId);
    _isLoading = false;
    notifyListeners();

    if (_connectivityService.isOnline) {
      _firestoreSubscription?.cancel();
      _firestoreSubscription =
          _firebaseService.getUserAppointments(userId).listen((list) {
        _appointments = list;
        for (final apt in list) {
          apt.isSynced = true;
          _hiveService.saveAppointment(apt);
        }
        _applyFilters(userId);
        notifyListeners();
      });
    }
  }

  Future<String?> bookAppointment({
    required String userId,
    required String userName,
    required String userEmail,
    required String serviceType,
    required String date,
    required String timeSlot,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final selectedDate = DateFormat('yyyy-MM-dd').parse(date);
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      if (selectedDate.isBefore(todayMidnight)) {
        throw Exception('Cannot book appointments in the past.');
      }

      bool slotAvailable;
      if (_connectivityService.isOnline) {
        slotAvailable = await _firebaseService.checkSlotAvailability(
          date, timeSlot, serviceType);
      } else {
        slotAvailable = await _hiveService.checkLocalSlotAvailability(
          date, timeSlot, serviceType);
      }
      if (!slotAvailable) {
        throw Exception(
          'This slot is fully booked (max ${AppConstants.maxAppointmentsPerSlot}). '
          'Please choose another time.',
        );
      }

      final duplicate = _appointments.any((a) =>
          a.preferredDate == date &&
          a.timeSlot == timeSlot &&
          a.serviceType == serviceType &&
          a.status != AppointmentStatus.cancelled);
      if (duplicate) {
        throw Exception('You already have a booking for this slot.');
      }

      final aptId = IdGenerator.generateAppointmentId();
      int queuePos = 1;
      if (_connectivityService.isOnline) {
        queuePos =
            await _firebaseService.getNextQueuePosition(date, serviceType);
      } else {
        queuePos = _appointments
                .where((a) =>
                    a.preferredDate == date &&
                    a.serviceType == serviceType &&
                    a.status != AppointmentStatus.cancelled)
                .length +
            1;
      }

      final apt = AppointmentModel(
        appointmentId: aptId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        serviceType: serviceType,
        preferredDate: date,
        timeSlot: timeSlot,
        queuePosition: queuePos,
        statusIndex: AppointmentStatus.scheduled.index,
        isSynced: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _hiveService.saveAppointment(apt);
      _appointments.insert(0, apt);
      notifyListeners();

      if (_connectivityService.isOnline) {
        await _firebaseService.saveAppointment(apt);
        apt.isSynced = true;
        await apt.save();
        await _firebaseService.initializeQueue(date, serviceType, queuePos);
      }

      _isLoading = false;
      notifyListeners();
      return aptId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelAppointment(String aptId) async {
    await _hiveService.updateStatus(aptId, AppointmentStatus.cancelled);
    if (_connectivityService.isOnline) {
      await _firebaseService.cancelAppointment(aptId);
    }
    final idx = _appointments.indexWhere((a) => a.appointmentId == aptId);
    if (idx != -1) {
      _appointments[idx].status = AppointmentStatus.cancelled;
      notifyListeners();
    }
  }

  void searchAppointments(String query, String userId) {
    _searchQuery = query;
    _applyFilters(userId);
    notifyListeners();
  }

  void applyFilter({
    String? date,
    AppointmentStatus? status,
    String? serviceType,
    required String userId,
  }) {
    _filterDate = date;
    _filterStatus = status;
    _filterServiceType = serviceType;
    _applyFilters(userId);
    notifyListeners();
  }

  void clearFilters(String userId) {
    _searchQuery = '';
    _filterDate = null;
    _filterStatus = null;
    _filterServiceType = null;
    _filteredAppointments = [];
    notifyListeners();
  }

  void _applyFilters(String userId) {
    _filteredAppointments = _appointments.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!a.userName.toLowerCase().contains(q) &&
            !a.appointmentId.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterDate != null && a.preferredDate != _filterDate) return false;
      if (_filterStatus != null && a.status != _filterStatus) return false;
      if (_filterServiceType != null && a.serviceType != _filterServiceType) {
        return false;
      }
      return true;
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
