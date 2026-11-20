import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class CustomerRepository {
  Box<Customer> get _box => Hive.box<Customer>(AppConstants.customerBox);

  /// Add a new customer.
  Future<void> addCustomer(Customer customer) async {
    await _box.put(customer.id, customer);
  }

  /// Update an existing customer.
  Future<void> updateCustomer(Customer customer) async {
    customer.updatedAt = DateTime.now();
    await _box.put(customer.id, customer);
  }

  /// Get a customer by ID.
  Customer? getCustomer(String id) => _box.get(id);

  /// Get all customers.
  List<Customer> getAllCustomers() => _box.values.toList();

  /// Get only active customers, sorted by name.
  List<Customer> getActiveCustomers() =>
      _box.values.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// Search customers by name (case-insensitive).
  List<Customer> searchCustomers(String query) {
    final lower = query.toLowerCase();
    return _box.values
        .where((c) => c.name.toLowerCase().contains(lower))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Deactivate a customer. Never hard-deletes.
  Future<void> deactivateCustomer(String id) async {
    final customer = _box.get(id);
    if (customer != null) {
      customer.isActive = false;
      customer.updatedAt = DateTime.now();
      await customer.save();
    }
  }

  /// Reactivate a customer.
  Future<void> activateCustomer(String id) async {
    final customer = _box.get(id);
    if (customer != null) {
      customer.isActive = true;
      customer.updatedAt = DateTime.now();
      await customer.save();
    }
  }

  /// Check whether the customer has any recorded meal entries, extra items,
  /// payments, or monthly bills. Used to enforce that customers with historical
  /// data are never permanently deleted (requirement 5).
  bool hasHistory(String customerId) {
    if (Hive.isBoxOpen(AppConstants.mealEntryBox)) {
      final mealBox = Hive.box<MealEntry>(AppConstants.mealEntryBox);
      if (mealBox.values.any((e) => e.customerId == customerId)) return true;
    }
    if (Hive.isBoxOpen(AppConstants.additionalItemEntryBox)) {
      final extraBox =
          Hive.box<AdditionalItemEntry>(AppConstants.additionalItemEntryBox);
      if (extraBox.values.any((e) => e.customerId == customerId)) return true;
    }
    if (Hive.isBoxOpen(AppConstants.paymentBox)) {
      final paymentBox = Hive.box<Payment>(AppConstants.paymentBox);
      if (paymentBox.values.any((p) => p.customerId == customerId)) return true;
    }
    if (Hive.isBoxOpen(AppConstants.monthlyBillBox)) {
      final billBox = Hive.box<MonthlyBill>(AppConstants.monthlyBillBox);
      if (billBox.values.any((b) => b.customerId == customerId)) return true;
    }
    return false;
  }

  /// Permanently delete a customer ONLY if they have no historical transactions.
  /// Throws [StateError] if historical records exist.
  Future<void> deleteCustomer(String id) async {
    if (hasHistory(id)) {
      throw StateError(
        'Cannot delete customer with existing historical records. Deactivate instead.',
      );
    }
    await _box.delete(id);
  }

  /// Watch for changes to the customer box.
  Stream<BoxEvent> watchAll() => _box.watch();
}
