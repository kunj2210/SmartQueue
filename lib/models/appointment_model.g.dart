// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 0;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentModel(
      appointmentId: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      userEmail: fields[3] as String,
      serviceType: fields[4] as String,
      preferredDate: fields[5] as String,
      timeSlot: fields[6] as String,
      queuePosition: fields[7] as int,
      statusIndex: fields[8] as int,
      isSynced: fields[9] as bool,
      createdAt: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.appointmentId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.userEmail)
      ..writeByte(4)
      ..write(obj.serviceType)
      ..writeByte(5)
      ..write(obj.preferredDate)
      ..writeByte(6)
      ..write(obj.timeSlot)
      ..writeByte(7)
      ..write(obj.queuePosition)
      ..writeByte(8)
      ..write(obj.statusIndex)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class AppointmentStatusAdapter extends TypeAdapter<AppointmentStatus> {
  @override
  final int typeId = 1;

  @override
  AppointmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppointmentStatus.scheduled;
      case 1:
        return AppointmentStatus.inProgress;
      case 2:
        return AppointmentStatus.completed;
      case 3:
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  @override
  void write(BinaryWriter writer, AppointmentStatus obj) {
    switch (obj) {
      case AppointmentStatus.scheduled:
        writer.writeByte(0);
        break;
      case AppointmentStatus.inProgress:
        writer.writeByte(1);
        break;
      case AppointmentStatus.completed:
        writer.writeByte(2);
        break;
      case AppointmentStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
