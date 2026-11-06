import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class MonthlyBillRepository {
  Box<MonthlyBill> get _box =>
      Hive.box<MonthlyBill>(AppConstants.monthlyBillBox);

  Future<void> saveBill(MonthlyBill bill) async {
    await _box.put(bill.id, bill);
  }

  Future<void> updateBill(MonthlyBill bill) async {
    bill.updatedAt = DateTime.now();
    await _box.put(bill.id, bill);
  }

  MonthlyBill? getBill(String id) => _box.get(id);

  MonthlyBill? getBillForMonth(String customerId, int year, int month) {
    final matches = _box.values.where((b) =>
        b.customerId == customerId &&
        b.billingYear == year &&
        b.billingMonth == month);
    return matches.isEmpty ? null : matches.first;
  }

  List<MonthlyBill> getBillsForCustomer(String customerId) =>
      _box.values.where((b) => b.customerId == customerId).toList()
        ..sort((a, b) {
          final yearCmp = a.billingYear.compareTo(b.billingYear);
          return yearCmp != 0
              ? yearCmp
              : a.billingMonth.compareTo(b.billingMonth);
        });

  List<MonthlyBill> getAllBillsForMonth(int year, int month) =>
      _box.values
          .where((b) => b.billingYear == year && b.billingMonth == month)
          .toList();
}
