import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/customer_repository.dart';
import 'package:food_billing/providers/customer_provider.dart';

class _FakeCustomerRepository implements CustomerRepository {
  final Map<String, Customer> _storage = {};
  final Set<String> _historyCustomerIds = {};

  void simulateHistory(String customerId) {
    _historyCustomerIds.add(customerId);
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    _storage[customer.id] = customer;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    customer.updatedAt = DateTime.now();
    _storage[customer.id] = customer;
  }

  @override
  Customer? getCustomer(String id) => _storage[id];

  @override
  List<Customer> getAllCustomers() => _storage.values.toList();

  @override
  List<Customer> getActiveCustomers() =>
      _storage.values.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  List<Customer> searchCustomers(String query) {
    final lower = query.toLowerCase();
    return _storage.values
        .where((c) => c.name.toLowerCase().contains(lower))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> deactivateCustomer(String id) async {
    final c = _storage[id];
    if (c != null) {
      c.isActive = false;
      c.updatedAt = DateTime.now();
    }
  }

  @override
  Future<void> activateCustomer(String id) async {
    final c = _storage[id];
    if (c != null) {
      c.isActive = true;
      c.updatedAt = DateTime.now();
    }
  }

  @override
  bool hasHistory(String customerId) =>
      _historyCustomerIds.contains(customerId);

  @override
  Future<void> deleteCustomer(String id) async {
    if (hasHistory(id)) {
      throw StateError(
          'Cannot delete customer with existing historical records.');
    }
    _storage.remove(id);
  }

  @override
  Stream<dynamic> watchAll() => const Stream.empty();
}

void main() {
  group('CustomerProvider Tests', () {
    late _FakeCustomerRepository repository;
    late CustomerProvider provider;

    setUp(() {
      repository = _FakeCustomerRepository();
      provider = CustomerProvider(repository);
    });

    test('Initial state is empty', () {
      expect(provider.allCustomers, isEmpty);
      expect(provider.activeCustomers, isEmpty);
      expect(provider.inactiveCustomers, isEmpty);
      expect(provider.totalActiveCount, 0);
      expect(provider.totalInactiveCount, 0);
    });

    test('Add customer adds active customer', () async {
      final success = await provider.addCustomer(
        name: 'Ram Sharma',
        phoneNumber: '9841000000',
        notes: 'Room 101',
      );

      expect(success, isTrue);
      expect(provider.totalActiveCount, 1);
      expect(provider.activeCustomers.length, 1);
      expect(provider.activeCustomers.first.name, 'Ram Sharma');
      expect(provider.activeCustomers.first.phoneNumber, '9841000000');
      expect(provider.activeCustomers.first.notes, 'Room 101');
      expect(provider.activeCustomers.first.isActive, isTrue);
    });

    test('Search query filters active customers by name and phone', () async {
      await provider.addCustomer(name: 'Sita Thapa', phoneNumber: '9841111111');
      await provider.addCustomer(name: 'Hari KC', phoneNumber: '9842222222');

      expect(provider.activeCustomers.length, 2);

      // Search by name
      provider.setSearchQuery('Sita');
      expect(provider.activeCustomers.length, 1);
      expect(provider.activeCustomers.first.name, 'Sita Thapa');

      // Search by phone
      provider.setSearchQuery('2222');
      expect(provider.activeCustomers.length, 1);
      expect(provider.activeCustomers.first.name, 'Hari KC');

      // Clear search
      provider.clearSearch();
      expect(provider.activeCustomers.length, 2);
    });

    test('Deactivate and reactivate customer updates lists properly', () async {
      await provider.addCustomer(name: 'Ram Sharma');
      final customerId = provider.activeCustomers.first.id;

      // Deactivate
      final deactSuccess = await provider.deactivateCustomer(customerId);
      expect(deactSuccess, isTrue);
      expect(provider.totalActiveCount, 0);
      expect(provider.totalInactiveCount, 1);
      expect(provider.activeCustomers, isEmpty);
      expect(provider.inactiveCustomers.length, 1);
      expect(provider.inactiveCustomers.first.name, 'Ram Sharma');

      // Reactivate
      final actSuccess = await provider.activateCustomer(customerId);
      expect(actSuccess, isTrue);
      expect(provider.totalActiveCount, 1);
      expect(provider.totalInactiveCount, 0);
      expect(provider.activeCustomers.length, 1);
      expect(provider.inactiveCustomers, isEmpty);
    });

    test('Update customer updates fields', () async {
      await provider.addCustomer(name: 'Ram Sharma', phoneNumber: '9841000000');
      final customerId = provider.activeCustomers.first.id;

      final updated = await provider.updateCustomer(
        id: customerId,
        name: 'Ram Kumar Sharma',
        phoneNumber: '9841999999',
        notes: 'Updated notes',
      );

      expect(updated, isTrue);
      final c = provider.getCustomer(customerId);
      expect(c?.name, 'Ram Kumar Sharma');
      expect(c?.phoneNumber, '9841999999');
      expect(c?.notes, 'Updated notes');
    });

    test('Delete customer is prevented when historical records exist', () async {
      await provider.addCustomer(name: 'Gita Basnet');
      final customerId = provider.activeCustomers.first.id;

      // Simulate historical transaction records
      repository.simulateHistory(customerId);
      expect(provider.hasHistory(customerId), isTrue);

      final deleteSuccess = await provider.deleteCustomer(customerId);
      expect(deleteSuccess, isFalse);
      expect(provider.totalActiveCount, 1);
    });

    test('Delete customer succeeds when no history exists', () async {
      await provider.addCustomer(name: 'Temporary Customer');
      final customerId = provider.activeCustomers.first.id;

      expect(provider.hasHistory(customerId), isFalse);

      final deleteSuccess = await provider.deleteCustomer(customerId);
      expect(deleteSuccess, isTrue);
      expect(provider.totalActiveCount, 0);
      expect(provider.allCustomers, isEmpty);
    });
  });
}
