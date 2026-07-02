import 'package:toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:one_context/one_context.dart';
import 'package:audioplayers/audioplayers.dart';

class ToastComponent {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Play sound based on toast type
  static Future<void> _playSound(String soundFile) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      // Silent fail - don't crash if sound can't play
      print('Error playing toast sound: $e');
    }
  }

  // ============================================
  // ✅ SUCCESS TOAST - Green with success sound
  // ============================================
  static showSuccess(String msg, {duration = 0, gravity = 0}) {
    _playSound('success.wav');
    _showToast(
      msg,
      duration: duration,
      gravity: gravity,
      backgroundColor: const Color(0xFF10B981), // Green
      textColor: Colors.white,
      borderColor: const Color(0xFF059669),
    );
  }

  // ============================================
  // ❌ ERROR TOAST - Red with error sound
  // ============================================
  static showError(String msg, {duration = 0, gravity = 0}) {
    _playSound('error.wav');
    _showToast(
      msg,
      duration: duration,
      gravity: gravity,
      backgroundColor: const Color(0xFFEF4444), // Red
      textColor: Colors.white,
      borderColor: const Color(0xFFDC2626),
    );
  }

  // ============================================
  // ⚠️ WARNING TOAST - Orange with warning sound
  // ============================================
  static showWarning(String msg, {duration = 0, gravity = 0}) {
    _playSound('error.wav');
    _showToast(
      msg,
      duration: duration,
      gravity: gravity,
      backgroundColor: const Color(0xFFF59E0B), // Orange
      textColor: Colors.white,
      borderColor: const Color(0xFFD97706),
    );
  }

  // ============================================
  // 📘 INFO TOAST - Blue (default)
  // ============================================
  static showInfo(String msg, {duration = 0, gravity = 0}) {
    _showToast(
      msg,
      duration: duration,
      gravity: gravity,
      backgroundColor: const Color(0xFF3B82F6), // Blue
      textColor: Colors.white,
      borderColor: const Color(0xFF2563EB),
    );
  }

  // ============================================
  // 🔄 LEGACY - Kept for backward compatibility
  // ============================================
  static showDialog(String msg, {duration = 0, gravity = 0}) {
    showInfo(msg, duration: duration, gravity: gravity);
  }

  // ============================================
  // 🛠️ PRIVATE - Core toast display method
  // ============================================
  static void _showToast(
    String msg, {
    required int duration,
    required int gravity,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    try {
      // Try to get context from OneContext
      BuildContext? context = OneContext().context;
      
      // If OneContext is null, try to use the default context
      if (context == null) {
        // Fallback: Use a different approach for Home page
        _showFallbackToast(msg, duration, gravity, backgroundColor, textColor);
        return;
      }
      
      ToastContext().init(context);
      Toast.show(
        msg,
        duration: duration != 0 ? duration : Toast.lengthShort,
        gravity: gravity != 0 ? gravity : Toast.bottom,
        backgroundColor: backgroundColor,
        textStyle: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
        ),
        backgroundRadius: 6,
      );
    } catch (e) {
      print('Toast error: $e');
      // Fallback to basic toast
      _showFallbackToast(msg, duration, gravity, backgroundColor, textColor);
    }
  }

  // ============================================
  // 🔄 FALLBACK - Used when OneContext fails
  // ============================================
  static void _showFallbackToast(
    String msg,
    int duration,
    int gravity,
    Color backgroundColor,
    Color textColor,
  ) {
    try {
      // Try to use the global navigator context as fallback
      // This is a simplified version that should work on the Home page
      Toast.show(
        msg,
        duration: duration != 0 ? duration : Toast.lengthShort,
        gravity: gravity != 0 ? gravity : Toast.bottom,
        backgroundColor: backgroundColor,
        textStyle: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        backgroundRadius: 6,
      );
    } catch (e2) {
      print('Fallback toast also failed: $e2');
      // Last resort - show a basic toast
      try {
        Toast.show(
          msg,
          duration: Toast.lengthShort,
          gravity: Toast.bottom,
        );
      } catch (_) {
        // Ignore - we tried our best
      }
    }
  }
}