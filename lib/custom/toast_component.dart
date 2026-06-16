import 'package:toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:one_context/one_context.dart';

class ToastComponent {
  // Constants for compatibility
  static const int LENGTH_SHORT = 2;
  static const int LENGTH_LONG = 4;
  static const int CENTER = 1;
  static const int BOTTOM = 0;
  static const int TOP = 2;
  
  static showDialog(String msg, {int duration = 2, int gravity = 0}) {
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