import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'menu_item.g.dart';

@HiveType(typeId: AppConstants.menuItemTypeId)
class MenuItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  MenuCategory category;

  @HiveField(3)
  String unit; // e.g. "serving", "piece", "plate"

  @HiveField(4)
  int pricePaisa;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.pricePaisa,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

@HiveType(typeId: AppConstants.menuCategoryTypeId)
enum MenuCategory {
  @HiveField(0)
  meal,
  @HiveField(1)
  beverage,
  @HiveField(2)
  dairy,
  @HiveField(3)
  extra,
}
