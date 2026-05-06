import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment_model.dart';
import '../models/queue_model.dart';
import '../utils/app_constants.dart';

class HiveService {
  static Box<AppointmentModel>? _appointmentsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppointmentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppointmentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(QueueModelAdapter());
    }
    _appointmentsBox = await Hive.openBox<AppointmentModel>(
      AppConstants.appointmentsBox,
    );
  }

  Box<AppointmentModel> get box => _appointmentsBox!;

  Future<void> saveAppointment(AppointmentModel apt) async {
    await box.put(apt.appointmentId, apt);
  }

  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    return box.values.where((a) => a.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<AppointmentModel>> getAllAppointments() async {
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<AppointmentModel>> getUnsyncedAppointments() async {
    return box.values.where((a) => !a.isSynced).toList();
  }

  Future<void> updateStatus(String aptId, AppointmentStatus status) async {
    final apt = box.get(aptId);
    if (apt != null) {
      apt.status = status;
      await apt.save();
    }
  }

  Future<void> deleteAppointment(String aptId) async {
    await box.delete(aptId);
  }

  Future<List<AppointmentModel>> searchByNameOrId(
      String query, String userId) async {
    final q = query.toLowerCase();
    return box.values
        .where((a) =>
            a.userId == userId &&
            (a.userName.toLowerCase().contains(q) ||
                a.appointmentId.toLowerCase().contains(q)))
        .toList();
  }

  Future<List<AppointmentModel>> filterAppointments({
    required String userId,
    String? date,
    AppointmentStatus? status,
    String? serviceType,
  }) async {
    return box.values.where((a) {
      if (a.userId != userId) return false;
      if (date != null && a.preferredDate != date) return false;
      if (status != null && a.status != status) return false;
      if (serviceType != null && a.serviceType != serviceType) return false;
      return true;
    }).toList();
  }

  Future<bool> checkLocalSlotAvailability(
    String date,
    String timeSlot,
    String serviceType,
  ) async {
    final count = box.values.where((a) {
      return a.preferredDate == date &&
          a.timeSlot == timeSlot &&
          a.serviceType == serviceType &&
          a.status != AppointmentStatus.cancelled;
    }).length;
    return count < AppConstants.maxAppointmentsPerSlot;
  }
}
