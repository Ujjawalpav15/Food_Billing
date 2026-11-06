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

  Stream<BoxEvent> watchAll() => _box.watch();
}
