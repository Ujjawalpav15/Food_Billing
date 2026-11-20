import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/menu_item_repository.dart';
import 'package:food_billing/providers/menu_item_provider.dart';

class _FakeMenuItemRepository implements MenuItemRepository {
  final Map<String, MenuItem> _storage = {};
  final Set<String> _historyItemIds = {};

  void simulateHistory(String itemId) {
    _historyItemIds.add(itemId);
  }

  @override
  Future<void> addMenuItem(MenuItem item) async {
    _storage[item.id] = item;
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    item.updatedAt = DateTime.now();
    _storage[item.id] = item;
  }

  @override
  MenuItem? getMenuItem(String id) => _storage[id];

  @override
  List<MenuItem> getAllMenuItems() => _storage.values.toList();

  @override
  List<MenuItem> getActiveMenuItems() =>
      _storage.values.where((m) => m.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  List<MenuItem> getMenuItemsByCategory(MenuCategory category) =>
      _storage.values.where((m) => m.category == category && m.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> deactivateMenuItem(String id) async {
    final item = _storage[id];
    if (item != null) {
      item.isActive = false;
      item.updatedAt = DateTime.now();
    }
  }

  @override
  Future<void> activateMenuItem(String id) async {
    final item = _storage[id];
    if (item != null) {
      item.isActive = true;
      item.updatedAt = DateTime.now();
    }
  }

  @override
  bool hasHistory(String menuItemId) =>
      _historyItemIds.contains(menuItemId);

  @override
  Future<void> deleteMenuItem(String id) async {
    if (hasHistory(id)) {
      throw StateError(
          'Cannot delete menu item with existing order records.');
    }
    _storage.remove(id);
  }

  @override
  Future<void> seedDefaultsIfEmpty() async {
    if (_storage.isNotEmpty) return;
    final now = DateTime.now();
    final defaults = [
      MenuItem(
        id: 'default_tea',
        name: 'Tea / Chiya',
        category: MenuCategory.beverage,
        unit: 'cup',
        pricePaisa: 2000,
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_boiled_egg',
        name: 'Boiled Egg',
        category: MenuCategory.extra,
        unit: 'piece',
        pricePaisa: 3000,
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_curd',
        name: 'Curd / Dahi',
        category: MenuCategory.dairy,
        unit: 'cup',
        pricePaisa: 3500,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final item in defaults) {
      _storage[item.id] = item;
    }
  }

  @override
  Stream<dynamic> watchAll() => const Stream.empty();
}

void main() {
  group('MenuItemProvider Tests', () {
    late _FakeMenuItemRepository repository;
    late MenuItemProvider provider;

    setUp(() async {
      repository = _FakeMenuItemRepository();
      provider = MenuItemProvider(repository);
      // Wait for initial async seed to finish
      await Future<void>.delayed(Duration.zero);
    });

    test('Initial state seeds popular default mess items', () {
      expect(provider.allItems.length, 3);
      expect(provider.totalActiveCount, 3);
      expect(provider.totalInactiveCount, 0);

      final names = provider.activeItems.map((i) => i.name).toList();
      expect(names, containsAll(['Tea / Chiya', 'Boiled Egg', 'Curd / Dahi']));
    });

    test('Add menu item adds new active item with correct paisa', () async {
      final success = await provider.addMenuItem(
        name: 'Black Coffee',
        category: MenuCategory.beverage,
        unit: 'cup',
        pricePaisa: 3000, // Rs. 30
      );

      expect(success, isTrue);
      expect(provider.totalActiveCount, 4);

      final coffee =
          provider.activeItems.firstWhere((i) => i.name == 'Black Coffee');
      expect(coffee.category, MenuCategory.beverage);
      expect(coffee.unit, 'cup');
      expect(coffee.pricePaisa, 3000);
      expect(coffee.isActive, isTrue);
    });

    test('Category filter isolates items by category', () {
      provider.setSelectedCategory(MenuCategory.beverage);
      expect(provider.activeItems.length, 1);
      expect(provider.activeItems.first.name, 'Tea / Chiya');

      provider.setSelectedCategory(MenuCategory.dairy);
      expect(provider.activeItems.length, 1);
      expect(provider.activeItems.first.name, 'Curd / Dahi');

      provider.setSelectedCategory(null);
      expect(provider.activeItems.length, 3);
    });

    test('Search query filters by item name or unit', () {
      provider.setSearchQuery('egg');
      expect(provider.activeItems.length, 1);
      expect(provider.activeItems.first.name, 'Boiled Egg');

      provider.setSearchQuery('cup');
      // Both Tea and Curd are unit 'cup'
      expect(provider.activeItems.length, 2);

      provider.clearSearch();
      expect(provider.activeItems.length, 3);
    });

    test('Deactivate and reactivate item', () async {
      final egg =
          provider.activeItems.firstWhere((i) => i.name == 'Boiled Egg');

      final deactSuccess = await provider.deactivateMenuItem(egg.id);
      expect(deactSuccess, isTrue);
      expect(provider.totalActiveCount, 2);
      expect(provider.totalInactiveCount, 1);
      expect(provider.inactiveItems.first.name, 'Boiled Egg');

      final actSuccess = await provider.activateMenuItem(egg.id);
      expect(actSuccess, isTrue);
      expect(provider.totalActiveCount, 3);
      expect(provider.totalInactiveCount, 0);
    });

    test('Update menu item preserves ID and updates values', () async {
      final tea =
          provider.activeItems.firstWhere((i) => i.name == 'Tea / Chiya');

      final updated = await provider.updateMenuItem(
        id: tea.id,
        name: 'Special Masala Tea',
        category: MenuCategory.beverage,
        unit: 'cup',
        pricePaisa: 2500, // Updated to Rs. 25
      );

      expect(updated, isTrue);
      final item = provider.getMenuItem(tea.id);
      expect(item?.name, 'Special Masala Tea');
      expect(item?.pricePaisa, 2500);
    });

    test('Delete menu item blocked when order history exists', () async {
      final egg =
          provider.activeItems.firstWhere((i) => i.name == 'Boiled Egg');
      repository.simulateHistory(egg.id);

      expect(provider.hasHistory(egg.id), isTrue);

      final deleted = await provider.deleteMenuItem(egg.id);
      expect(deleted, isFalse);
      expect(provider.allItems.length, 3);
    });

    test('Delete menu item succeeds when no order history exists', () async {
      final egg =
          provider.activeItems.firstWhere((i) => i.name == 'Boiled Egg');

      expect(provider.hasHistory(egg.id), isFalse);

      final deleted = await provider.deleteMenuItem(egg.id);
      expect(deleted, isTrue);
      expect(provider.allItems.length, 2);
    });
  });
}
