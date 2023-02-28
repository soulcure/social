// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dlog_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DLogReportModelAdapter extends TypeAdapter<DLogReportModel> {
  @override
  final int typeId = 17;

  @override
  DLogReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DLogReportModel(
      dlogContentID: fields[0] as String,
      dlogContent: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DLogReportModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dlogContentID)
      ..writeByte(1)
      ..write(obj.dlogContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DLogReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
