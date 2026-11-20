import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/additional_item_entry_repository.dart';
import 'package:food_billing/data/repositories/meal_entry_repository.dart';
import 'package:food_billing/data/repositories/shop_profile_repository.dart';
import 'package:food_billing/providers/daily_entry_provider.dart';

class _FakeMealRepo implements MealEntryRepository {
  final Map<String, MealEntry> _storage = {};

  @override
  Future<void> addMealEntry(MealEntry entry) async {
    _storage[entry.id] = entry;
  }

  @override
  Future<void> updateMealEntry(MealEntry entry) async {
    _storage[entry.id] = entry;
  }

  @override
  Future<void> deleteMealEntry(String id) async {
    _storage.remove(id);
  }

  @override
  MealEntry? getMealEntry(String id) => _storage[id];

  @override
  MealEntry? findMealEntryForDate(String customerId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _storage.values.cast<MealEntry?>().firstWhere(
          (e) =>
              e!.customerId == customerId &&
              DateTime(e.date.year, e.date.month, e.date.day) == dateOnly,
          orElse: () => null,
        );
  }

  @override
  List<MealEntry> getMealEntriesForCustomer(String customerId) =>
      _storage.values.where((e) => e.customerId == customerId).toList();

  @override
  List<MealEntry> getMealEntriesForMonth(
          String customerId, int year, int month) =>
      _storage.values
          .where((e) =>
              e.customerId == customerId &&
              e.date.year == year &&
              e.date.month == month)
          .toList();

  @override
  List<MealEntry> getMealEntriesForDay(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _storage.values
        .where((e) =>
            DateTime(e.date.year, e.date.month, e.date.day) == dateOnly)
        .toList();
  }

  @override
  Stream<dynamic> watchAll() => const Stream.empty();
}

class _FakeExtraRepo implements AdditionalItemEntryRepository {
  final Map<String, AdditionalItemEntry> _storage = {};

