import 'package:active_ecommerce_flutter/my_theme.dart';

class FormatHelper {
  static String formatPrice(double? price) {
    if (price == null) return '\$0.00';
    return '\$${price.toStringAsFixed(2)}';
  }
  
  static String formatPoints(dynamic points) {
    if (points == null) return '0';
    if (points is double) return points.toInt().toString();
    return points.toString();
  }
  
  static String formatAffiliateBalance(double? balance) {
    if (balance == null) return '\$0.00';
    return '\$${balance.toStringAsFixed(2)}';
  }
}