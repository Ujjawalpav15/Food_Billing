import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class MenuItemRepository {
  Box<MenuItem> get _box => Hive.box<MenuItem>(AppConstants.menuItemBox);

  Future<void> addMenuItem(MenuItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> updateMenuItem(MenuItem item) async {
    item.updatedAt = DateTime.now();
    await _box.put(item.id, item);
  }

  MenuItem? getMenuItem(String id) => _box.get(id);

  List<MenuItem> getAllMenuItems() => _box.values.toList();

  List<MenuItem> getActiveMenuItems() =>
      _box.values.where((m) => m.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<MenuItem> getMenuItemsByCategory(MenuCategory category) =>
      _box.values.where((m) => m.category == category && m.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Future<void> deactivateMenuItem(String id) async {
    final item = _box.get(id);
    if (item != null) {
      item.isActive = false;
      item.updatedAt = DateTime.now();
      await item.save();
    }
  }

  Future<void> activateMenuItem(String id) async {
    final item = _box.get(id);
    if (item != null) {
      item.isActive = true;
      item.updatedAt = DateTime.now();
      await item.save();
    }
  }

  /// Check whether this menu item has any recorded extra-item orders.
  bool hasHistory(String menuItemId) {
    if (Hive.isBoxOpen(AppConstants.additionalItemEntryBox)) {
      final extraBox =
          Hive.box<AdditionalItemEntry>(AppConstants.additionalItemEntryBox);
      return extraBox.values.any((e) => e.menuItemId == menuItemId);
    }
    return false;
  }

  /// Permanently delete a menu item ONLY if it has never been ordered.
  /// Throws [StateError] if historical order records exist.
  Future<void> deleteMenuItem(String id) async {
    if (hasHistory(id)) {
      throw StateError(
        'Cannot delete menu item with existing order records. Deactivate instead.',
      );
    }
    await _box.delete(id);
  }

  /// Seeds popular Nepali mess menu items if the box is currently empty.
  Future<void> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return;

    final now = DateTime.now();
    final defaultItems = [
      MenuItem(
        id: 'default_tea',
        name: 'Tea / Chiya',
        category: MenuCategory.beverage,
        unit: 'cup',
        pricePaisa: 2000, // Rs. 20
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_boiled_egg',
        name: 'Boiled Egg',
        category: MenuCategory.extra,
        unit: 'piece',
        pricePaisa: 3000, // Rs. 30
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_egg_omelette',
        name: 'Egg Omelette',
        category: MenuCategory.extra,
        unit: 'piece',
        pricePaisa: 4000, // Rs. 40
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_curd',
        name: 'Curd / Dahi',
        category: MenuCategory.dairy,
        unit: 'cup',
        pricePaisa: 3500, // Rs. 35
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_milk',
        name: 'Milk / Dudh',
        category: MenuCategory.dairy,
        unit: 'glass',
        pricePaisa: 4000, // Rs. 40
        createdAt: now,
        updatedAt: now,
      ),
      MenuItem(
        id: 'default_chicken_curry',
        name: 'Chicken Curry',
        category: MenuCategory.extra,
        unit: 'plate',
        pricePaisa: 15000, // Rs. 150
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final item in defaultItems) {
      await _box.put(item.id, item);
    }
  }

  Stream<BoxEvent> watchAll() => _box.watch();
}
