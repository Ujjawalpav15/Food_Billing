import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'additional_item_entry.g.dart';

/// Records a customer ordering an extra menu item on a given date.
/// unitPricePaisa is preserved at time of recording so menu price changes don't affect history.
@HiveType(typeId: AppConstants.additionalItemEntryTypeId)
class AdditionalItemEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String menuItemId;

  @HiveField(3)
  String menuItemName; // snapshot for display, in case item is deleted

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  int unitPricePaisa; // price at time of recording

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  AdditionalItemEntry({
    required this.id,
    required this.customerId,
    required this.menuItemId,
    required this.menuItemName,
    required this.date,
    required this.quantity,
    required this.unitPricePaisa,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total charge in paisa (quantity × unitPrice).
  int get totalPaisa => quantity * unitPricePaisa;
}
