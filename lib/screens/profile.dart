import 'dart:async';
import 'dart:convert';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/repositories/api-request.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/address.dart';
import 'package:active_ecommerce_flutter/screens/change_language.dart';
import 'package:active_ecommerce_flutter/screens/classified_ads/classified_ads.dart';
import 'package:active_ecommerce_flutter/screens/classified_ads/my_classified_ads.dart';
import 'package:active_ecommerce_flutter/screens/club_point.dart';
import 'package:active_ecommerce_flutter/screens/coupons.dart';
import 'package:active_ecommerce_flutter/screens/currency_change.dart';
import 'package:active_ecommerce_flutter/screens/digital_product/digital_products.dart';
import 'package:active_ecommerce_flutter/screens/digital_product/purchased_digital_produts.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/screens/followed_sellers.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:active_ecommerce_flutter/screens/order_list.dart';
import 'package:active_ecommerce_flutter/screens/profile_edit.dart';
import 'package:active_ecommerce_flutter/screens/refund_request.dart';
import 'package:active_ecommerce_flutter/screens/top_selling_products.dart';
import 'package:active_ecommerce_flutter/screens/uploads/upload_file.dart';
import 'package:active_ecommerce_flutter/screens/wallet.dart';
import 'package:active_ecommerce_flutter/screens/wishlist.dart';
import 'package:active_ecommerce_flutter/screens/notification_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../repositories/auth_repository.dart';
import '../data_model/user_info_response.dart';
import 'auction_purchase_history.dart';
import 'coming_soon_page.dart';
import 'invite_history_page.dart';
import 'payment_settings_page.dart';
import 'terms_conditions_page.dart';
import 'package:flutter/services.dart';

class Profile extends StatefulWidget {
  Profile({Key? key, this.show_back_button = false}) : super(key: key);

  bool show_back_button;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _mainScrollController = ScrollController();
  bool _pointsVisible = true;
  
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;
  
