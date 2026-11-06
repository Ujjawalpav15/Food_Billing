// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'additional_item_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdditionalItemEntryAdapter extends TypeAdapter<AdditionalItemEntry> {
  @override
  final typeId = 4;

  @override
  AdditionalItemEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdditionalItemEntry(
      id: fields[0] as String,
      customerId: fields[1] as String,
      menuItemId: fields[2] as String,
      menuItemName: fields[3] as String,
      date: fields[4] as DateTime,
      quantity: (fields[5] as num).toInt(),
      unitPricePaisa: (fields[6] as num).toInt(),
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AdditionalItemEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.menuItemId)
      ..writeByte(3)
      ..write(obj.menuItemName)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unitPricePaisa)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdditionalItemEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
