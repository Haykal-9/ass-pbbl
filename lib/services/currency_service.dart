import 'package:flutter/foundation.dart';

/// Global notifier — widgets rebuild when the active currency changes.
final ValueNotifier<String> currencyNotifier = ValueNotifier('IDR');

/// Currency helper.
///
/// All budget amounts are stored in the database in a single **base currency
/// (IDR)**. The user-selected currency only affects how those amounts are
/// displayed and how raw input is interpreted. This keeps the stored data
/// consistent while letting the Settings → Currency option re-price the whole
/// app instantly.
class CurrencyService {
  CurrencyService._();

  /// How many IDR make up one unit of each currency (approximate fixed rates).
  static const Map<String, double> _idrPerUnit = {
    'IDR': 1,
    'USD': 16000,
    'EUR': 17500,
  };

  static const Map<String, String> _symbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
  };

  /// Number of decimal places shown for each currency.
  static const Map<String, int> _decimals = {
    'IDR': 0,
    'USD': 2,
    'EUR': 2,
  };

  static String symbol([String? currency]) {
    final cur = currency ?? currencyNotifier.value;
    return _symbols[cur] ?? cur;
  }

  /// Convert an amount stored in base (IDR) into the given currency.
  static double fromBase(double idrAmount, [String? currency]) {
    final cur = currency ?? currencyNotifier.value;
    return idrAmount / (_idrPerUnit[cur] ?? 1);
  }

  /// Convert a value expressed in the given currency back to base (IDR).
  static double toBase(double value, [String? currency]) {
    final cur = currency ?? currencyNotifier.value;
    return value * (_idrPerUnit[cur] ?? 1);
  }

  /// Parse free-form user input (e.g. "1.250,5" or "1,250.5" or "1250") into a
  /// number expressed in the active currency. Strips the currency symbol and
  /// any grouping separators. Returns null if nothing numeric is found.
  static double? parseInput(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    // Remove currency symbols and spaces.
    s = s.replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (s.isEmpty) return null;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // The last separator is the decimal one; the other is grouping.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Treat a lone comma as a decimal separator.
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// Format an amount stored in base (IDR) for display in the active currency,
  /// e.g. "Rp 1.500.000" or "$ 93.75".
  static String format(double idrAmount, [String? currency]) {
    final cur = currency ?? currencyNotifier.value;
    final value = fromBase(idrAmount, cur);
    final decimals = _decimals[cur] ?? 0;

    final isNegative = value < 0;
    final fixed = value.abs().toStringAsFixed(decimals);

    String intPart;
    String fracPart = '';
    if (fixed.contains('.')) {
      final parts = fixed.split('.');
      intPart = parts[0];
      fracPart = parts[1];
    } else {
      intPart = fixed;
    }

    // Indonesian-style grouping for IDR ("."), US-style for USD/EUR (",").
    final groupSep = cur == 'IDR' ? '.' : ',';
    final decSep = cur == 'IDR' ? ',' : '.';
    final grouped = _groupThousands(intPart, groupSep);

    final number =
        decimals > 0 ? '$grouped$decSep$fracPart' : grouped;
    return '${isNegative ? '-' : ''}${symbol(cur)} $number';
  }

  static String _groupThousands(String intPart, String sep) {
    final buffer = StringBuffer();
    final len = intPart.length;
    for (var i = 0; i < len; i++) {
      if (i != 0 && (len - i) % 3 == 0) buffer.write(sep);
      buffer.write(intPart[i]);
    }
    return buffer.toString();
  }
}
