import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class AdjustmentRepository {
  Box<Adjustment> get _box =>
      Hive.box<Adjustment>(AppConstants.adjustmentBox);

  Future<void> addAdjustment(Adjustment adjustment) async {
    await _box.put(adjustment.id, adjustment);
  }

  Future<void> updateAdjustment(Adjustment adjustment) async {
    adjustment.updatedAt = DateTime.now();
    await _box.put(adjustment.id, adjustment);
  }

  Future<void> voidAdjustment(String id) async {
    final adj = _box.get(id);
    if (adj != null) {
      adj.isVoided = true;
      adj.updatedAt = DateTime.now();
      await adj.save();
    }
  }

  List<Adjustment> getAdjustmentsForCustomer(String customerId) =>
      _box.values
          .where((a) => a.customerId == customerId && !a.isVoided)
          .toList()
        ..sort((a, b) => a.adjustmentDate.compareTo(b.adjustmentDate));

  List<Adjustment> getAdjustmentsForMonth(
      String customerId, int year, int month) {
    return _box.values
        .where((a) =>
            a.customerId == customerId &&
            !a.isVoided &&
            a.adjustmentDate.year == year &&
            a.adjustmentDate.month == month)
        .toList()
      ..sort((a, b) => a.adjustmentDate.compareTo(b.adjustmentDate));
  }

  Stream<BoxEvent> watchAll() => _box.watch();
}
