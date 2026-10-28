import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return '0 ₫';
    return _formatter.format(amount);
  }
}
