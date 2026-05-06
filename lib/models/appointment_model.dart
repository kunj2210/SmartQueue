import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

@HiveType(typeId: 1)
enum AppointmentStatus {
  @HiveField(0)
  scheduled,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,

  @HiveField(3)
  cancelled,
}

@HiveType(typeId: 0)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  String appointmentId;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String userName;

  @HiveField(3)
  String userEmail;

  @HiveField(4)
  String serviceType;

  @HiveField(5)
  String preferredDate;

  @HiveField(6)
  String timeSlot;

  @HiveField(7)
  int queuePosition;

  @HiveField(8)
  int statusIndex;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  String createdAt;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.serviceType,
    required this.preferredDate,
    required this.timeSlot,
    required this.queuePosition,
    required this.statusIndex,
    required this.isSynced,
    required this.createdAt,
  });

  AppointmentStatus get status => AppointmentStatus.values[statusIndex];
  set status(AppointmentStatus s) => statusIndex = s.index;

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      appointmentId: map['appointmentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      serviceType: map['serviceType'] ?? '',
      preferredDate: map['preferredDate'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      queuePosition: map['queuePosition'] ?? 0,
      statusIndex: map['statusIndex'] ?? 0,
      isSynced: map['isSynced'] ?? true,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'serviceType': serviceType,
      'preferredDate': preferredDate,
      'timeSlot': timeSlot,
      'queuePosition': queuePosition,
      'statusIndex': statusIndex,
      'isSynced': isSynced,
      'createdAt': createdAt,
    };
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? userId,
    String? userName,
    String? userEmail,
    String? serviceType,
    String? preferredDate,
    String? timeSlot,
    int? queuePosition,
    int? statusIndex,
    bool? isSynced,
    String? createdAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      serviceType: serviceType ?? this.serviceType,
      preferredDate: preferredDate ?? this.preferredDate,
      timeSlot: timeSlot ?? this.timeSlot,
      queuePosition: queuePosition ?? this.queuePosition,
      statusIndex: statusIndex ?? this.statusIndex,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
