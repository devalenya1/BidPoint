import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:shared_value/shared_value.dart';

final SharedValue<bool> is_logged_in = SharedValue(
  value: false,
  key: "is_logged_in",
);

final SharedValue<String?> access_token = SharedValue(
  value: "",
  key: "access_token",
);

final SharedValue<int?> user_id = SharedValue(
  value: 0,
  key: "user_id",
);

final SharedValue<String?> avatar_original = SharedValue(
  value: "",
  key: "avatar_original",
);

final SharedValue<String?> user_name = SharedValue(
  value: "",
  key: "user_name",
);

final SharedValue<String> user_email = SharedValue(
  value: "",
  key: "user_email",
);

final SharedValue<String> user_phone = SharedValue(
  value: "",
  key: "user_phone",
);

final SharedValue<String?> app_language = SharedValue(
  value: AppConfig.default_language,
  key: "app_language",
);

final SharedValue<String?> app_mobile_language = SharedValue(
  value: AppConfig.mobile_app_code,
  key: "app_mobile_language",
);

final SharedValue<int?> system_currency = SharedValue(
  key: "system_currency", 
  value: 0,
);

final SharedValue<bool?> app_language_rtl = SharedValue(
  value: AppConfig.app_language_rtl,
  key: "app_language_rtl",
);

// ============ USER BASIC INFO ============
final SharedValue<String?> user_address = SharedValue(
  value: "",
  key: "user_address",
);

final SharedValue<String?> user_country = SharedValue(
  value: "",
  key: "user_country",
);

final SharedValue<String?> user_state = SharedValue(
  value: "",
  key: "user_state",
);

final SharedValue<String?> user_city = SharedValue(
  value: "",
  key: "user_city",
);

final SharedValue<String?> user_postal_code = SharedValue(
  value: "",
  key: "user_postal_code",
);

// ============ POINTS & BALANCE ============
final SharedValue<String?> points_balance = SharedValue(
  value: "0",
  key: "points_balance",
);

// ============ AFFILIATE FIELDS ============
final SharedValue<String?> affiliate_id = SharedValue(
  value: "",
  key: "affiliate_id",
);

final SharedValue<String?> paypal_email = SharedValue(
  value: "",
  key: "paypal_email",
);

final SharedValue<String?> bank_name = SharedValue(
  value: "",
  key: "bank_name",
);

final SharedValue<String?> account_holder = SharedValue(
  value: "",
  key: "account_holder",
);

final SharedValue<String?> account_number = SharedValue(
  value: "",
  key: "account_number",
);

final SharedValue<String?> ifsc_code = SharedValue(
  value: "",
  key: "ifsc_code",
);

final SharedValue<String?> affiliate_balance = SharedValue(
  value: "0",
  key: "affiliate_balance",
);

final SharedValue<int?> affiliate_status = SharedValue(
  value: 0,
  key: "affiliate_status",
);

final SharedValue<String?> referral_code = SharedValue(
  value: "",
  key: "referral_code",
);

final SharedValue<String?> referral_link = SharedValue(
  value: "",
  key: "referral_link",
);

final SharedValue<String?> total_affiliate_earnings = SharedValue(
  value: "0",
  key: "total_affiliate_earnings",
);

// ============ PACKAGE FIELDS ============
final SharedValue<int?> customer_package_id = SharedValue(
  value: 0,
  key: "customer_package_id",
);

final SharedValue<String?> customer_package_name = SharedValue(
  value: "",
  key: "customer_package_name",
);

final SharedValue<int?> remaining_uploads = SharedValue(
  value: 0,
  key: "remaining_uploads",
);

// ============ NOTIFICATION COUNTS ============
final SharedValue<int?> unread_notifications_count = SharedValue(
  value: 0,
  key: "unread_notifications_count",
);

// ============ WISHLIST ============
final SharedValue<int?> wishlist_count = SharedValue(
  value: 0,
  key: "wishlist_count",
);

// ============ AUCTION BIDS ============
final SharedValue<int?> auction_bids_count = SharedValue(
  value: 0,
  key: "auction_bids_count",
);

final SharedValue<int?> distinct_auction_bids_count = SharedValue(
  value: 0,
  key: "distinct_auction_bids_count",
);

// ============ WITHDRAWAL ============
final SharedValue<String?> total_withdrawn_amount = SharedValue(
  value: "0",
  key: "total_withdrawn_amount",
);

final SharedValue<String?> pending_withdraw_amount = SharedValue(
  value: "0",
  key: "pending_withdraw_amount",
);

// ============ ADDRESS COUNTS ============
final SharedValue<int?> address_count = SharedValue(
  value: 0,
  key: "address_count",
);

final SharedValue<int?> default_address_count = SharedValue(
  value: 0,
  key: "default_address_count",
);

// ============ PACKAGE PAYMENTS ============
final SharedValue<String?> total_package_payments = SharedValue(
  value: "0",
  key: "total_package_payments",
);

// ============ ADDONS START ============
final SharedValue<bool> club_point_addon_installed = SharedValue(
  value: false,
  key: "club_point_addon_installed",
);

final SharedValue<bool> whole_sale_addon_installed = SharedValue(
  value: false,
  key: "whole_sale_addon_installed",
);

final SharedValue<bool> refund_addon_installed = SharedValue(
  value: false,
  key: "refund_addon_installed",
);

final SharedValue<bool> otp_addon_installed = SharedValue(
  value: false,
  key: "otp_addon_installed",
);

final SharedValue<bool> auction_addon_installed = SharedValue(
  value: false,
  key: "auction_addon_installed",
);
// ============ ADDON END ============

// ============ SOCIAL LOGIN START ============
final SharedValue<bool> allow_google_login = SharedValue(
  value: false,
  key: "allow_google_login",
);

final SharedValue<bool> allow_facebook_login = SharedValue(
  value: false,
  key: "allow_facebook_login",
);

final SharedValue<bool> allow_twitter_login = SharedValue(
  value: false,
  key: "allow_twitter_login",
);

final SharedValue<bool> allow_apple_login = SharedValue(
  value: false,
  key: "allow_apple_login",
);
// ============ SOCIAL LOGIN END ============

// ============ BUSINESS SETTING START ============
final SharedValue<bool> pick_up_status = SharedValue(
  value: false,
  key: "pick_up_status",
);

final SharedValue<bool> carrier_base_shipping = SharedValue(
  value: false,
  key: "carrier_base_shipping",
);

final SharedValue<bool> google_recaptcha = SharedValue(
  value: false,
  key: "google_recaptcha",
);

final SharedValue<bool> wallet_system_status = SharedValue(
  value: false,
  key: "wallet_system_status",
);

final SharedValue<bool> mail_verification_status = SharedValue(
  value: false,
  key: "mail_verification_status",
);

final SharedValue<bool> conversation_system_status = SharedValue(
  value: false,
  key: "conversation_system",
);

final SharedValue<bool> vendor_system = SharedValue(
  value: false,
  key: "vendor_system",
);

final SharedValue<bool> classified_product_status = SharedValue(
  value: false,
  key: "classified_product",
);
// ============ BUSINESS SETTING END ============