// Utility functions for money formatting and conversion.
// All internal values are in Paisa (integer). Display as NPR.

class MoneyUtils {
  MoneyUtils._();

  /// Convert paisa to NPR display string. e.g. 8500 -> "Rs. 85"
  static String formatNPR(int paisa) {
    final isNegative = paisa < 0;
    final absPaisa = paisa.abs();
    final rupees = absPaisa ~/ 100;
    final remainingPaisa = absPaisa % 100;
    final sign = isNegative ? '-' : '';
    if (remainingPaisa == 0) {
      return '${sign}Rs. $rupees';
    }
    return '${sign}Rs. $rupees.${remainingPaisa.toString().padLeft(2, '0')}';
  }

  /// Convert rupees (double input from user) to paisa integer.
  static int rupeesToPaisa(double rupees) => (rupees * 100).round();

  /// Convert paisa to rupees double for display/input.
  static double paisaToRupees(int paisa) => paisa / 100.0;

  /// Parse a user-entered rupees string to paisa. Returns null if invalid.
  static int? parseRupeesString(String input) {
    final trimmed = input.trim().replaceAll(',', '');
    final value = double.tryParse(trimmed);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }
}
