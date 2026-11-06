import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'shop_profile.g.dart';

@HiveType(typeId: AppConstants.shopProfileTypeId)
class ShopProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String ownerName;

  @HiveField(2)
  String shopName;

  @HiveField(3)
  String address;

  @HiveField(4)
  String phoneNumber;

  @HiveField(5)
  String? logoPath; // local file path

  @HiveField(6)
  String currencyCode; // default: NPR

  @HiveField(7)
  String currencySymbol; // default: Rs.

  @HiveField(8)
  int defaultBreakfastPricePaisa;

  @HiveField(9)
  int defaultDinnerPricePaisa;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  ShopProfile({
    required this.id,
    required this.ownerName,
    required this.shopName,
    required this.address,
    required this.phoneNumber,
    this.logoPath,
    this.currencyCode = AppConstants.currencyCode,
    this.currencySymbol = AppConstants.currencySymbol,
    this.defaultBreakfastPricePaisa = AppConstants.defaultBreakfastPricePaisa,
    this.defaultDinnerPricePaisa = AppConstants.defaultDinnerPricePaisa,
    required this.createdAt,
    required this.updatedAt,
  });
}
