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

  /// Watch for changes to the customer box.
  Stream<BoxEvent> watchAll() => _box.watch();
}
