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
    // Default to info (or you can change to warning)
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
    ToastContext().init(OneContext().context!);
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
  }
}