import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'meal_entry.g.dart';

/// Tracks whether a customer had breakfast and/or dinner on a given date.
/// breakfastPricePaisa and dinnerPricePaisa record the price AT THE TIME of entry.
@HiveType(typeId: AppConstants.mealEntryTypeId)
class MealEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  DateTime date; // date only (time component should be normalized to midnight)

  @HiveField(3)
  bool hadBreakfast;

  @HiveField(4)
  bool hadDinner;

  @HiveField(5)
  int breakfastPricePaisa; // price at time of recording

  @HiveField(6)
  int dinnerPricePaisa; // price at time of recording

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  MealEntry({
    required this.id,
    required this.customerId,
    required this.date,
    required this.hadBreakfast,
    required this.hadDinner,
    required this.breakfastPricePaisa,
    required this.dinnerPricePaisa,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total charge for this meal entry in paisa.
  int get totalPaisa =>
      (hadBreakfast ? breakfastPricePaisa : 0) +
      (hadDinner ? dinnerPricePaisa : 0);
}
