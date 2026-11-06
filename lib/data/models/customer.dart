import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'customer.g.dart';

@HiveType(typeId: AppConstants.customerTypeId)
class Customer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phoneNumber;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? notes;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });
}
