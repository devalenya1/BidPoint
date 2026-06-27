import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/repositories/auth_repository.dart';

import '../data_model/login_response.dart';

class AuthHelper {
  setUserData(LoginResponse loginResponse) {
    if (loginResponse.result == true) {
      SystemConfig.systemUser = loginResponse.user;
      
      // Auth values
      is_logged_in.$ = true;
      is_logged_in.save();
      
      access_token.$ = loginResponse.access_token;
      access_token.save();
      
      user_id.$ = loginResponse.user?.id;
      user_id.save();
      
      user_name.$ = loginResponse.user?.name;
      user_name.save();
      
      user_email.$ = loginResponse.user?.email ?? "";
      user_email.save();
      
      user_phone.$ = loginResponse.user?.phone ?? "";
      user_phone.save();
      
      avatar_original.$ = loginResponse.user?.avatar_original;
      avatar_original.save();
    }
  }

  clearUserData() {
    // ✅ Clear SystemConfig
    SystemConfig.systemUser = null;
    
    // ============================================
    // ✅ CLEAR ALL SHARED VALUES
    // ============================================
    
    // Auth values
    is_logged_in.$ = false;
    is_logged_in.save();
    
    access_token.$ = "";
    access_token.save();
    
    user_id.$ = 0;
    user_id.save();
    
    avatar_original.$ = "";
    avatar_original.save();
    
    // User info
    user_name.$ = "";
    user_name.save();
    
    user_email.$ = "";
    user_email.save();
    
    user_phone.$ = "";
    user_phone.save();
    
    // ✅ Clear ALL other user-related shared values
    user_address.$ = "";
    user_address.save();
    
    user_country.$ = "";
    user_country.save();
    
    user_state.$ = "";
    user_state.save();
    
    user_city.$ = "";
    user_city.save();
    
    user_postal_code.$ = "";
    user_postal_code.save();
    
    // Points & Balance
    points_balance.$ = "0";
    points_balance.save();
    
    // Affiliate fields
    affiliate_id.$ = "";
    affiliate_id.save();
    
    paypal_email.$ = "";
    paypal_email.save();
    
    bank_name.$ = "";
    bank_name.save();
    
    account_holder.$ = "";
    account_holder.save();
    
    account_number.$ = "";
    account_number.save();
    
    ifsc_code.$ = "";
    ifsc_code.save();
    
    affiliate_balance.$ = "0";
    affiliate_balance.save();
    
    affiliate_status.$ = 0;
    affiliate_status.save();
    
    referral_code.$ = "";
    referral_code.save();
    
    referral_link.$ = "";
    referral_link.save();
    
    total_affiliate_earnings.$ = "0";
    total_affiliate_earnings.save();
    
    // Package fields
    customer_package_id.$ = 0;
    customer_package_id.save();
    
    customer_package_name.$ = "";
    customer_package_name.save();
    
    remaining_uploads.$ = 0;
    remaining_uploads.save();
    
    // Notification counts
    unread_notifications_count.$ = 0;
    unread_notifications_count.save();
    
    // Wishlist
    wishlist_count.$ = 0;
    wishlist_count.save();
    
    // Auction bids
    auction_bids_count.$ = 0;
    auction_bids_count.save();
    
    distinct_auction_bids_count.$ = 0;
    distinct_auction_bids_count.save();
    
    // Withdrawal amounts
    total_withdrawn_amount.$ = "0";
    total_withdrawn_amount.save();
    
    pending_withdraw_amount.$ = "0";
    pending_withdraw_amount.save();
    
    // Address counts
    address_count.$ = 0;
    address_count.save();
    
    default_address_count.$ = 0;
    default_address_count.save();
    
    // Package payments
    total_package_payments.$ = "0";
    total_package_payments.save();
  }

  fetch_and_set() async {
    var userByTokenResponse = await AuthRepository().getUserByTokenResponse();
    if (userByTokenResponse.result == true) {
      setUserData(userByTokenResponse);
    } else {
      clearUserData();
    }
  }
}