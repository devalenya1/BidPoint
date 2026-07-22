import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:intl/intl.dart';

class FormatHelper {
  static String formatPrice(double? price) {
    if (price == null) return '\$0.00';
    // Use system currency symbol if available, otherwise fallback to $
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    
    // Format with thousands separators and 2 decimal places
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    
    return '$symbol${formatter.format(price)}';
  }
  
  // ✅ FIXED: Now formats with thousands separators
  static String formatPoints(dynamic points) {
    if (points == null) return '0';
    
    // Convert to int first
    int value;
    if (points is double) {
      value = points.toInt();
    } else if (points is int) {
      value = points;
    } else {
      value = int.tryParse(points.toString()) ?? 0;
    }
    
    // Format with thousands separators
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(value);
  }
  
  static String formatAffiliateBalance(double? balance) {
    if (balance == null) return '\$0.00';
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    
    // Format with thousands separators and 2 decimal places
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    
    return '$symbol${formatter.format(balance)}';
  }
  
  // Additional helper for formatting without currency symbol
  static String formatNumber(double? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,###.##', 'en_US');
    return formatter.format(number);
  }
  
  // Helper for formatting integers with commas
  static String formatInt(int? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }
}