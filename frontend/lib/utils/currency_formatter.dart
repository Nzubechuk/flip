import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const String symbol = '₦';
  
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String get naira => symbol;
}
