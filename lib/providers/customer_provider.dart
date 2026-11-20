import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository;
  static const _uuid = Uuid();

  List<Customer> _customers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  CustomerProvider(this._repository) {
    loadCustomers();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<Customer> get allCustomers => List.unmodifiable(_customers);

  /// Total count of active customers (ignoring current search filter).
  int get totalActiveCount =>
      _customers.where((c) => c.isActive).length;

  /// Total count of inactive customers (ignoring current search filter).
  int get totalInactiveCount =>
      _customers.where((c) => !c.isActive).length;

  /// Active customers, filtered by the current search query and sorted by name.
  List<Customer> get activeCustomers {
    final query = _searchQuery.trim().toLowerCase();
    final list = _customers.where((c) {
      if (!c.isActive) return false;
      if (query.isEmpty) return true;
      final nameMatches = c.name.toLowerCase().contains(query);
      final phoneMatches =
          c.phoneNumber != null && c.phoneNumber!.toLowerCase().contains(query);
      return nameMatches || phoneMatches;
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Inactive customers, filtered by the current search query and sorted by name.
  List<Customer> get inactiveCustomers {
    final query = _searchQuery.trim().toLowerCase();
    final list = _customers.where((c) {
      if (c.isActive) return false;
      if (query.isEmpty) return true;
      final nameMatches = c.name.toLowerCase().contains(query);
      final phoneMatches =
          c.phoneNumber != null && c.phoneNumber!.toLowerCase().contains(query);
      return nameMatches || phoneMatches;
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  // ── Search Handling ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  // ── Repository Operations ─────────────────────────────────────────────────

  void loadCustomers() {
    try {
      _customers = _repository.getAllCustomers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load customers: $e';
    }
    notifyListeners();
  }

  Customer? getCustomer(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return _repository.getCustomer(id);
    }
  }

  /// Add a new customer.
  Future<bool> addCustomer({
    required String name,
    String? phoneNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final customer = Customer(
        id: _uuid.v4(),
        name: name.trim(),
        phoneNumber:
            phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );

      await _repository.addCustomer(customer);
      _customers = _repository.getAllCustomers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing customer's details.
  Future<bool> updateCustomer({
    required String id,
    required String name,
    String? phoneNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existing = _repository.getCustomer(id);
      if (existing == null) {
        _errorMessage = 'Customer not found';
        return false;
      }

      existing.name = name.trim();
      existing.phoneNumber =
          phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim();
      existing.notes = notes?.trim().isEmpty == true ? null : notes?.trim();

      await _repository.updateCustomer(existing);
      _customers = _repository.getAllCustomers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deactivate a customer (preserves all historical billing/payment data).
  Future<bool> deactivateCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deactivateCustomer(id);
      _customers = _repository.getAllCustomers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to deactivate customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reactivate a previously deactivated customer.
  Future<bool> activateCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.activateCustomer(id);
      _customers = _repository.getAllCustomers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to activate customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check whether the customer has any transaction history.
  bool hasHistory(String id) {
    return _repository.hasHistory(id);
  }

  /// Permanently delete a customer ONLY if they have NO history.
  /// Returns false if deletion failed or was blocked by history preservation.
  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCustomer(id);
      _customers = _repository.getAllCustomers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
