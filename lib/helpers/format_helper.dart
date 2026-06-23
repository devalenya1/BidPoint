import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';

class FormatHelper {
  static String formatPrice(double? price) {
    if (price == null) return '\$0.00';
    // Use system currency symbol if available, otherwise fallback to $
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
  }
  
  static String formatPoints(dynamic points) {
    if (points == null) return '0';
    if (points is double) return points.toInt().toString();
    return points.toString();
  }
  
  static String formatAffiliateBalance(double? balance) {
    if (balance == null) return '\$0.00';
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${balance.toStringAsFixed(2)}';
  }
}