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
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../repositories/auth_repository.dart';
import '../data_model/user_info_response.dart';
import 'auction_purchase_history.dart';
import 'coming_soon_page.dart';
import 'invite_history_page.dart';
import 'payment_settings_page.dart';
import 'terms_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'faq_page.dart';
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
  // ============ REFERRAL DIALOG STATE ============
  bool _showReferralDialog = false;
  bool _isSubmittingReferral = false;
  final TextEditingController _referralCodeController = TextEditingController();

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
    _referralCodeController.dispose();
    super.dispose();
  }

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
          
          // ✅ Check and show referral dialog after data is loaded
          _checkAndShowReferralDialog();
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

  void _togglePointsVisibility() {
    setState(() {
      _pointsVisible = !_pointsVisible;
    });
  }

  // ============ REFERRAL DIALOG LOGIC ============
  void _checkAndShowReferralDialog() {
    if (_userInfo == null) return;
    
    // Check conditions: referred_by is NULL/empty and has_upline is "0"
    final hasUpline = _userInfo!.hasUpline ?? "0";
    final referredBy = _userInfo!.referredBy;
    
    final shouldShowDialog = 
        (referredBy == null || referredBy.isEmpty || referredBy == "null") && 
        hasUpline == "0";
    
    if (shouldShowDialog && !_showReferralDialog && mounted) {
      _showReferralDialog = true;
      // Use addPostFrameCallback to show dialog after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showReferralOfferDialog();
        }
      });
    }
  }

  void _showReferralOfferDialog() {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => false, // Prevent back button dismissal
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient decoration
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MyTheme.accent_color,
                              MyTheme.accent_color.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 40.sp,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              localizations?.referral_offer_title ?? '🎉 Get Free Points!',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              localizations?.referral_offer_subtitle ?? 'Enter a referral code to earn free points',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Info text
                      Text(
                        localizations?.referral_offer_description ?? 
                        'Get 100 bonus points when you enter a valid referral code!',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Input field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
                        ),
                        child: TextField(
                          controller: _referralCodeController,
                          enabled: !_isSubmittingReferral,
                          decoration: InputDecoration(
                            hintText: localizations?.enter_referral_code ?? 'Enter referral code',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              Icons.code,
                              size: 20.sp,
                              color: MyTheme.accent_color,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            suffixIcon: _referralCodeController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18.sp,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () {
                                      _referralCodeController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Two buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogButton(
                              label: localizations?.i_dont_have_referral ?? "I don't have a referral",
                              onPressed: _isSubmittingReferral ? null : () => _submitReferralCode(null),
                              isPrimary: false,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildDialogButton(
                              label: localizations?.submit_ucf ?? "Submit",
                              onPressed: _isSubmittingReferral 
                                  ? null 
                                  : () {
                                      final code = _referralCodeController.text.trim();
                                      if (code.isEmpty) {
                                        ToastComponent.showWarning(
                                          localizations?.please_enter_referral_code ?? 'Please enter a referral code',
                                        );
                                        return;
                                      }
                                      _submitReferralCode(code);
                                    },
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                      
                      if (_isSubmittingReferral) ...[
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? MyTheme.accent_color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : MyTheme.accent_color,
          elevation: isPrimary ? 2 : 1,
          shadowColor: isPrimary ? MyTheme.accent_color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: isPrimary ? MyTheme.accent_color : const Color(0xFFE2E8F0),
              width: 1.w,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _submitReferralCode(String? referralCode) async {
    final localizations = AppLocalizations.of(context);
    
    if (_userInfo == null || _userInfo!.id == null) {
      ToastComponent.showError(localizations?.user_not_found_ucf ?? AppLocalizations.of(context)!.user_not_found);
      return;
    }

    // Show loading on the buttons
    setState(() {
      _isSubmittingReferral = true;
    });

    try {
      final response = await ProfileRepository().submitReferralCode(
        userId: _userInfo!.id!,
        referralCode: referralCode,
      );

      // Close dialog first
      if (mounted) {
        Navigator.of(context).pop();
        _showReferralDialog = false;
      }

      if (response['success'] == true) {
        // Show success message
        ToastComponent.showSuccess(
          response['message'] ?? 
          (referralCode != null 
            ? localizations?.referral_code_applied_successfully ?? AppLocalizations.of(context)!.referral_code_applied_successfully
            : localizations?.referral_skipped_successfully ?? AppLocalizations.of(context)!.referral_skipped_successfully)
        );
        
        // Refresh user data to update referral status and points
        await _fetchUserData();
        
        // Force UI refresh after data is loaded
        if (mounted) {
          setState(() {
            _isSubmittingReferral = false;
          });
        }
      } else {
        // Reset loading state on error
        if (mounted) {
          setState(() {
            _isSubmittingReferral = false;
          });
        }
        ToastComponent.showError(
          response['message'] ?? localizations?.failed_to_apply_referral ?? AppLocalizations.of(context)!.failed_to_apply_referral
        );
      }
    } catch (e) {
      print("Error submitting referral: $e");
      // Reset loading state on error
      if (mounted) {
        setState(() {
          _isSubmittingReferral = false;
        });
      }
      ToastComponent.showError(
        localizations?.failed_to_apply_referral ?? AppLocalizations.of(context)!.failed_to_apply_referral
      );
    }
  }
    
  // ============ LOGOUT ============
  void _onTapLogout(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          localizations?.logout_ucf ?? AppLocalizations.of(context)!.logout_ucf,
          style: TextStyle(fontSize: 15.sp, color: MyTheme.dark_font_grey),
        ),
        content: Text(
          localizations?.are_you_sure_you_want_to_sign_out ?? AppLocalizations.of(context)!.are_you_sure_you_want_to_sign_out,
          style: TextStyle(fontSize: 13.sp, color: MyTheme.dark_font_grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations?.no_ucf ?? AppLocalizations.of(context)!.no_ucf,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations?.yes_ucf ?? AppLocalizations.of(context)!.yes_ucf,
              style: TextStyle(fontSize: 14.sp),
            ),
          )
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await AuthHelper().clearUserData();
        _resetState();
        ToastComponent.showSuccess(localizations?.logged_out_successfully ?? AppLocalizations.of(context)!.logged_out_successfully);
        if (mounted) {
          context.go("/users/login");
        }
      } catch (e) {
        ToastComponent.showError('${localizations?.logout_failed ?? AppLocalizations.of(context)!.logout_failed}: ${e.toString()}');
      }
    }
  }

  void _showLoginWarning() {
    final localizations = AppLocalizations.of(context);
    ToastComponent.showWarning(
      localizations?.you_need_to_log_in ?? AppLocalizations.of(context)!.you_need_to_log_in,
      gravity: ToastGravity.CENTER,
      duration: Toast.LENGTH_LONG,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Divider(height: 1.h, thickness: 1.w),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          localizations?.profile_ucf ?? AppLocalizations.of(context)!.profile_ucf,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Main(initialIndex: 0),
              ),
            );
          },
        ),
        actions: [
          if (is_logged_in.$)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(Icons.logout, size: 24.sp, color: const Color(0xFFDC2626)),
                onPressed: () => _onTapLogout(context),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: TextButton(
                onPressed: () {
                  context.push("/users/login");
                },
                child: Text(
                  localizations?.login_ucf ?? AppLocalizations.of(context)!.login_ucf,
                  style: TextStyle(
                    fontSize: 14.sp,
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
            : isLargeScreen 
                ? _buildDesktopTabletBody() 
                : _buildBody(),
      ),
    );
  }

  // ============ SHIMMER LOADING ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(13.w, 13.h, 13.w, 27.h),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      ShimmerHelper().buildBasicShimmer(height: 45.w, width: 45.w, radius: 45.r),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerHelper().buildBasicShimmer(height: 16.h, width: 120.w),
                            SizedBox(height: 8.h),
                            ShimmerHelper().buildBasicShimmer(height: 12.h, width: 100.w),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ShimmerHelper().buildBasicShimmer(height: 50.h, width: 80.w, radius: 20.r),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: List.generate(6, (index) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: ShimmerHelper().buildBasicShimmer(height: 60.h, radius: 16.r),
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============ MOBILE BODY ============
  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(13.w, 13.h, 13.w, 27.h),
      child: Column(
        children: [
          _buildProfileCard(),
          _buildMenuSection(),
        ],
      ),
    );
  }
  
  // ============ TABLET/DESKTOP BODY ============
  Widget _buildDesktopTabletBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 27.h),
      child: Column(
        children: [
          SizedBox(
            width: 800.w,
            child: Column(
              children: [
                _buildProfileCard(),
                _buildMenuSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ============ PROFILE CARD ============
  Widget _buildProfileCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: isSmallScreen 
          ? _buildProfileCardSmall() 
          : _buildProfileCardRegular(),
    );
  }

  Widget _buildProfileCardSmall() {
    final localizations = AppLocalizations.of(context);
    
    return Column(
      children: [
        // Avatar and name in a row
        Row(
          children: [
            Container(
              width: 45.w,
              height: 45.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3.w,
                ),
              ),
              child: ClipOval(
                child: _userInfo?.avatar != null && _userInfo!.avatar!.isNotEmpty
                    ? Image.network(
                        _userInfo!.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 40.sp,
                            color: const Color(0xFF94A3B8),
                          );
                        },
                      )
                    : Icon(
                        Icons.person,
                        size: 40.sp,
                        color: const Color(0xFF94A3B8),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userInfo?.name?.isNotEmpty == true 
                        ? _userInfo!.name! 
                        : (localizations?.guest_user_ucf ?? 'Guest User'),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${localizations?.referral_earnings_ucf ?? 'Referral Earnings'} ${FormatHelper.formatPrice(_userInfo?.affiliateBalance ?? 0.0)}',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: MyTheme.accent_color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Points section full width
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    localizations?.referral_point_ucf ?? 'Referral Points',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(width: 7.w),
                  GestureDetector(
                    onTap: _togglePointsVisibility,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _pointsVisible ? Icons.visibility : Icons.visibility_off,
                        size: 13.sp,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _pointsVisible 
                        ? FormatHelper.formatPoints(_userInfo?.balance) 
                        : '****',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    localizations?.points_ucf ?? 'Points',
                    style: TextStyle(
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCardRegular() {
    final localizations = AppLocalizations.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3.w,
                  ),
                ),
                child: ClipOval(
                  child: _userInfo?.avatar != null && _userInfo!.avatar!.isNotEmpty
                      ? Image.network(
                          _userInfo!.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 40.sp,
                              color: const Color(0xFF94A3B8),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 40.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userInfo?.name?.isNotEmpty == true 
                          ? _userInfo!.name! 
                          : (localizations?.guest_user_ucf ?? 'Guest User'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${localizations?.referral_earnings_ucf ?? 'Referral Earnings'} ${FormatHelper.formatPrice(_userInfo?.affiliateBalance ?? 0.0)}',
                      style: TextStyle(
                        fontSize: 10.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    localizations?.referral_point_ucf ?? 'Referral Points',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(width: 7.w),
                  GestureDetector(
                    onTap: _togglePointsVisibility,
                    child: Container(
                      width: 27.w,
                      height: 27.w,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _pointsVisible ? Icons.visibility : Icons.visibility_off,
                        size: 16.sp,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _pointsVisible 
                        ? (_userInfo?.balance?.toInt() ?? 0).toString() 
                        : '****',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    localizations?.points_ucf ?? 'Points',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============ MENU SECTION ============
  Widget _buildMenuSection() {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    // For tablet/desktop, show menus in a grid
    if (isTablet || isDesktop) {
      return _buildDesktopMenuSection();
    }
    
    // Mobile menu
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(localizations?.my_account_ucf ?? 'My Account'),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  label: localizations?.update_profile_ucf ?? 'Update Profile',
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEdit()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.payment,
                  label: localizations?.payment_settings_ucf ?? 'Payment Settings',
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsPage()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.history,
                  label: localizations?.invite_history_ucf ?? 'Invite History',
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
          
          SizedBox(height: 16.h),
          
          _buildSectionHeading(localizations?.security_ucf ?? 'Security'),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  label: localizations?.notification_ucf ?? 'Notification',
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
                    } else {
                      _showLoginWarning();
                    }
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.language,
                  label: localizations?.language_ucf ?? 'Language',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeLanguage()));
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  label: localizations?.terms_conditions_ucf ?? 'Terms & Conditions',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsPage()));
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  label: localizations?.privacy_policy_ucf ?? 'Privacy Policy',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                  },
                ),
                Divider(height: 0, color: const Color(0xFFEEF2F8)),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  label: localizations?.faq_ucf ?? 'FAQ',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqPage()));
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // ============ DESKTOP MENU ============
  Widget _buildDesktopMenuSection() {
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Account Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeading(localizations?.my_account_ucf ?? 'My Account'),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.favorite_border,
                        label: localizations?.all_favorite_ucf ?? 'All Favorites',
                        onTap: () {
                          if (is_logged_in.$) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Wishlist()));
                          } else {
                            _showLoginWarning();
                          }
                        },
                      ),
                      Divider(height: 0, color: const Color(0xFFEEF2F8)),
                      _buildMenuItem(
                        icon: Icons.payment,
                        label: localizations?.payment_settings_ucf ?? 'Payment Settings',
                        onTap: () {
                          if (is_logged_in.$) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsPage()));
                          } else {
                            _showLoginWarning();
                          }
                        },
                      ),
                      Divider(height: 0, color: const Color(0xFFEEF2F8)),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: localizations?.invite_history_ucf ?? 'Invite History',
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
              ],
            ),
          ),
          SizedBox(width: 16.w),
          // Security Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeading(localizations?.security_ucf ?? 'Security'),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        label: localizations?.update_profile_ucf ?? 'Update Profile',
                        onTap: () {
                          if (is_logged_in.$) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEdit()));
                          } else {
                            _showLoginWarning();
                          }
                        },
                      ),
                      Divider(height: 0, color: const Color(0xFFEEF2F8)),
                      _buildMenuItem(
                        icon: Icons.notifications_none,
                        label: localizations?.notification_ucf ?? 'Notification',
                        onTap: () {
                          if (is_logged_in.$) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
                          } else {
                            _showLoginWarning();
                          }
                        },
                      ),
                      Divider(height: 0, color: const Color(0xFFEEF2F8)),
                      _buildMenuItem(
                        icon: Icons.language,
                        label: localizations?.language_ucf ?? 'Language',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeLanguage()));
                        },
                      ),
                      Divider(height: 0, color: const Color(0xFFEEF2F8)),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        label: localizations?.terms_conditions_ucf ?? 'Terms & Conditions',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsPage()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ============ SECTION HEADING ============
  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF000417),
        ),
      ),
    );
  }
  
  // ============ MENU ITEM ============
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isDesktop ? 14.h : 11.h, horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 40.w : 34.w,
              height: isDesktop ? 40.w : 34.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isDesktop ? 20.sp : 18.sp,
                color: const Color(0xFF000417),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 16.sp : 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isActive ? MyTheme.accent_color : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                fontSize: isDesktop ? 28.sp : 20.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}