  // ============ INIT ============
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();
    } else {
      _loadFromSharedPreferences();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  // ============ FETCH DATA FROM API ============
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        if (_userInfo != null) {
          user_name.$ = _userInfo!.name ?? "";
          user_name.save();
          user_email.$ = _userInfo!.email ?? "";
          user_email.save();
          user_phone.$ = _userInfo!.phone ?? "";
          user_phone.save();
          avatar_original.$ = _userInfo!.avatar ?? "";
          avatar_original.save();
          points_balance.$ = _userInfo!.balance?.toString() ?? "0";
          points_balance.save();
          affiliate_balance.$ = _userInfo!.affiliateBalance?.toString() ?? "0";
          affiliate_balance.save();
        }
      } else {
        _loadFromSharedPreferences();
      }
    } catch (e) {
      print("Error loading user data: $e");
      _loadFromSharedPreferences();
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  void _loadFromSharedPreferences() {
    setState(() {
      _userInfo = UserInformation(
        name: user_name.$ ?? "",
        email: user_email.$ ?? "",
        phone: user_phone.$ ?? "",
        avatar: avatar_original.$ ?? "",
        balance: double.tryParse(points_balance.$ ?? "0") ?? 0.0,
        affiliateBalance: double.tryParse(affiliate_balance.$ ?? "0") ?? 0.0,
      );
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  void _resetState() {
    setState(() {
      _userInfo = null;
      _isLoading = true;
    });
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.push("/");
    }
  }

  void _togglePointsVisibility() {
    setState(() {
      _pointsVisible = !_pointsVisible;
    });
  }

  // ============ GET ALL SHARED VALUES FOR DEBUG ============
  Map<String, dynamic> _getAllSharedValues() {
    return {
      // Auth values
      'is_logged_in': is_logged_in.$,
      'access_token': access_token.$ != null && access_token.$.isNotEmpty 
          ? '${access_token.$.substring(0, 20)}...' 
          : access_token.$,
      'user_id': user_id.$,
      'avatar_original': avatar_original.$,
      
      // User info
      'user_name': user_name.$,
      'user_email': user_email.$,
      'user_phone': user_phone.$,
      'user_address': user_address.$,
      'user_country': user_country.$,
      'user_state': user_state.$,
      'user_city': user_city.$,
      'user_postal_code': user_postal_code.$,
      
      // App settings (should NOT be cleared)
      'app_language': app_language.$,
      'app_mobile_language': app_mobile_language.$,
      'system_currency': system_currency.$,
      'app_language_rtl': app_language_rtl.$,
      
      // Points & Balance
      'points_balance': points_balance.$,
      
      // Affiliate fields
      'affiliate_id': affiliate_id.$,
      'paypal_email': paypal_email.$,
      'bank_name': bank_name.$,
      'account_holder': account_holder.$,
      'account_number': account_number.$,
      'ifsc_code': ifsc_code.$,
      'affiliate_balance': affiliate_balance.$,
      'affiliate_status': affiliate_status.$,
      'referral_code': referral_code.$,
      'referral_link': referral_link.$,
      'total_affiliate_earnings': total_affiliate_earnings.$,
      
      // Package fields
      'customer_package_id': customer_package_id.$,
      'customer_package_name': customer_package_name.$,
      'remaining_uploads': remaining_uploads.$,
      
      // Notification counts
      'unread_notifications_count': unread_notifications_count.$,
      
      // Wishlist
      'wishlist_count': wishlist_count.$,
      
      // Auction bids
      'auction_bids_count': auction_bids_count.$,
      'distinct_auction_bids_count': distinct_auction_bids_count.$,
      
      // Withdrawal
      'total_withdrawn_amount': total_withdrawn_amount.$,
      'pending_withdraw_amount': pending_withdraw_amount.$,
      
      // Address counts
      'address_count': address_count.$,
      'default_address_count': default_address_count.$,
      
      // Package payments
      'total_package_payments': total_package_payments.$,
      
      // Addons (should NOT be cleared)
      'club_point_addon_installed': club_point_addon_installed.$,
      'whole_sale_addon_installed': whole_sale_addon_installed.$,
      'refund_addon_installed': refund_addon_installed.$,
      'otp_addon_installed': otp_addon_installed.$,
      'auction_addon_installed': auction_addon_installed.$,
      
      // Social login (should NOT be cleared)
      'allow_google_login': allow_google_login.$,
      'allow_facebook_login': allow_facebook_login.$,
      'allow_twitter_login': allow_twitter_login.$,
      'allow_apple_login': allow_apple_login.$,
      
      // Business settings (should NOT be cleared)
      'pick_up_status': pick_up_status.$,
      'carrier_base_shipping': carrier_base_shipping.$,
      'google_recaptcha': google_recaptcha.$,
      'wallet_system_status': wallet_system_status.$,
      'mail_verification_status': mail_verification_status.$,
      'conversation_system_status': conversation_system_status.$,
      'vendor_system': vendor_system.$,
      'classified_product_status': classified_product_status.$,
    };
  }

  // ============ SHOW DEBUG LOGOUT DIALOG ============
  void _showDebugLogoutDialog(BuildContext context, Map<String, dynamic> steps) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.orange),
            const SizedBox(width: 10),
            const Text(
              'Logout Debug Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status summary
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: steps['success'] ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: steps['success'] ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        steps['success'] ? Icons.check_circle : Icons.error,
                        color: steps['success'] ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          steps['message'] ?? 'Logout completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: steps['success'] ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Steps
                const Text(
                  'Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...steps['steps'].map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        step['success'] ? Icons.check_circle : Icons.error,
                        size: 14,
                        color: step['success'] ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step['message'],
                          style: TextStyle(
                            color: step['success'] ? Colors.black : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                // Final values
                const Text(
                  'Final Shared Values:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(steps['finalValues']),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final debugReport = '''
=== LOGOUT DEBUG REPORT ===
Message: ${steps['message']}
Success: ${steps['success']}

=== STEPS ===
${steps['steps'].map((s) => '[${s['success'] ? '✓' : '✗'}] ${s['message']}').join('\n')}

=== FINAL SHARED VALUES ===
${const JsonEncoder.withIndent('  ').convert(steps['finalValues'])}
''';
              Clipboard.setData(ClipboardData(text: debugReport));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debug report copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============ LOGOUT - WITH FULL DEBUG ============
  void _onTapLogout(BuildContext context) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.logout_ucf,
          style: TextStyle(fontSize: 15, color: MyTheme.dark_font_grey),
        ),
        content: Text(
          AppLocalizations.of(context)!.are_you_sure_you_want_to_sign_out,
          style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no_ucf),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes_ucf),
          )
        ],
      ),
    );
    
    if (confirm == true) {
      // Initialize debug steps
      List<Map<String, dynamic>> steps = [];
      bool allSuccess = true;
      
      // STEP 1: Start logout process
      steps.add({
        'success': true,
        'message': 'Step 1: Logout process started',
      });
      
      try {
        // STEP 2: Clear user data
        steps.add({
          'success': true,
          'message': 'Step 2: Calling AuthHelper.clearUserData()...',
        });
        
        await AuthHelper().clearUserData();
        
        steps.add({
          'success': true,
          'message': 'Step 2: AuthHelper.clearUserData() completed successfully',
        });
        
        // In _onTapLogout method, after clearing:
        // STEP 3: Get all shared values after clearing
        steps.add({
          'success': true,
          'message': 'Step 3: Checking shared values after clearing...',
        });

        final afterClearValues = _getAllSharedValues();

        // Check each critical value
        List<Map<String, dynamic>> checkResults = [
          {'key': 'is_logged_in', 'expected': false, 'actual': afterClearValues['is_logged_in']},
          {'key': 'access_token', 'expected': '', 'actual': afterClearValues['access_token']},
          {'key': 'user_id', 'expected': 0, 'actual': afterClearValues['user_id']},
          {'key': 'user_name', 'expected': '', 'actual': afterClearValues['user_name']},
          {'key': 'user_email', 'expected': '', 'actual': afterClearValues['user_email']},
          {'key': 'user_phone', 'expected': '', 'actual': afterClearValues['user_phone']},
          {'key': 'avatar_original', 'expected': '', 'actual': afterClearValues['avatar_original']},
          {'key': 'points_balance', 'expected': '0', 'actual': afterClearValues['points_balance']},
          {'key': 'affiliate_balance', 'expected': '0', 'actual': afterClearValues['affiliate_balance']},
          {'key': 'wishlist_count', 'expected': 0, 'actual': afterClearValues['wishlist_count']},
          {'key': 'auction_bids_count', 'expected': 0, 'actual': afterClearValues['auction_bids_count']},
        ];

        bool allCleared = true;
        for (var check in checkResults) {
          bool isCleared;
          if (check['expected'] == '') {
            isCleared = check['actual'] == '' || check['actual'] == null;
          } else {
            isCleared = check['actual'] == check['expected'];
          }
          
          steps.add({
            'success': isCleared,
            'message': '  ${check['key']}: ${check['actual']} ${isCleared ? '✓' : '✗'} (expected: ${check['expected']})',
          });
          
          if (!isCleared) allCleared = false;
        }

        // Check app settings that should NOT be cleared
        steps.add({
          'success': true,
          'message': 'Step 3: App settings (should NOT be cleared):',
        });
        steps.add({
          'success': true,
          'message': '  app_language: ${afterClearValues['app_language']}',
        });
        steps.add({
          'success': true,
          'message': '  wallet_system_status: ${afterClearValues['wallet_system_status']}',
        });
        steps.add({
          'success': true,
          'message': '  conversation_system_status: ${afterClearValues['conversation_system_status']}',
        });
        
        // STEP 4: Reset local state
        steps.add({
          'success': true,
          'message': 'Step 4: Resetting local state...',
        });
        
        _resetState();
        
        steps.add({
          'success': true,
          'message': 'Step 4: Local state reset completed',
        });
        
        // STEP 5: Show success toast
        steps.add({
          'success': true,
          'message': 'Step 5: Showing success toast...',
        });
        
        ToastComponent.showDialog(
          "Logged out successfully",
          gravity: ToastGravity.CENTER,
          duration: Toast.LENGTH_SHORT,
        );
        
        steps.add({
          'success': true,
          'message': 'Step 5: Success toast displayed',
        });
        
        // STEP 6: Navigate to login screen
        steps.add({
          'success': true,
          'message': 'Step 6: Navigating to login screen...',
        });
        
        // Final values after all operations
        final finalValues = _getAllSharedValues();
        
        // Build final debug report
        final debugData = {
          'success': allSuccess,
          'message': allSuccess ? 'Logout completed successfully ✓' : 'Logout completed with issues ✗',
          'steps': steps,
          'finalValues': finalValues,
        };
        
        // Show debug dialog
        if (mounted) {
          _showDebugLogoutDialog(context, debugData);
        }
        
        // Navigate to login screen
        if (mounted) {
          context.go("/users/login");
        }
        
      } catch (e, stackTrace) {
        steps.add({
          'success': false,
          'message': 'ERROR: ${e.toString()}',
        });
        
        steps.add({
          'success': false,
          'message': 'Stack trace: ${stackTrace.toString().substring(0, 200)}...',
        });
        
        final debugData = {
          'success': false,
          'message': 'Logout failed with error: ${e.toString()}',
          'steps': steps,
          'finalValues': _getAllSharedValues(),
        };
        
        if (mounted) {
          _showDebugLogoutDialog(context, debugData);
        }
      }
    }
  }

  void _showLoginWarning() {
    ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
      gravity: ToastGravity.CENTER,
      duration: Toast.LENGTH_LONG,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile_ucf,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              context.go("/");
            }
          },
        ),
        actions: [
          // Logout button - always show when logged in
          if (is_logged_in.$)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                onPressed: () => _onTapLogout(context),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  context.push("/users/login");
                },
                child: Text(
                  AppLocalizations.of(context)!.login_ucf,
                  style: const TextStyle(
                    color: MyTheme.accent_color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : _buildBody(),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      ShimmerHelper().buildBasicShimmer(height: 45, width: 45, radius: 45),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerHelper().buildBasicShimmer(height: 16, width: 120),
                            const SizedBox(height: 8),
                            ShimmerHelper().buildBasicShimmer(height: 12, width: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ShimmerHelper().buildBasicShimmer(height: 50, width: 80, radius: 20),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(6, (index) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerHelper().buildBasicShimmer(height: 60, radius: 16),
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          _buildProfileCard(),
          _buildMenuSection(),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _userInfo?.avatar != null && _userInfo!.avatar!.isNotEmpty
                        ? Image.network(
                            _userInfo!.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userInfo?.name?.isNotEmpty == true ? _userInfo!.name! : AppLocalizations.of(context)!.guest_user,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.referral_earnings} ${FormatHelper.formatPrice(_userInfo?.affiliateBalance ?? 0.0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.referral_point,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: _togglePointsVisibility,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _pointsVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _pointsVisible 
                          ? (_userInfo?.balance?.toInt() ?? 0).toString() 
                          : '****',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.points_ucf,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(AppLocalizations.of(context)!.my_account),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.favorite_border,
                  label: AppLocalizations.of(context)!.all_favorite,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Wishlist()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                const Divider(height: 0, color: Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.payment,
                  label: AppLocalizations.of(context)!.payment_settings,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsPage()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                const Divider(height: 0, color: Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.history,
                  label: AppLocalizations.of(context)!.invite_history,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteHistoryPage()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionHeading(AppLocalizations.of(context)!.security),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  label: AppLocalizations.of(context)!.update_profile,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEdit()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                const Divider(height: 0, color: Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  label: AppLocalizations.of(context)!.notification_ucf,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                const Divider(height: 0, color: Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.language,
                  label: AppLocalizations.of(context)!.language_ucf,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeLanguage()));
                  },
                ),
                const Divider(height: 0, color: Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  label: AppLocalizations.of(context)!.terms_conditions,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsPage()));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000417),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF000417),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isActive ? MyTheme.accent_color : const Color(0xFF334155),
                ),
              ),
            ),
            const Text(
              '›',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}