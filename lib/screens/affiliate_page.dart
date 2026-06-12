import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/withdrawal_page.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/screens/points_history_page.dart';
import 'package:active_ecommerce_flutter/screens/cash_earnings_page.dart';

class AffiliatePage extends StatefulWidget {
  const AffiliatePage({Key? key}) : super(key: key);

  @override
  State<AffiliatePage> createState() => _AffiliatePageState();
}

class _AffiliatePageState extends State<AffiliatePage> {
  // User data
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userAvatar = "";
  String _pointsBalance = "0";
  String _cashEarnings = "0";
  String _referralEarnings = "0";
  String _referralCode = "";
  String _referralLink = "";
  
  // UI state
  bool _pointsVisible = true;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _loadUserData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        
        setState(() {
          _userName = user.name ?? "";
          _userEmail = user.email ?? "";
          _userPhone = user.phone ?? "";
          _userAvatar = user.avatar ?? "";
          _pointsBalance = user.balance ?? "0";
          _cashEarnings = user.affiliateBalance?.toString() ?? "0";
          _referralEarnings = user.affiliateBalance?.toString() ?? "0";
          _referralCode = user.affiliateId ?? "";
          _referralLink = "https://bidpoint.com/ref/$_referralCode";
        });
        
        // Update shared_value_helper
        user_name.$ = _userName;
        user_email.$ = _userEmail;
        user_phone.$ = _userPhone;
        avatar_original.$ = _userAvatar;
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _copyToClipboard(String text, String type) {
    // Copy to clipboard logic here
    ToastComponent.showDialog(AppLocalizations.of(context)!.copied_to_clipboard);
  }
  
  void _shareReferralLink() async {
    if (_referralCode.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.referral_code_not_available);
      return;
    }
    
    final String shareText = AppLocalizations.of(context)!.share_referral_message(
      _referralLink,
      _referralCode,
    );
    
    await Share.share(
      shareText,
      subject: AppLocalizations.of(context)!.share_referral_subject,
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    // Stats Cards Row
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    // Banner Image
                    _buildBanner(),
                    const SizedBox(height: 20),
                    // How It Works Section
                    _buildHowItWorks(),
                    const SizedBox(height: 20),
                    // Referral Link Section
                    _buildReferralLink(),
                    const SizedBox(height: 16),
                    // Share Button
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
          // Left side - Avatar and User Info
          Expanded(
            child: Row(
              children: [
                // Avatar
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
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : 'User',
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
                          '${AppLocalizations.of(context)!.referral_earnings} \$$_referralEarnings',
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
          // Right side - Withdraw button
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
    // Parse cash earnings to double for display
    double cashValue = double.tryParse(_cashEarnings) ?? 0.0;
    
    return Row(
      children: [
        // Points Balance Card
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
        // Cash Earnings Card
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
                    '\$${cashValue.toStringAsFixed(2)}',
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
    // Build referral link only if code exists
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