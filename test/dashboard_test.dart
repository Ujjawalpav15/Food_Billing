import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/core/theme/app_theme.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/additional_item_entry_repository.dart';
import 'package:food_billing/data/repositories/adjustment_repository.dart';
import 'package:food_billing/data/repositories/customer_repository.dart';
import 'package:food_billing/data/repositories/meal_entry_repository.dart';
import 'package:food_billing/data/repositories/monthly_bill_repository.dart';
import 'package:food_billing/data/repositories/payment_repository.dart';
import 'package:food_billing/data/repositories/shop_profile_repository.dart';
import 'package:food_billing/providers/customer_provider.dart';
import 'package:food_billing/providers/daily_entry_provider.dart';
import 'package:food_billing/providers/monthly_bill_provider.dart';
import 'package:food_billing/providers/payment_provider.dart';
import 'package:food_billing/providers/shop_profile_provider.dart';
import 'package:food_billing/screens/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';

class _FakeShopRepo implements ShopProfileRepository {
  ShopProfile? profile;
  _FakeShopRepo([this.profile]);
  @override
  ShopProfile? getProfile() => profile;
  @override
  bool get isSetUp => profile != null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerRepo implements CustomerRepository {
  final List<Customer> customers = [];
  @override
  List<Customer> getAllCustomers() => List.from(customers);
  @override
  List<Customer> getActiveCustomers() => customers.where((c) => c.isActive).toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMealRepo implements MealEntryRepository {
  final List<MealEntry> meals = [];
  @override
  List<MealEntry> getMealEntriesForDay(DateTime date) => meals;
  @override
  List<MealEntry> getMealEntriesForCustomer(String id) => meals.where((m) => m.customerId == id).toList();
  @override
  List<MealEntry> getMealEntriesForMonth(String id, int y, int m) => meals;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExtraRepo implements AdditionalItemEntryRepository {
  @override
  List<AdditionalItemEntry> getAllEntriesForDay(DateTime date) => [];
  @override
  List<AdditionalItemEntry> getEntriesForCustomer(String id) => [];
  @override
  List<AdditionalItemEntry> getEntriesForMonth(String id, int y, int m) => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdjustmentRepo implements AdjustmentRepository {
  @override
  List<Adjustment> getAdjustmentsForCustomer(String id) => [];
  @override
  List<Adjustment> getAdjustmentsForMonth(String id, int y, int m) => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepo implements PaymentRepository {
  @override
  List<Payment> getAllPayments() => [];
  @override
  List<Payment> getPaymentsForCustomer(String id) => [];
  @override
  List<Payment> getPaymentsForMonth(String id, int y, int m) => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBillRepo implements MonthlyBillRepository {
  @override
  MonthlyBill? getBillForMonth(String id, int y, int m) => null;
  @override
  List<MonthlyBill> getAllBillsForMonth(int y, int m) => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Dashboard renders shop name, attendance card, and quick actions', (tester) async {
    final now = DateTime.now();
    final shopRepo = _FakeShopRepo(
      ShopProfile(
        id: 's1',
        shopName: 'Annapurna Student Mess',
        ownerName: 'Ram',
        phoneNumber: '9841000000',
        address: 'Kathmandu',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final customerRepo = _FakeCustomerRepo();
    customerRepo.customers.add(
      Customer(
        id: 'c1',
        name: 'Suman Thapa',
        phoneNumber: '9841111111',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final mealRepo = _FakeMealRepo();
    final extraRepo = _FakeExtraRepo();
    final adjustmentRepo = _FakeAdjustmentRepo();
    final paymentRepo = _FakePaymentRepo();
    final billRepo = _FakeBillRepo();

    int navigatedTab = -1;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ShopProfileProvider(shopRepo)),
          ChangeNotifierProvider(create: (_) => CustomerProvider(customerRepo)),
          ChangeNotifierProvider(
            create: (_) => DailyEntryProvider(
              mealRepo: mealRepo,
              extraRepo: extraRepo,
              shopRepo: shopRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => MonthlyBillProvider(
              billRepo: billRepo,
              mealRepo: mealRepo,
              extraRepo: extraRepo,
              adjustmentRepo: adjustmentRepo,
              paymentRepo: paymentRepo,
              customerRepo: customerRepo,
              shopRepo: shopRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PaymentProvider(
              paymentRepo: paymentRepo,
              customerRepo: customerRepo,
              mealRepo: mealRepo,
              extraRepo: extraRepo,
              adjustmentRepo: adjustmentRepo,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: DashboardScreen(
            onNavigateToTab: (tab) => navigatedTab = tab,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify shop name and metrics render
    expect(find.text('Annapurna Student Mess'), findsOneWidget);
    expect(find.text('1 Active Students'), findsOneWidget);
    expect(find.text('Today’s Meal Attendance'), findsOneWidget);

    // Verify quick action buttons exist
    expect(find.text('Daily Meals'), findsOneWidget);
    expect(find.text('New Customer'), findsOneWidget);
    expect(find.text('Record Pay'), findsOneWidget);
    expect(find.text('Menu & Rates'), findsOneWidget);

    // Tap Daily Meals quick action and verify navigation callback
    await tester.tap(find.text('Daily Meals'));
    expect(navigatedTab, 1);
  });

  testWidgets('Dashboard renders on small screen (320px width) without any overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final shopRepo = _FakeShopRepo(
      ShopProfile(
        id: 's1',
        shopName: 'Annapurna Student Mess',
        ownerName: 'Ram',
        phoneNumber: '9841000000',
        address: 'Kathmandu',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final customerRepo = _FakeCustomerRepo();
    customerRepo.customers.add(
      Customer(
        id: 'c1',
        name: 'Suman Thapa',
        phoneNumber: '9841111111',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ShopProfileProvider(shopRepo)),
          ChangeNotifierProvider(create: (_) => CustomerProvider(customerRepo)),
          ChangeNotifierProvider(
            create: (_) => DailyEntryProvider(
              mealRepo: _FakeMealRepo(),
              extraRepo: _FakeExtraRepo(),
              shopRepo: shopRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => MonthlyBillProvider(
              billRepo: _FakeBillRepo(),
              mealRepo: _FakeMealRepo(),
              extraRepo: _FakeExtraRepo(),
              adjustmentRepo: _FakeAdjustmentRepo(),
              paymentRepo: _FakePaymentRepo(),
              customerRepo: customerRepo,
              shopRepo: shopRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PaymentProvider(
              paymentRepo: _FakePaymentRepo(),
              customerRepo: customerRepo,
              mealRepo: _FakeMealRepo(),
              extraRepo: _FakeExtraRepo(),
              adjustmentRepo: _FakeAdjustmentRepo(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify no overflow error occurred
    expect(tester.takeException(), isNull);
    expect(find.text('Today’s Meal Attendance'), findsOneWidget);
    expect(find.text('Daily Entry'), findsOneWidget);
  });
}
