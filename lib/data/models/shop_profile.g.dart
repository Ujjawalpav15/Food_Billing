// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopProfileAdapter extends TypeAdapter<ShopProfile> {
  @override
  final typeId = 0;

  @override
  ShopProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopProfile(
      id: fields[0] as String,
      ownerName: fields[1] as String,
      shopName: fields[2] as String,
      address: fields[3] as String,
      phoneNumber: fields[4] as String,
      logoPath: fields[5] as String?,
      currencyCode:
          fields[6] == null ? AppConstants.currencyCode : fields[6] as String,
      currencySymbol:
          fields[7] == null ? AppConstants.currencySymbol : fields[7] as String,
      defaultBreakfastPricePaisa: fields[8] == null
          ? AppConstants.defaultBreakfastPricePaisa
          : (fields[8] as num).toInt(),
      defaultDinnerPricePaisa: fields[9] == null
          ? AppConstants.defaultDinnerPricePaisa
          : (fields[9] as num).toInt(),
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShopProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerName)
      ..writeByte(2)
      ..write(obj.shopName)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.logoPath)
      ..writeByte(6)
      ..write(obj.currencyCode)
      ..writeByte(7)
      ..write(obj.currencySymbol)
      ..writeByte(8)
      ..write(obj.defaultBreakfastPricePaisa)
      ..writeByte(9)
      ..write(obj.defaultDinnerPricePaisa)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
