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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ✅ Helper class for localization without BuildContext
class LocalizedMessages {
  // Default messages (English fallback)
  static const Map<String, String> _defaultMessages = {
    'notification_settings_saved': 'Notification settings saved successfully',
    'failed_to_save_notification_settings': 'Failed to save notification settings',
    'removed_from_wishlist_success': 'Removed from wishlist successfully!',
    'failed_to_remove_from_wishlist': 'Failed to remove from wishlist',
    'failed_to_get_notification_settings': 'Failed to get notification settings',
    'verification_code_sent': 'Verification code sent',
    'failed_to_send_verification_code': 'Failed to send verification code',
    'email_updated_successfully': 'Email updated successfully',
    'verification_failed': 'Verification failed',
    'all_notifications_marked_read': 'All notifications marked as read',
    'failed_to_mark_notifications_read': 'Failed to mark notifications as read',
    'withdrawal_request_submitted': 'Withdrawal request submitted successfully',
    'failed_to_submit_withdrawal': 'Failed to submit withdrawal request',
    'failed_to_update_payment_details': 'Failed to update payment details',
    'failed_to_get_payment_details': 'Failed to get payment details',
    'network_error_try_again': 'Network error. Please try again.',
    'failed_to_load_notifications': 'Failed to load notifications',
    'failed_to_load_wishlist': 'Failed to load wishlist',
    'failed_to_load_activities': 'Failed to load activities',
    'failed_to_load_comments': 'Failed to load comments',
    'failed_to_load_reviews': 'Failed to load reviews',
    'failed_to_load_bid_history': 'Failed to load bid history',
    'failed_to_add_to_wishlist': 'Failed to add to wishlist',
    'add_to_wishlist_success': 'Added to wishlist successfully!',
    'wishlist_update_failed': 'Wishlist update failed',
    'bid_placed_successfully': 'Bid placed successfully',
    'bid_placed': 'Bid placed!',
    'failed_to_place_bid': 'Failed to place bid',
    'auction_time_extended': '⏰ Auction time extended!',
    'comment_added_successfully': 'Comment added successfully',
    'failed_to_add_comment': 'Failed to add comment',
    'review_submitted_successfully': 'Review submitted successfully',
    'failed_to_submit_review': 'Failed to submit review',
    'notify_me_success': 'You will be notified when this auction starts',
    'notify_me_failed': 'Failed to set notification',
    'message_sent_to_seller': 'Message sent to seller!',
    'failed_to_contact_seller': 'Failed to contact seller',
    'something_went_wrong': 'Something went wrong',
  };

