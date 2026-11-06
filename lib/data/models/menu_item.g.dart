// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final typeId = 2;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as MenuCategory,
      unit: fields[3] as String,
      pricePaisa: (fields[4] as num).toInt(),
      isActive: fields[5] == null ? true : fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.pricePaisa)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MenuCategoryAdapter extends TypeAdapter<MenuCategory> {
  @override
  final typeId = 10;

  @override
  MenuCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MenuCategory.meal;
      case 1:
        return MenuCategory.beverage;
      case 2:
        return MenuCategory.dairy;
      case 3:
        return MenuCategory.extra;
      default:
        return MenuCategory.meal;
    }
  }

  @override
  void write(BinaryWriter writer, MenuCategory obj) {
    switch (obj) {
      case MenuCategory.meal:
        writer.writeByte(0);
      case MenuCategory.beverage:
        writer.writeByte(1);
      case MenuCategory.dairy:
        writer.writeByte(2);
      case MenuCategory.extra:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
