import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class PaymentRepository {
  Box<Payment> get _box => Hive.box<Payment>(AppConstants.paymentBox);

  Future<void> addPayment(Payment payment) async {
    await _box.put(payment.id, payment);
  }

  Future<void> updatePayment(Payment payment) async {
    payment.updatedAt = DateTime.now();
    await _box.put(payment.id, payment);
  }

  /// Void a payment (soft delete — never hard delete payment records).
  Future<void> voidPayment(String id) async {
    final payment = _box.get(id);
    if (payment != null) {
      payment.isVoided = true;
      payment.updatedAt = DateTime.now();
      await payment.save();
    }
  }

  Payment? getPayment(String id) => _box.get(id);

  List<Payment> getPaymentsForCustomer(String customerId) =>
      _box.values
          .where((p) => p.customerId == customerId && !p.isVoided)
          .toList()
        ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

  List<Payment> getPaymentsForMonth(String customerId, int year, int month) {
    return _box.values
        .where((p) =>
            p.customerId == customerId &&
            !p.isVoided &&
            p.paymentDate.year == year &&
            p.paymentDate.month == month)
        .toList()
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
  }

  /// Total active (non-voided) payments for a customer across all time.
  int getTotalPaymentsPaisa(String customerId) {
    return _box.values
        .where((p) => p.customerId == customerId && !p.isVoided)
        .fold(0, (sum, p) => sum + p.amountPaisa);
  }

  /// Get all payments across all customers (newest first).
  List<Payment> getAllPayments() =>
      _box.values.where((p) => !p.isVoided).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  /// Get all payments across all customers for a specific month.
  List<Payment> getAllPaymentsForMonth(int year, int month) =>
      _box.values
          .where((p) =>
              !p.isVoided &&
              p.paymentDate.year == year &&
              p.paymentDate.month == month)
          .toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  Stream<BoxEvent> watchAll() => _box.watch();
}
