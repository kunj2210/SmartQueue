import 'package:hive/hive.dart';

part 'queue_model.g.dart';

@HiveType(typeId: 2)
class QueueModel extends HiveObject {
  @HiveField(0)
  String queueId;

  @HiveField(1)
  String date;

  @HiveField(2)
  String serviceType;

  @HiveField(3)
  int currentToken;

  @HiveField(4)
  int totalAppointments;

  @HiveField(5)
  int avgServiceTimeMinutes;

  QueueModel({
    required this.queueId,
    required this.date,
    required this.serviceType,
    required this.currentToken,
    required this.totalAppointments,
    required this.avgServiceTimeMinutes,
  });

  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      queueId: map['queueId'] ?? '',
      date: map['date'] ?? '',
      serviceType: map['serviceType'] ?? '',
      currentToken: map['currentToken'] ?? 0,
      totalAppointments: map['totalAppointments'] ?? 0,
      avgServiceTimeMinutes: map['avgServiceTimeMinutes'] ?? 15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueId': queueId,
      'date': date,
      'serviceType': serviceType,
      'currentToken': currentToken,
      'totalAppointments': totalAppointments,
      'avgServiceTimeMinutes': avgServiceTimeMinutes,
    };
  }
}
