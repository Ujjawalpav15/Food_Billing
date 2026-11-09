import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_billing/core/theme/app_theme.dart';
import 'package:food_billing/providers/shop_profile_provider.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/screens/onboarding/onboarding_screen.dart';
import 'package:food_billing/widgets/main_shell.dart';

// ---------------------------------------------------------------------------
// Fake provider — avoids any Hive interaction.
// ---------------------------------------------------------------------------

class _FakeShopProfileProvider extends ChangeNotifier
    implements ShopProfileProvider {
  final bool _isSetUp;
  final ShopProfile? _profile;

  _FakeShopProfileProvider({bool isSetUp = false, ShopProfile? profile})
      : _isSetUp = isSetUp,
        _profile = profile;

  @override
  bool get isSetUp => _isSetUp;

  @override
  ShopProfile? get shopProfile => _profile;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> createProfile({
    required String shopName,
    required String ownerName,
    required String phoneNumber,
    required String address,
    int breakfastPricePaisa = 8500,
    int dinnerPricePaisa = 8500,
  }) async => true;

  @override
  Future<bool> updateProfile({
    required String shopName,
    required String ownerName,
    required String phoneNumber,
    required String address,
    int? breakfastPricePaisa,
    int? dinnerPricePaisa,
    String? logoPath,
  }) async => true;

  @override
  Future<void> reload() async {}

  @override
  void clearError() {}
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, {bool isSetUp = false}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: ChangeNotifierProvider<ShopProfileProvider>(
      create: (_) => _FakeShopProfileProvider(isSetUp: isSetUp),
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
    'OnboardingScreen renders app title on first run',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen()));
      await tester.pump();

      expect(find.text('Mess Billing Manager'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    },
  );

  testWidgets(
    'MainShell renders bottom nav with 5 destinations',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MainShell(), isSetUp: true));
      await tester.pump();

      // Each destination label appears at least once in the nav bar
      expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
      expect(find.text('Daily Entry'), findsAtLeastNWidgets(1));
      expect(find.text('Customers'), findsAtLeastNWidgets(1));
      expect(find.text('Bills'), findsAtLeastNWidgets(1));
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'MainShell tab switching — tapping Customers shows customer screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MainShell(), isSetUp: true));
      await tester.pump();

      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Management'), findsOneWidget);
    },
  );
}
