import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/withdrawal_page.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
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
import 'package:go_router/go_router.dart';

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
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_affiliate_data);
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
  String get _referralLink => "${AppConfig.RAW_BASE_URL}/ref/$_referralCode";
  
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ToastComponent.showDialog(AppLocalizations.of(context)!.copied_to_clipboard);
  }
  
  void _shareReferralLink() async {
    if (_referralCode.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.referral_code_not_available);
      return;
    }
    
    final String shareText = '${AppLocalizations.of(context)!.join_me_on_bidpoint} ${AppLocalizations.of(context)!.use_my_referral_code}: $_referralCode\n\n$_referralLink';
    
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
              // Go to home if can't pop
              context.go("/");
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 87, radius: 20),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120, radius: 14)),
              const SizedBox(width: 15),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120, radius: 14)),
            ],
          ),
          const SizedBox(height: 20),
          ShimmerHelper().buildBasicShimmer(height: 150, radius: 16),
          const SizedBox(height: 20),
          ShimmerHelper().buildBasicShimmer(height: 200, radius: 16),
          const SizedBox(height: 20),
          ShimmerHelper().buildBasicShimmer(height: 80, radius: 16),
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 50, radius: 8),
          const SizedBox(height: 30),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildBanner(),
              const SizedBox(height: 20),
              _buildHowItWorks(),
              const SizedBox(height: 20),
              _buildReferralLink(),
              const SizedBox(height: 16),
              _buildShareButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
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
                                size: 30,
                                color: Color(0xFF94A3B8),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : AppLocalizations.of(context)!.user_ucf,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _navigateToWithdrawHistory,
                        child: Text(
                          '${AppLocalizations.of(context)!.referral_earnings} ${FormatHelper.formatPrice(_referralEarnings)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                AppLocalizations.of(context)!.withdraw_ucf,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.points_balance,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: _togglePointsVisibility,
                        child: Icon(
                          _pointsVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _pointsVisible ? '$_pointsBalance' : '****',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.points_ucf,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.view_ucf,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
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
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: _navigateToCash,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.cash_earnings,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    FormatHelper.formatPrice(_cashEarnings),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.view_ucf,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/Banner_Image.png',
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: const Color(0xFFE2E8F0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: MyTheme.accent_color.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.referral_banner,
                      style: TextStyle(
                        fontSize: 14,
                        color: MyTheme.font_grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.bring_friend_save_money,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E8E8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step['number']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['desc']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
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
          AppLocalizations.of(context)!.referral_link,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Text(
                    displayLink,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_referralCode.isNotEmpty)
                GestureDetector(
                  onTap: () => _copyToClipboard(_referralLink, AppLocalizations.of(context)!.link_ucf),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.copy_ucf,
                      style: const TextStyle(
                        fontSize: 12,
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _referralCode.isNotEmpty ? MyTheme.accent_color : const Color(0xFFCCCCCC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.share,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.share_invite_link,
              style: const TextStyle(
                fontSize: 14,
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