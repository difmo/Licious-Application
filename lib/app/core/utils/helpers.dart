class Helpers {
  Helpers._();

  /// Format a double as currency string, e.g. ₹8.00
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Parse a price string like "₹8.00" into a double.
  static double parsePrice(String price) {
    return double.tryParse(price.replaceAll('₹', '')) ?? 0.0;
  }
}
