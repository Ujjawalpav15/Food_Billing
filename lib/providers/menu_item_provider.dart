import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/menu_item_repository.dart';

class MenuItemProvider extends ChangeNotifier {
  final MenuItemRepository _repository;
  static const _uuid = Uuid();

  List<MenuItem> _items = [];
  MenuCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  MenuItemProvider(this._repository) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.seedDefaultsIfEmpty();
      _items = _repository.getAllMenuItems();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load menu items: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  MenuCategory? get selectedCategory => _selectedCategory;

  List<MenuItem> get allItems => List.unmodifiable(_items);

  /// Total count of active menu items (unfiltered by search or category).
  int get totalActiveCount => _items.where((i) => i.isActive).length;

  /// Total count of inactive menu items (unfiltered by search or category).
  int get totalInactiveCount => _items.where((i) => !i.isActive).length;

  /// Active menu items, filtered by category and search query.
  List<MenuItem> get activeItems {
    final query = _searchQuery.trim().toLowerCase();
    final list = _items.where((item) {
      if (!item.isActive) return false;
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesUnit = item.unit.toLowerCase().contains(query);
        return matchesName || matchesUnit;
      }
      return true;
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Inactive menu items, filtered by category and search query.
  List<MenuItem> get inactiveItems {
    final query = _searchQuery.trim().toLowerCase();
    final list = _items.where((item) {
      if (item.isActive) return false;
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesUnit = item.unit.toLowerCase().contains(query);
        return matchesName || matchesUnit;
      }
      return true;
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  int getCategoryCount(MenuCategory? category, {bool activeOnly = true}) {
    return _items.where((i) {
      if (activeOnly && !i.isActive) return false;
      if (!activeOnly && i.isActive) return false;
      if (category == null) return true;
      return i.category == category;
    }).length;
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setSelectedCategory(MenuCategory? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

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

  // ── Operations ────────────────────────────────────────────────────────────

  void loadMenuItems() {
    try {
      _items = _repository.getAllMenuItems();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load menu: $e';
    }
    notifyListeners();
  }

  MenuItem? getMenuItem(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return _repository.getMenuItem(id);
    }
  }

  /// Add a new menu item.
  Future<bool> addMenuItem({
    required String name,
    required MenuCategory category,
    required String unit,
    required int pricePaisa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final item = MenuItem(
        id: _uuid.v4(),
        name: name.trim(),
        category: category,
        unit: unit.trim().toLowerCase(),
        pricePaisa: pricePaisa,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addMenuItem(item);
      _items = _repository.getAllMenuItems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add menu item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing menu item.
  Future<bool> updateMenuItem({
    required String id,
    required String name,
    required MenuCategory category,
    required String unit,
    required int pricePaisa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existing = _repository.getMenuItem(id);
      if (existing == null) {
        _errorMessage = 'Menu item not found';
        return false;
      }

      existing.name = name.trim();
      existing.category = category;
      existing.unit = unit.trim().toLowerCase();
      existing.pricePaisa = pricePaisa;

      await _repository.updateMenuItem(existing);
      _items = _repository.getAllMenuItems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update menu item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deactivate a menu item.
  Future<bool> deactivateMenuItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deactivateMenuItem(id);
      _items = _repository.getAllMenuItems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to deactivate menu item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reactivate a menu item.
  Future<bool> activateMenuItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.activateMenuItem(id);
      _items = _repository.getAllMenuItems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to activate menu item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check whether this item has been ordered before.
  bool hasHistory(String id) => _repository.hasHistory(id);

  /// Permanently delete an item if it has never been ordered.
  Future<bool> deleteMenuItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteMenuItem(id);
      _items = _repository.getAllMenuItems();
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
