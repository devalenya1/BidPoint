import 'package:toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:one_context/one_context.dart';

class ToastComponent {
  // Constants for compatibility
  static const int LENGTH_SHORT = Toast.LENGTH_SHORT;
  static const int LENGTH_LONG = Toast.LENGTH_LONG;
  static const int CENTER = Toast.CENTER;
  static const int BOTTOM = Toast.BOTTOM;
  static const int TOP = Toast.TOP;
  
  static showDialog(String msg, {int duration = Toast.LENGTH_SHORT, int gravity = Toast.BOTTOM}) {
    ToastContext().init(OneContext().context!);
    Toast.show(
      msg,
      duration: duration,
      gravity: gravity,
      backgroundColor: Color.fromRGBO(239, 239, 239, .9),
      textStyle: TextStyle(color: MyTheme.font_grey),
      border: Border(
        top: BorderSide(color: Color.fromRGBO(203, 209, 209, 1)),
        bottom: BorderSide(color: Color.fromRGBO(203, 209, 209, 1)),
        right: BorderSide(color: Color.fromRGBO(203, 209, 209, 1)),
        left: BorderSide(color: Color.fromRGBO(203, 209, 209, 1)),
      ),
      backgroundRadius: 6,
    );
  }
}