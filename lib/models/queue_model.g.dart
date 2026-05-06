// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueueModelAdapter extends TypeAdapter<QueueModel> {
  @override
  final int typeId = 2;

  @override
  QueueModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueueModel(
      queueId: fields[0] as String,
      date: fields[1] as String,
      serviceType: fields[2] as String,
      currentToken: fields[3] as int,
      totalAppointments: fields[4] as int,
      avgServiceTimeMinutes: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QueueModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.queueId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.serviceType)
      ..writeByte(3)
      ..write(obj.currentToken)
      ..writeByte(4)
      ..write(obj.totalAppointments)
      ..writeByte(5)
      ..write(obj.avgServiceTimeMinutes);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