  @override
  Future<void> addEntry(AdditionalItemEntry entry) async {
    _storage[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(AdditionalItemEntry entry) async {
    _storage[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _storage.remove(id);
  }

  @override
  AdditionalItemEntry? getEntry(String id) => _storage[id];

  @override
  List<AdditionalItemEntry> getEntriesForCustomer(String customerId) =>
      _storage.values.where((e) => e.customerId == customerId).toList();

  @override
  List<AdditionalItemEntry> getEntriesForMonth(
          String customerId, int year, int month) =>
      _storage.values
          .where((e) =>
              e.customerId == customerId &&
              e.date.year == year &&
              e.date.month == month)
          .toList();

  @override
  List<AdditionalItemEntry> getEntriesForDay(
      String customerId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _storage.values
        .where((e) =>
            e.customerId == customerId &&
            DateTime(e.date.year, e.date.month, e.date.day) == dateOnly)
        .toList();
  }

  @override
  List<AdditionalItemEntry> getAllEntriesForDay(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _storage.values
        .where((e) =>
            DateTime(e.date.year, e.date.month, e.date.day) == dateOnly)
        .toList();
  }

  @override
  Stream<dynamic> watchAll() => const Stream.empty();
}

class _FakeShopRepo implements ShopProfileRepository {
  ShopProfile? _profile;

  _FakeShopRepo([this._profile]);

  @override
  ShopProfile? getProfile() => _profile;

  @override
  bool get isSetUp => _profile != null;

  @override
  Future<void> saveProfile(ShopProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> updateProfile(ShopProfile profile) async {
    _profile = profile;
  }
}

void main() {
  group('DailyEntryProvider Tests', () {
    late _FakeMealRepo mealRepo;
    late _FakeExtraRepo extraRepo;
    late _FakeShopRepo shopRepo;
    late DailyEntryProvider provider;

    setUp(() {
      mealRepo = _FakeMealRepo();
      extraRepo = _FakeExtraRepo();
      final now = DateTime.now();
      shopRepo = _FakeShopRepo(
        ShopProfile(
          id: 'shop1',
          shopName: 'Annapurna Mess',
          ownerName: 'Ram',
          phoneNumber: '9800000000',
          address: 'Kathmandu',
          defaultBreakfastPricePaisa: 8500, // Rs. 85
          defaultDinnerPricePaisa: 9000,    // Rs. 90
          createdAt: now,
          updatedAt: now,
        ),
      );
      provider = DailyEntryProvider(
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        shopRepo: shopRepo,
      );
    });

    test('Initial counts are zero', () {
      expect(provider.totalBreakfastCount, 0);
      expect(provider.totalDinnerCount, 0);
      expect(provider.totalExtraItemsCount, 0);
    });

    test('Toggle breakfast creates entry and snapshots current profile price',
        () async {
      await provider.toggleBreakfast('cust1');

      expect(provider.totalBreakfastCount, 1);
      final entry = provider.getMealEntryForCustomer('cust1');
      expect(entry, isNotNull);
      expect(entry!.hadBreakfast, isTrue);
      expect(entry.hadDinner, isFalse);
      expect(entry.breakfastPricePaisa, 8500); // Snapshotted Rs. 85

      // Toggle off
      await provider.toggleBreakfast('cust1');
      expect(provider.totalBreakfastCount, 0);
      expect(provider.getMealEntryForCustomer('cust1')!.hadBreakfast, isFalse);
    });

    test('Toggle dinner sets hadDinner to true with snapshotted dinner price',
        () async {
      await provider.toggleDinner('cust1');

      expect(provider.totalDinnerCount, 1);
      final entry = provider.getMealEntryForCustomer('cust1');
      expect(entry, isNotNull);
      expect(entry!.hadBreakfast, isFalse);
      expect(entry.hadDinner, isTrue);
      expect(entry.dinnerPricePaisa, 9000); // Snapshotted Rs. 90
    });

    test('Add extra item snapshots item price and increments correctly',
        () async {
      final now = DateTime.now();
      final egg = MenuItem(
        id: 'item_egg',
        name: 'Boiled Egg',
        category: MenuCategory.extra,
        unit: 'piece',
        pricePaisa: 3000,
        createdAt: now,
        updatedAt: now,
      );

      await provider.addExtraItem(
        customerId: 'cust1',
        item: egg,
        quantity: 1,
      );

      expect(provider.totalExtraItemsCount, 1);
      var extras = provider.getExtrasForCustomer('cust1');
      expect(extras.length, 1);
      expect(extras.first.menuItemName, 'Boiled Egg');
      expect(extras.first.unitPricePaisa, 3000);
      expect(extras.first.quantity, 1);
      expect(extras.first.totalPaisa, 3000);

      // Add another egg
      await provider.addExtraItem(
        customerId: 'cust1',
        item: egg,
        quantity: 2,
      );

      expect(provider.totalExtraItemsCount, 3);
      extras = provider.getExtrasForCustomer('cust1');
      expect(extras.first.quantity, 3);
      expect(extras.first.totalPaisa, 9000);
    });

    test('Bulk set breakfast sets breakfast for all customers', () async {
      final now = DateTime.now();
      final customers = [
        Customer(
          id: 'c1',
          name: 'Hari',
          createdAt: now,
          updatedAt: now,
        ),
        Customer(
          id: 'c2',
          name: 'Sita',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await provider.bulkSetBreakfast(customers, true);
      expect(provider.totalBreakfastCount, 2);

      await provider.bulkSetBreakfast(customers, false);
      expect(provider.totalBreakfastCount, 0);
    });

    test('Date navigation isolates entries by date', () async {
      await provider.toggleBreakfast('cust1');
      expect(provider.totalBreakfastCount, 1);

      // Navigate to previous day
      provider.goToPreviousDay();
      expect(provider.totalBreakfastCount, 0);

      // Navigate back to today
      provider.goToNextDay();
      expect(provider.totalBreakfastCount, 1);
    });
  });
}