  static String getMessage(String key, [Map<String, String>? params]) {
    String message = _defaultMessages[key] ?? key;
    
    if (params != null) {
      params.forEach((key, value) {
        message = message.replaceAll('{$key}', value);
      });
    }
    
    return message;
  }
}

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

  // =============================================
  // GET USER INFO WITH PAGINATION SUPPORT
  // =============================================
  Future<dynamic> getUserInfoResponse({
    BuildContext? context,
    int notificationPage = 1,
    int notificationPerPage = 10,
    int pointPage = 1,
    int pointPerPage = 10,
    int cashPage = 1,
    int cashPerPage = 10,
    int withdrawPage = 1,
    int withdrawPerPage = 10,
    int wishlistPage = 1,
    int wishlistPerPage = 20,
    int auctionBidPage = 1,
    int auctionBidPerPage = 20,
    int distinctPage = 1,
    int distinctPerPage = 20,
  }) async {
    String url = "${AppConfig.BASE_URL}/customer/info"
        "?notification_page=$notificationPage"
        "&notification_per_page=$notificationPerPage"
        "&point_page=$pointPage"
        "&point_per_page=$pointPerPage"
        "&cash_page=$cashPage"
        "&cash_per_page=$cashPerPage"
        "&withdraw_page=$withdrawPage"
        "&withdraw_per_page=$withdrawPerPage"
        "&wishlist_page=$wishlistPage"
        "&wishlist_per_page=$wishlistPerPage"
        "&auction_bid_page=$auctionBidPage"
        "&auction_bid_per_page=$auctionBidPerPage"
        "&distinct_page=$distinctPage"
        "&distinct_per_page=$distinctPerPage";
    
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

  // =============================================
  // GET NOTIFICATIONS WITH PAGINATION
  // =============================================
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 10,
  }) async {
    String url = "${AppConfig.BASE_URL}/notifications?page=$page&per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'data': responseData['data'] ?? [],
          'pagination': responseData['pagination'] ?? {},
          'unread_count': responseData['unread_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_load_notifications'),
        };
      }
    } catch (e) {
      print("Error loading notifications: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
      };
    }
  }

  // =============================================
  // GET POINT HISTORY WITH PAGINATION
  // =============================================
  Future<Map<String, dynamic>> getPointHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    String url = "${AppConfig.BASE_URL}/point-history?page=$page&per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'data': responseData['data'] ?? [],
          'pagination': responseData['pagination'] ?? {},
          'total_points': responseData['total_points'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_load_activities'),
        };
      }
    } catch (e) {
      print("Error loading point history: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
      };
    }
  }

  // =============================================
  // GET CASH HISTORY WITH PAGINATION
  // =============================================
  Future<Map<String, dynamic>> getCashHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    String url = "${AppConfig.BASE_URL}/cash-history?page=$page&per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'data': responseData['data'] ?? [],
          'pagination': responseData['pagination'] ?? {},
          'total_cash': responseData['total_cash'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_load_activities'),
        };
      }
    } catch (e) {
      print("Error loading cash history: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
      };
    }
  }

  // =============================================
  // GET WITHDRAW REQUESTS WITH PAGINATION
  // =============================================
  Future<Map<String, dynamic>> getWithdrawRequests({
    int page = 1,
    int perPage = 10,
  }) async {
    String url = "${AppConfig.BASE_URL}/withdraw-requests?page=$page&per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'data': responseData['data'] ?? [],
          'pagination': responseData['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load withdraw requests',
        };
      }
    } catch (e) {
      print("Error loading withdraw requests: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
      };
    }
  }

  // =============================================
  // LOAD MORE NOTIFICATIONS (Helper method)
  // =============================================
  Future<Map<String, dynamic>> loadMoreNotifications({
    required int currentPage,
    int perPage = 10,
  }) async {
    return await getNotifications(
      page: currentPage + 1,
      perPage: perPage,
    );
  }

  // =============================================
  // LOAD MORE POINTS (Helper method)
  // =============================================
  Future<Map<String, dynamic>> loadMorePoints({
    required int currentPage,
    int perPage = 10,
  }) async {
    return await getPointHistory(
      page: currentPage + 1,
      perPage: perPage,
    );
  }

  // =============================================
  // LOAD MORE CASH (Helper method)
  // =============================================
  Future<Map<String, dynamic>> loadMoreCash({
    required int currentPage,
    int perPage = 10,
  }) async {
    return await getCashHistory(
      page: currentPage + 1,
      perPage: perPage,
    );
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('notification_settings_saved'),
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_save_notification_settings'),
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error updating notification settings: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('removed_from_wishlist_success'),
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_remove_from_wishlist'),
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error removing from wishlist: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': LocalizedMessages.getMessage('failed_to_get_notification_settings'),
        };
      }
    } catch (e) {
      print("Error getting notification settings: $e");
      return {
        'success': false,
        'settings': {},
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('verification_code_sent'),
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? LocalizedMessages.getMessage('failed_to_send_verification_code'),
          };
        } catch (e) {
          return {
            'success': false,
            'message': LocalizedMessages.getMessage('failed_to_send_verification_code'),
          };
        }
      }
    } catch (e) {
      print("Error sending verification code: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('email_updated_successfully'),
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? LocalizedMessages.getMessage('verification_failed'),
          };
        } catch (e) {
          return {
            'success': false,
            'message': LocalizedMessages.getMessage('verification_failed'),
          };
        }
      }
    } catch (e) {
      print("Error verifying email: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('all_notifications_marked_read'),
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_mark_notifications_read'),
        };
      }
    } catch (e) {
      print("Error marking all notifications as read: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': responseData['message'] ?? LocalizedMessages.getMessage('withdrawal_request_submitted'),
          'data': responseData['data'],
        };
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? LocalizedMessages.getMessage('failed_to_submit_withdrawal'),
            'status': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': LocalizedMessages.getMessage('failed_to_submit_withdrawal'),
            'status': response.statusCode,
          };
        }
      }
    } catch (e) {
      print("Error submitting withdrawal: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': LocalizedMessages.getMessage('failed_to_update_payment_details')
        };
      }
    } catch (e) {
      print("Error updating payment details: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
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
          'message': LocalizedMessages.getMessage('failed_to_get_payment_details')
        };
      }
    } catch (e) {
      print("Error getting payment details: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error_try_again'),
      };
    }
  }

  // =============================================
  // GET WISHLIST WITH PAGINATION
  // =============================================
  Future<WishlistPaginatedResponse> getWishlistPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    String url = "${AppConfig.BASE_URL}/customer/info?wishlist_page=$page&wishlist_per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Extract the first customer's data (assuming single user)
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          final customerData = responseData['data'][0];
          return WishlistPaginatedResponse.fromJson(customerData);
        }
        return WishlistPaginatedResponse(
          success: true,
          data: [],
          pagination: WishlistPagination(currentPage: page, perPage: perPage, total: 0),
          wishlistCount: 0,
        );
      } else {
        return WishlistPaginatedResponse(
          success: false,
          data: [],
          pagination: WishlistPagination(currentPage: page, perPage: perPage, total: 0),
          wishlistCount: 0,
        );
      }
    } catch (e) {
      print("Error loading wishlist: $e");
      return WishlistPaginatedResponse(
        success: false,
        data: [],
        pagination: WishlistPagination(currentPage: page, perPage: perPage, total: 0),
        wishlistCount: 0,
      );
    }
  }

  // =============================================
  // GET AUCTION BIDS WITH PAGINATION
  // =============================================
  Future<AuctionBidsPaginatedResponse> getAuctionBidsPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    String url = "${AppConfig.BASE_URL}/customer/info?auction_bid_page=$page&auction_bid_per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          final customerData = responseData['data'][0];
          return AuctionBidsPaginatedResponse.fromJson(customerData);
        }
        return AuctionBidsPaginatedResponse(
          success: true,
          data: [],
          pagination: AuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
          auctionBidsCount: 0,
        );
      } else {
        return AuctionBidsPaginatedResponse(
          success: false,
          data: [],
          pagination: AuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
          auctionBidsCount: 0,
        );
      }
    } catch (e) {
      print("Error loading auction bids: $e");
      return AuctionBidsPaginatedResponse(
        success: false,
        data: [],
        pagination: AuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
        auctionBidsCount: 0,
      );
    }
  }

  // =============================================
  // GET DISTINCT AUCTION BIDS WITH PAGINATION
  // =============================================
  Future<DistinctAuctionBidsPaginatedResponse> getDistinctAuctionBidsPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    String url = "${AppConfig.BASE_URL}/customer/info?distinct_page=$page&distinct_per_page=$perPage";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          final customerData = responseData['data'][0];
          return DistinctAuctionBidsPaginatedResponse.fromJson(customerData);
        }
        return DistinctAuctionBidsPaginatedResponse(
          success: true,
          data: [],
          pagination: DistinctAuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
          distinctAuctionBidsCount: 0,
        );
      } else {
        return DistinctAuctionBidsPaginatedResponse(
          success: false,
          data: [],
          pagination: DistinctAuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
          distinctAuctionBidsCount: 0,
        );
      }
    } catch (e) {
      print("Error loading distinct auction bids: $e");
      return DistinctAuctionBidsPaginatedResponse(
        success: false,
        data: [],
        pagination: DistinctAuctionBidsPagination(currentPage: page, perPage: perPage, total: 0),
        distinctAuctionBidsCount: 0,
      );
    }
  }

  // =============================================
  // LOAD MORE WISHLIST ITEMS
  // =============================================
  Future<WishlistPaginatedResponse> loadMoreWishlistItems({
    required int currentPage,
    int perPage = 20,
  }) async {
    return await getWishlistPaginated(
      page: currentPage + 1,
      perPage: perPage,
    );
  }

  // =============================================
  // LOAD MORE AUCTION BIDS
  // =============================================
  Future<AuctionBidsPaginatedResponse> loadMoreAuctionBids({
    required int currentPage,
    int perPage = 20,
  }) async {
    return await getAuctionBidsPaginated(
      page: currentPage + 1,
      perPage: perPage,
    );
  }

  // =============================================
  // LOAD MORE DISTINCT AUCTION BIDS
  // =============================================
  Future<DistinctAuctionBidsPaginatedResponse> loadMoreDistinctAuctionBids({
    required int currentPage,
    int perPage = 20,
  }) async {
    return await getDistinctAuctionBidsPaginated(
      page: currentPage + 1,
      perPage: perPage,
    );
  }

  Future<Map<String, dynamic>> submitReferralCode({
    required int userId,
    String? referralCode,
  }) async {
    var url = "${AppConfig.BASE_URL}/api/user/submit-referral";
    
    final body = {
      "user_id": userId.toString(),
      if (referralCode != null) "referral_code": referralCode,
    };
    
    var response = await ApiRequest.post(
      url: url,
      body: body,
    );
    
    return jsonDecode(response.body);
  }
}