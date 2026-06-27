// import 'package:active_ecommerce_flutter/data_model/user_info_response.dart';
// import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';

// class UserDataHelper {
//   static void saveUserData(UserInformation user) {
//     // Basic Info
//     user_name.$ = user.name ?? "";
//     user_email.$ = user.email ?? "";
//     user_phone.$ = user.phone ?? "";
//     avatar_original.$ = user.avatar ?? "";
//     user_id.$ = user.id ?? 0;
    
//     // Address Info
//     user_address.$ = user.address ?? "";
//     user_country.$ = user.country ?? "";
//     user_state.$ = user.state ?? "";
//     user_city.$ = user.city ?? "";
//     user_postal_code.$ = user.postalCode ?? "";
    
//     // Points Balance - convert double to string
//     points_balance.$ = user.balance?.toString() ?? "0";
    
//     // Affiliate Fields
//     affiliate_id.$ = user.affiliateId ?? "";
//     paypal_email.$ = user.paypalEmail ?? "";
//     bank_name.$ = user.bankName ?? "";
//     account_holder.$ = user.accountHolder ?? "";
//     account_number.$ = user.accountNumber ?? "";
//     ifsc_code.$ = user.ifscCode ?? "";
//     affiliate_balance.$ = user.affiliateBalance?.toString() ?? "0";
//     affiliate_status.$ = user.affiliateStatus ?? 0;
//     referral_code.$ = user.referralCode ?? "";
//     total_affiliate_earnings.$ = user.totalAffiliateEarnings?.toString() ?? "0";
    
//     // Package Info
//     customer_package_id.$ = user.packageId ?? 0;
//     customer_package_name.$ = user.packageName ?? "";
//     remaining_uploads.$ = user.remainingUploads ?? 0;
    
//     // Counts
//     unread_notifications_count.$ = user.unreadNotificationsCount ?? 0;
//     wishlist_count.$ = user.wishlistCount ?? 0;
//     auction_bids_count.$ = user.auctionBidsCount ?? 0;
//     distinct_auction_bids_count.$ = user.distinctAuctionBidsCount ?? 0;
//     address_count.$ = user.addressCount ?? 0;
//     default_address_count.$ = user.defaultAddressCount ?? 0;
    
//     // Financial
//     total_withdrawn_amount.$ = user.totalWithdrawnAmount?.toString() ?? "0";
//     pending_withdraw_amount.$ = user.pendingWithdrawAmount?.toString() ?? "0";
//     total_package_payments.$ = user.totalPackagePayments?.toString() ?? "0";
//   }
  
//   static void clearUserData() {
//     // Basic Info
//     user_name.$ = "";
//     user_email.$ = "";
//     user_phone.$ = "";
//     avatar_original.$ = "";
//     user_id.$ = 0;
    
//     // Address Info
//     user_address.$ = "";
//     user_country.$ = "";
//     user_state.$ = "";
//     user_city.$ = "";
//     user_postal_code.$ = "";
    
//     // Points Balance
//     points_balance.$ = "0";
    
//     // Affiliate Fields
//     affiliate_id.$ = "";
//     paypal_email.$ = "";
//     bank_name.$ = "";
//     account_holder.$ = "";
//     account_number.$ = "";
//     ifsc_code.$ = "";
//     affiliate_balance.$ = "0";
//     affiliate_status.$ = 0;
//     referral_code.$ = "";
//     total_affiliate_earnings.$ = "0";
    
//     // Package Info
//     customer_package_id.$ = 0;
//     customer_package_name.$ = "";
//     remaining_uploads.$ = 0;
    
//     // Counts
//     unread_notifications_count.$ = 0;
//     wishlist_count.$ = 0;
//     auction_bids_count.$ = 0;
//     distinct_auction_bids_count.$ = 0;
//     address_count.$ = 0;
//     default_address_count.$ = 0;
    
//     // Financial
//     total_withdrawn_amount.$ = "0";
//     pending_withdraw_amount.$ = "0";
//     total_package_payments.$ = "0";
//   }
// }