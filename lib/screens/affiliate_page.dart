import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/screens/withdrawal_page.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/screens/points_history_page.dart';
import 'package:active_ecommerce_flutter/screens/cash_earnings_page.dart';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class AffiliatePage extends StatefulWidget {
  const AffiliatePage({Key? key}) : super(key: key);

  @override
  State<AffiliatePage> createState() => _AffiliatePageState();
}

class _AffiliatePageState extends State<AffiliatePage> {
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _pointsVisible = true;
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();  // Fetch fresh data from API
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
        
        // Optional: Update global SharedValues for affiliate data
        affiliate_balance.$ = _userInfo?.affiliateBalance?.toString() ?? "0";
        affiliate_balance.save();
        points_balance.$ = _userInfo?.balance?.toString() ?? "0";
        points_balance.save();
        
        // Save all user data to SharedPreferences for other screens
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_affiliate_data);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  // Helper getters for user data (derived from _userInfo)
  String get _userName => _userInfo?.name ?? "";
  String get _userEmail => _userInfo?.email ?? "";
  String get _userPhone => _userInfo?.phone ?? "";
  String get _userAvatar => _userInfo?.avatar ?? "";
  int get _pointsBalance => (_userInfo?.balance ?? 0).toInt();
  double get _cashEarnings => _userInfo?.affiliateBalance ?? 0.0;
  double get _referralEarnings => _userInfo?.affiliateBalance ?? 0.0;
  String get _referralCode => _userInfo?.referralCode ?? "";
  
  // UPDATED: Use AppConfig.RAW_BASE_URL for referral link
  // String get _referralLink => "${AppConfig.RAW_BASE_URL}/registration?referral_code=$_referralCode";
  String get _referralLink => "$_referralCode";
  
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ToastComponent.showSuccess(AppLocalizations.of(context)!.copied_to_clipboard);
  }
  
  void _shareReferralLink() async {
    if (_referralCode.isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.referral_code_not_available);
      return;
    }
    
    // final String shareText = '${AppLocalizations.of(context)!.join_me_on_bidpoint} ${AppLocalizations.of(context)!.use_my_referral_code}: $_referralCode\n\n$_referralLink';
    final String shareText = '${AppLocalizations.of(context)!.join_me_on_bidpoint} ${AppLocalizations.of(context)!.use_my_referral_code}: $_referralCode';
    
    await Share.share(
      shareText,
      subject: AppLocalizations.of(context)!.join_bidpoint,
    );
  }
  
  void _togglePointsVisibility() {
    setState(() {
      _pointsVisible = !_pointsVisible;
    });
  }
  
  void _navigateToWithdrawHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WithdrawalPage()),
    );
  }
  
  void _navigateToPoints() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PointsHistoryPage()),
    );
  }
  
  void _navigateToCash() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CashEarningsPage()),
    );
  }
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.referrals_ucf,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              // If nothing to pop, go to home and clear the stack
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
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
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          ShimmerHelper().buildBasicShimmer(height: 87.h, radius: 20.r),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120.h, radius: 14.r)),
              SizedBox(width: 15.w),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120.h, radius: 14.r)),
            ],
          ),
          SizedBox(height: 20.h),
          ShimmerHelper().buildBasicShimmer(height: 150.h, radius: 16.r),
          SizedBox(height: 20.h),
          ShimmerHelper().buildBasicShimmer(height: 200.h, radius: 16.r),
          SizedBox(height: 20.h),
          ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 16.r),
          SizedBox(height: 16.h),
          ShimmerHelper().buildBasicShimmer(height: 50.h, radius: 8.r),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
  
  // ============ MAIN BODY ============
  Widget _buildBody() {
    return RefreshIndicator(
      color: MyTheme.accent_color,
      backgroundColor: Colors.white,
      onRefresh: _onPageRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              _buildProfileCard(),
              SizedBox(height: 16.h),
              _buildStatsRow(),
              SizedBox(height: 20.h),
              _buildBanner(),
              SizedBox(height: 20.h),
              _buildHowItWorks(),
              SizedBox(height: 20.h),
              _buildReferralLink(),
              SizedBox(height: 16.h),
              _buildShareButton(),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 55.w,
                  height: 55.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2.w,
                    ),
                  ),
                  child: ClipOval(
                    child: _userAvatar.isNotEmpty
                        ? Image.network(
                            _userAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30.sp,
                                color: const Color(0xFF94A3B8),
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 30.sp,
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
                        _userName.isNotEmpty ? _userName : AppLocalizations.of(context)!.user_ucf,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      GestureDetector(
                        onTap: _navigateToWithdrawHistory,
                        child: Text(
                          '${AppLocalizations.of(context)!.referral_earnings} ${FormatHelper.formatPrice(_referralEarnings)}',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _navigateToWithdrawHistory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.withdraw_ucf,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToPoints,
            child: Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.points_balance,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: _togglePointsVisibility,
                        child: Icon(
                          _pointsVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _pointsVisible ? '$_pointsBalance' : '****',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        AppLocalizations.of(context)!.points_ucf,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.view_ucf,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: GestureDetector(
            onTap: _navigateToCash,
            child: Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.cash_earnings,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    FormatHelper.formatPrice(_cashEarnings),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.view_ucf,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBanner() {
    final double aspectRatio = 349 / 108;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.asset(
              'assets/Banner_Image.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHowItWorks() {
    final List<Map<String, String>> steps = [
      {
        'number': '1',
        'title': AppLocalizations.of(context)!.invite_friend,
        'desc': AppLocalizations.of(context)!.invite_friend_desc,
      },
      {
        'number': '2',
        'title': AppLocalizations.of(context)!.you_earn_more,
        'desc': AppLocalizations.of(context)!.you_earn_more_desc,
      },
      {
        'number': '3',
        'title': AppLocalizations.of(context)!.no_limits,
        'desc': AppLocalizations.of(context)!.no_limits_desc,
      },
    ];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.bring_friend_save_money,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 14.h),
          ...steps.map((step) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E8E8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step['number']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        step['desc']!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildReferralLink() {
    final displayLink = _referralCode.isNotEmpty 
        ? _referralLink 
        : AppLocalizations.of(context)!.referral_code_not_available;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.referral_code,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF666666),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.w),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                  child: Text(
                    displayLink,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_referralCode.isNotEmpty)
                GestureDetector(
                  onTap: () => _copyToClipboard(_referralLink, AppLocalizations.of(context)!.link_ucf),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(7.r),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.copy_ucf,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildShareButton() {
    return GestureDetector(
      onTap: _referralCode.isNotEmpty ? _shareReferralLink : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: _referralCode.isNotEmpty ? MyTheme.accent_color : const Color(0xFFCCCCCC),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share,
              size: 18.sp,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)!.share_invite_link,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}