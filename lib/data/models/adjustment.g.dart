// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdjustmentAdapter extends TypeAdapter<Adjustment> {
  @override
  final typeId = 6;

  @override
  Adjustment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Adjustment(
      id: fields[0] as String,
      customerId: fields[1] as String,
      adjustmentDate: fields[2] as DateTime,
      amountPaisa: (fields[3] as num).toInt(),
      reason: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      isVoided: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Adjustment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.adjustmentDate)
      ..writeByte(3)
      ..write(obj.amountPaisa)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isVoided);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
