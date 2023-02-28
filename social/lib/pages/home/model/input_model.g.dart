// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InputRecordAdapter extends TypeAdapter<InputRecord> {
  @override
  final int typeId = 3;

  @override
  InputRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InputRecord(
      replyId: fields[0] as String,
      content: fields[1] as String,
      richContent: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InputRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.replyId)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.richContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
