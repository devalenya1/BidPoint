import 'dart:async';
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../repositories/auth_repository.dart';
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
  int _userBalance = 1250;
  String _userName = "John Doe";
  String _userEmail = "john.doe@example.com";
  String _userPhone = "+1234567890";
  String _userAvatar = "";
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    setState(() {
      _userName = user_name.$ ?? "John Doe";
      _userEmail = user_email.$ ?? "";
      _userPhone = user_phone.$ ?? "";
      _userAvatar = avatar_original.$ ?? "";
      _userBalance = 1250;
    });
  }

  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

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
      context.go("/");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header
          _buildTopHeader(),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Card
                  _buildProfileCard(),
                  
                  // Menu Section
                  _buildMenuSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEEF2F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel/Back Button
          GestureDetector(
            onTap: _navigateBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          // Title
          Text(
            AppLocalizations.of(context)!.profile_ucf,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          // Logout Button
          GestureDetector(
            onTap: is_logged_in.$ ? _onTapLogout : () => context.push("/users/login"),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                size: 20,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Avatar and User Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _userAvatar.isNotEmpty
                        ? Image.network(
                            _userAvatar,
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
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.referral_earnings} \$${_userBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
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
          // Right side - Points Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _togglePointsVisibility,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _pointsVisible ? Icons.visibility : Icons.visibility_off,
                          size: 18,
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
                      _pointsVisible ? '$_userBalance' : '****',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.points_ucf,
                      style: const TextStyle(
                        fontSize: 14,
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
          // My Account Section
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
          
          // Security Section
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ComingSoonPage(title: 'Notification')));
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
  
  void _showLoginWarning() {
    ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
      gravity: ToastGravity.CENTER,
      duration: Toast.LENGTH_LONG,
    );
  }
}