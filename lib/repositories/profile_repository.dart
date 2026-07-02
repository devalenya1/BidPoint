import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/data_model/check_response_model.dart';
import 'package:active_ecommerce_flutter/data_model/profile_image_update_response.dart';
import 'package:active_ecommerce_flutter/data_model/user_info_response.dart';
import 'dart:convert';
import 'package:active_ecommerce_flutter/data_model/profile_counters_response.dart';
import 'package:active_ecommerce_flutter/data_model/profile_update_response.dart';
import 'package:active_ecommerce_flutter/data_model/device_token_update_response.dart';
import 'package:active_ecommerce_flutter/data_model/phone_email_availability_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/repositories/api-request.dart';
import 'package:active_ecommerce_flutter/middlewares/banned_user.dart';
import 'package:flutter/foundation.dart';
import 'package:active_ecommerce_flutter/helpers/debug_helper.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart' show kDebugMode;
// ✅ Add this import for localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileRepository {

  Future<dynamic> getProfileCountersResponse() async {
    String url=("${AppConfig.BASE_URL}/profile/counters");
    final response = await ApiRequest.get(
      url:url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );
    return profileCountersResponseFromJson(response.body);
  }

  Future<dynamic> getProfileUpdateResponse({required String post_body}) async {
    String url=("${AppConfig.BASE_URL}/profile/update");
    final response = await ApiRequest.post(
      url:url,
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: post_body 
    );
    return profileUpdateResponseFromJson(response.body);
  }

  Future<dynamic> getDeviceTokenUpdateResponse(String device_token) async {
    var post_body = jsonEncode({"device_token": "${device_token}"});
    String url=("${AppConfig.BASE_URL}/profile/update-device-token");
    final response = await ApiRequest.post(
      url:url,
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: post_body 
    );
    return deviceTokenUpdateResponseFromJson(response.body);
  }

  Future<dynamic> getProfileImageUpdateResponse(String image, String filename) async {
    var post_body = jsonEncode({"image": "${image}", "filename": "$filename"});
    print(post_body.toString());
    String url=("${AppConfig.BASE_URL}/profile/update-image");
    final response = await ApiRequest.post(
      url:url,
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: post_body 
    );
    return profileImageUpdateResponseFromJson(response.body);
  }

  Future<dynamic> getPhoneEmailAvailabilityResponse() async {
    String url=("${AppConfig.BASE_URL}/profile/check-phone-and-email");
    final response = await ApiRequest.post(
      url:url,
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: ''
    );
    return phoneEmailAvailabilityResponseFromJson(response.body);
  }

  Future<dynamic> getUserInfoResponse({BuildContext? context}) async {
    String url = "${AppConfig.BASE_URL}/customer/info";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}", 
          "App-Language": app_language.$!
        },
      );
      
      // Show debug popup with response
      if (context != null && kDebugMode) {
        DebugHelper.showApiResponseDialog(
          context,
          title: "User Info API Response",
          responseData: response.body,
          isSuccess: response.statusCode == 200,
        );
      }
      
      return userInfoResponseFromJson(response.body);
    } catch (e, stackTrace) {
      if (context != null && kDebugMode) {
        DebugHelper.showErrorDialog(
          context,
          title: "Failed to fetch user info",
          error: e,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  // Update notification settings
  Future<Map<String, dynamic>> updateNotificationSettings(Map<String, bool> settings) async {
    String url = "${AppConfig.BASE_URL}/notification-settings/update";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode(settings),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.notification_settings_saved,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': AppLocalizations.of(context!)!.failed_to_save_notification_settings,
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error updating notification settings: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Remove from wishlist
  Future<Map<String, dynamic>> removeFromWishlist(int productId) async {
    String url = "${AppConfig.BASE_URL}/wishlist/remove";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "product_id": productId,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.removed_from_wishlist_success,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': AppLocalizations.of(context!)!.failed_to_remove_from_wishlist,
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error removing from wishlist: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    String url = "${AppConfig.BASE_URL}/notification-settings";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'settings': responseData['settings'] ?? {},
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'settings': {},
          'message': AppLocalizations.of(context!)!.failed_to_get_notification_settings,
        };
      }
    } catch (e) {
      print("Error getting notification settings: $e");
      return {
        'success': false,
        'settings': {},
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }


  // Send email verification code
  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    String url = "${AppConfig.BASE_URL}/user/email/verify/send";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({"email": email})
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.verification_code_sent,
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? AppLocalizations.of(context!)!.failed_to_send_verification_code,
          };
        } catch (e) {
          return {
            'success': false,
            'message': AppLocalizations.of(context!)!.failed_to_send_verification_code,
          };
        }
      }
    } catch (e) {
      print("Error sending verification code: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Verify and update email
  Future<Map<String, dynamic>> verifyAndUpdateEmail(String email, String code) async {
    String url = "${AppConfig.BASE_URL}/user/email/verify/update";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "email": email,
          "code": code,
        })
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.email_updated_successfully,
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? AppLocalizations.of(context!)!.verification_failed,
          };
        } catch (e) {
          return {
            'success': false,
            'message': AppLocalizations.of(context!)!.verification_failed,
          };
        }
      }
    } catch (e) {
      print("Error verifying email: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    String url = "${AppConfig.BASE_URL}/notification/mark-all-read";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.all_notifications_marked_read,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': AppLocalizations.of(context!)!.failed_to_mark_notifications_read,
        };
      }
    } catch (e) {
      print("Error marking all notifications as read: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Submit withdrawal request
  Future<Map<String, dynamic>> submitWithdrawalRequest(double amount) async {
    String url = "${AppConfig.BASE_URL}/affiliate/withdraw-request";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "amount": amount,
        })
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? AppLocalizations.of(context!)!.withdrawal_request_submitted,
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? AppLocalizations.of(context!)!.failed_to_submit_withdrawal,
            'status': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': AppLocalizations.of(context!)!.failed_to_submit_withdrawal,
            'status': response.statusCode,
          };
        }
      }
    } catch (e) {
      print("Error submitting withdrawal: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Update affiliate payment details
  Future<Map<String, dynamic>> updateAffiliatePaymentDetails({
    required String paypalEmail,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String ifscCode,
  }) async {
    String url = "${AppConfig.BASE_URL}/affiliate/payment-details/update";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "paypal_email": paypalEmail,
          "bank_name": bankName,
          "account_holder": accountHolder,
          "account_number": accountNumber,
          "ifsc_code": ifscCode,
        })
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'status': response.statusCode,
          'message': AppLocalizations.of(context!)!.failed_to_update_payment_details
        };
      }
    } catch (e) {
      print("Error updating payment details: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }

  // Get affiliate payment details
  Future<Map<String, dynamic>> getAffiliatePaymentDetails() async {
    String url = "${AppConfig.BASE_URL}/affiliate/payment-details";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: '{}'
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'status': response.statusCode,
          'message': AppLocalizations.of(context!)!.failed_to_get_payment_details
        };
      }
    } catch (e) {
      print("Error getting payment details: $e");
      return {
        'success': false,
        'message': AppLocalizations.of(context!)!.network_error_try_again,
      };
    }
  }
}