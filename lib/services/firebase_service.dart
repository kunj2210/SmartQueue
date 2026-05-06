import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/queue_model.dart';
import '../utils/app_constants.dart';
import 'hive_service.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── APPOINTMENTS ──────────────────────────────────────────

  Future<void> saveAppointment(AppointmentModel apt) async {
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(apt.appointmentId)
        .set(apt.toMap());
  }

  Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppointmentModel.fromMap(d.data())).toList());
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppointmentModel.fromMap(d.data())).toList());
  }

  Stream<List<AppointmentModel>> getAppointmentsByDate(String date) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('preferredDate', isEqualTo: date)
        .orderBy('queuePosition')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppointmentModel.fromMap(d.data())).toList());
  }

  Future<void> updateStatus(String aptId, AppointmentStatus status) async {
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(aptId)
        .update({'statusIndex': status.index});
  }

  Future<void> rescheduleAppointment(
    String aptId,
    String newDate,
    String newTimeSlot,
  ) async {
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(aptId)
        .update({
      'preferredDate': newDate,
      'timeSlot': newTimeSlot,
      'statusIndex': AppointmentStatus.scheduled.index,
    });
  }

  Future<void> cancelAppointment(String aptId) async {
    await updateStatus(aptId, AppointmentStatus.cancelled);
  }

  // ── CONFLICT DETECTION ────────────────────────────────────

  Future<bool> checkSlotAvailability(
    String date,
    String timeSlot,
    String serviceType,
  ) async {
    final snap = await _db
        .collection(AppConstants.appointmentsCollection)
        .where('preferredDate', isEqualTo: date)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('serviceType', isEqualTo: serviceType)
        .get();
    final active = snap.docs.where((d) {
      final statusIndex = d.data()['statusIndex'] as int? ?? 0;
      return statusIndex != AppointmentStatus.cancelled.index;
    }).length;
    return active < AppConstants.maxAppointmentsPerSlot;
  }

  Future<int> getNextQueuePosition(String date, String serviceType) async {
    final snap = await _db
        .collection(AppConstants.appointmentsCollection)
        .where('preferredDate', isEqualTo: date)
        .where('serviceType', isEqualTo: serviceType)
        .get();
    final active = snap.docs.where((d) {
      final statusIndex = d.data()['statusIndex'] as int? ?? 0;
      return statusIndex != AppointmentStatus.cancelled.index;
    }).length;
    return active + 1;
  }

  // ── QUEUE ─────────────────────────────────────────────────

  Stream<QueueModel?> listenToQueue(String date, String serviceType) {
    final queueId = '${date}_${serviceType.replaceAll(' ', '')}';
    return _db
        .collection(AppConstants.queuesCollection)
        .doc(queueId)
        .snapshots()
        .map((snap) => snap.exists ? QueueModel.fromMap(snap.data()!) : null);
  }

  Future<void> moveQueueForward(String date, String serviceType) async {
    final queueId = '${date}_${serviceType.replaceAll(' ', '')}';
    await _db.collection(AppConstants.queuesCollection).doc(queueId).set({
      'currentToken': FieldValue.increment(1),
      'date': date,
      'serviceType': serviceType,
      'queueId': queueId,
      'avgServiceTimeMinutes': AppConstants.avgServiceTimeMinutes,
    }, SetOptions(merge: true));
  }

  Future<void> initializeQueue(
    String date,
    String serviceType,
    int totalAppointments,
  ) async {
    final queueId = '${date}_${serviceType.replaceAll(' ', '')}';
    final doc =
        await _db.collection(AppConstants.queuesCollection).doc(queueId).get();
    if (!doc.exists) {
      await _db.collection(AppConstants.queuesCollection).doc(queueId).set({
        'queueId': queueId,
        'date': date,
        'serviceType': serviceType,
        'currentToken': 0,
        'totalAppointments': totalAppointments,
        'avgServiceTimeMinutes': AppConstants.avgServiceTimeMinutes,
      });
    } else {
      await _db
          .collection(AppConstants.queuesCollection)
          .doc(queueId)
          .update({'totalAppointments': FieldValue.increment(1)});
    }
  }

  Future<void> resetQueue(String date, String serviceType) async {
    final queueId = '${date}_${serviceType.replaceAll(' ', '')}';
    await _db.collection(AppConstants.queuesCollection).doc(queueId).update({
      'currentToken': 0,
    });
  }

  // ── OFFLINE SYNC ──────────────────────────────────────────

  Future<void> syncPendingAppointments(HiveService hiveService) async {
    final unsynced = await hiveService.getUnsyncedAppointments();
    for (final apt in unsynced) {
      try {
        await saveAppointment(apt);
        apt.isSynced = true;
        await apt.save();
      } catch (_) {
        // Skip and try next time
      }
    }
  }
}
