import 'dart:async';
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
import 'package:active_ecommerce_flutter/screens/auction_products.dart';
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
import 'auction_bidded_products.dart';
import 'auction_purchase_history.dart';
import 'coming_soon_page.dart';
import 'invite_history_page.dart';
import 'payment_settings_page.dart';
import 'terms_conditions_page.dart';

class Profile extends StatefulWidget {
  Profile({Key? key, this.show_back_button = false}) : super(key: key);

  bool show_back_button;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _mainScrollController = ScrollController();
  bool _pointsVisible = true;
  
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;           // Loading state
  bool _isRefreshing = false;       // Pull-to-refresh state
  UserInformation? _userInfo;       // Store the API response locally
  
  // ============ INIT ============
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();  // Fetch fresh data from API
    } else {
      _loadFromSharedPreferences();  // Fallback for non-logged in
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

  // ============ FETCH DATA FROM API (Like ProductDetails) ============
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally like _productDetails
        });
        
        // Optional: Update SharedValues for global use (like cart counter in ProductDetails)
        // Only update global state that OTHER screens need
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
  
  // Fallback for non-logged in users
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
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  // ============ RESET STATE (Like ProductDetails) ============
  void _resetState() {
    setState(() {
      _userInfo = null;
      _isLoading = true;
    });
  }

  // ============ NAVIGATION HELPERS ============
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go("/");
    }
  }

  void _togglePointsVisibility() {
    setState(() {
      _pointsVisible = !_pointsVisible;
    });
  }

  void _onTapLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.logout_ucf,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.are_you_sure_you_want_to_sign_out,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.yes_ucf),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      AuthHelper().clearUserData();
      _resetState();
      context.go("/");
    }
  }

  void _showLoginWarning() {
    ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
      gravity: ToastGravity.CENTER,
      duration: Toast.LENGTH_LONG,
    );
  }

  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
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
          onPressed: _navigateBack,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              onPressed: is_logged_in.$ ? _onTapLogout : () => context.push("/users/login"),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()  // Show shimmer while loading (like ProductDetails)
            : _buildBody(),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE (Like ProductDetails) ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          // Profile card shimmer
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
          // Menu section shimmer
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
  
  // ============ MAIN BODY (Shows real data when loaded) ============
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          _buildProfileCard(),
          _buildMenuSection(),
        ],
      ),
    );
  }
  
  // ============ PROFILE CARD (Using local _userInfo) ============
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
                        _userInfo?.name?.isNotEmpty == true ? _userInfo!.name! : "Guest User",
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
  
  // ============ MENU SECTION ============
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