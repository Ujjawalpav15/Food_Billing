// Core constants for the Mess Billing Manager application.
// All monetary values use integer Paisa (1 NPR = 100 Paisa) to avoid floating-point errors.

class AppConstants {
  AppConstants._();

  // Default prices in Paisa
  static const int defaultBreakfastPricePaisa = 8500; // Rs. 85
  static const int defaultDinnerPricePaisa = 8500; // Rs. 85

  // Currency
  static const String currencySymbol = 'Rs.';
  static const String currencyCode = 'NPR';

  // Hive box names
  static const String shopProfileBox = 'shop_profile';
  static const String customerBox = 'customers';
  static const String menuItemBox = 'menu_items';
  static const String mealEntryBox = 'meal_entries';
  static const String additionalItemEntryBox = 'additional_item_entries';
  static const String paymentBox = 'payments';
  static const String adjustmentBox = 'adjustments';
  static const String monthlyBillBox = 'monthly_bills';
  static const String auditEntryBox = 'audit_entries';

  // Hive type IDs
  static const int shopProfileTypeId = 0;
  static const int customerTypeId = 1;
  static const int menuItemTypeId = 2;
  static const int mealEntryTypeId = 3;
  static const int additionalItemEntryTypeId = 4;
  static const int paymentTypeId = 5;
  static const int adjustmentTypeId = 6;
  static const int monthlyBillTypeId = 7;
  static const int auditEntryTypeId = 8;
  static const int mealTypeTypeId = 9;
  static const int menuCategoryTypeId = 10;
  static const int paymentMethodTypeId = 11;
  static const int billStatusTypeId = 12;
  static const int auditActionTypeId = 13;
}
