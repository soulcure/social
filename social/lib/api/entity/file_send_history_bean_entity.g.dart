// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_send_history_bean_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileSendHistoryBeanEntityAdapter
    extends TypeAdapter<FileSendHistoryBeanEntity> {
  @override
  final int typeId = 19;

  @override
  FileSendHistoryBeanEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileSendHistoryBeanEntity(
      name: fields[0] as String,
      size: fields[1] as int,
      updateTime: fields[2] as int,
      path: fields[3] as String,
      fileHash: fields[4] as String,
      fileUrl: fields[5] as String,
      bucketId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileSendHistoryBeanEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.size)
      ..writeByte(2)
      ..write(obj.updateTime)
      ..writeByte(3)
      ..write(obj.path)
      ..writeByte(4)
      ..write(obj.fileHash)
      ..writeByte(5)
      ..write(obj.fileUrl)
      ..writeByte(6)
      ..write(obj.bucketId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSendHistoryBeanEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
