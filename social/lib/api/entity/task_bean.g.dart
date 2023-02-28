// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskBeanAdapter extends TypeAdapter<TaskBean> {
  @override
  final int typeId = 15;

  @override
  TaskBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskBean()
      ..messageId = fields[0] as String
      ..undoneChannel = fields[1] as String
      ..guildId = fields[2] as String
      ..channelId = fields[3] as String
      ..taskMessageId = fields[4] as String
      ..sendId = fields[5] as String
      ..status = fields[6] as int;
  }

  @override
  void write(BinaryWriter writer, TaskBean obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.undoneChannel)
      ..writeByte(2)
      ..write(obj.guildId)
      ..writeByte(3)
      ..write(obj.channelId)
      ..writeByte(4)
      ..write(obj.taskMessageId)
      ..writeByte(5)
      ..write(obj.sendId)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
