import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class InviteHistoryPage extends StatefulWidget {
  const InviteHistoryPage({Key? key}) : super(key: key);

  @override
  State<InviteHistoryPage> createState() => _InviteHistoryPageState();
}

class _InviteHistoryPageState extends State<InviteHistoryPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  UserInformation? _userInfo;  // Store user info for referral data
  
  // Referral data derived from _userInfo
  int get _totalReferrals => _userInfo?.affiliateLogs?.where((log) => log.bonusType == 'referral').length ?? 0;
  int get _totalPoints => (_userInfo?.balance ?? 0).toInt();
  double get _totalEarnings => _userInfo?.affiliateBalance ?? 0.0;
  String get _referralCode => _userInfo?.referralCode ?? "";
  
  // FIXED: Use AppConfig.RAW_BASE_URL for referral link
  String get _referralLink => "${AppConfig.RAW_BASE_URL}/ref/$_referralCode";
  
  // Invite history from API
  List<AffiliateLog> get _inviteHistory => _userInfo?.affiliateLogs?.where((log) => 
    log.bonusType == 'referral' && log.cameFrom != null
  ).toList() ?? [];
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchReferralData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ============ FETCH REFERRAL DATA FROM API ============
  Future<void> _fetchReferralData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally
        });
      }
    } catch (e) {
      print("Error loading referral data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_referral_data);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchReferralData();
  }
  
  void _copyToClipboard() {
    if (_referralCode.isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.referral_code_not_available);
      return;
    }
    
    Clipboard.setData(ClipboardData(text: _referralLink));
    ToastComponent.showSuccess(AppLocalizations.of(context)!.copied_to_clipboard);
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _getReferralName(AffiliateLog log) {
    if (log.cameFrom != null && log.cameFrom!.isNotEmpty) {
      return log.cameFrom!;
    }
    return AppLocalizations.of(context)!.referred_user;
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.invite_history,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                child: Column(
                  children: [
                    _buildStatsRow(),
                    SizedBox(height: 24.h),
                    _buildReferralSection(),
                    SizedBox(height: 24.h),
                    _buildHistorySection(),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90.h, radius: 16.r)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90.h, radius: 16.r)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90.h, radius: 16.r)),
            ],
          ),
          SizedBox(height: 24.h),
          ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 12.r),
          SizedBox(height: 24.h),
          ShimmerHelper().buildBasicShimmer(height: 20.h, width: 150.w),
          SizedBox(height: 16.h),
          Column(
            children: List.generate(5, (index) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ShimmerHelper().buildBasicShimmer(height: 50.h, radius: 8.r),
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
        _buildStatCard(
          label: AppLocalizations.of(context)!.referrals_ucf,
          value: '$_totalReferrals',
        ),
        SizedBox(width: 12.w),
        _buildStatCard(
          label: AppLocalizations.of(context)!.points_ucf,
          value: '$_totalPoints',
          unit: 'pts',
        ),
        SizedBox(width: 12.w),
        _buildStatCard(
          label: AppLocalizations.of(context)!.earnings_ucf,
          value: FormatHelper.formatPrice(_totalEarnings),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String label,
    required String value,
    String? unit,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReferralSection() {
    final displayLink = _referralCode.isNotEmpty 
        ? _referralLink 
        : AppLocalizations.of(context)!.referral_code_not_available;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.your_referral_link,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Text(
                    displayLink,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: 'monospace',
                      color: const Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_referralCode.isNotEmpty)
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(11.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          AppLocalizations.of(context)!.copy_ucf,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistorySection() {
    final history = _inviteHistory;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFEEF2F8),
                width: 1.w,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  AppLocalizations.of(context)!.referral_name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  AppLocalizations.of(context)!.points_ucf,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  AppLocalizations.of(context)!.date_ucf,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (history.isEmpty)
          _buildEmptyState()
        else
          Container(
            constraints: BoxConstraints(maxHeight: 500.h),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: const Color(0xFFEEF2F8),
              ),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryItem(item, index);
              },
            ),
          ),
        
        if (history.length > 5)
          _buildPagination(),
      ],
    );
  }
  
  Widget _buildHistoryItem(AffiliateLog item, int index) {
    final pointsValue = (item.amount ?? 0).abs().toInt();
    final isEarned = (item.amount ?? 0) > 0;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getReferralName(item),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${isEarned ? '+' : ''}$pointsValue',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isEarned ? const Color(0xFF0092AC) : const Color(0xFFEF4444),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.createdAt != null ? _formatDate(item.createdAt!) : AppLocalizations.of(context)!.unknown,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            '📋',
            style: TextStyle(fontSize: 48.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)!.no_referral_history_yet,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.share_referral_link_to_start_earning,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPagination() {
    final history = _inviteHistory;
    final totalPages = (history.length / 10).ceil();
    
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages > 5 ? 5 : totalPages, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: index == 0 ? MyTheme.accent_color : Colors.white,
              border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                color: index == 0 ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          );
        }),
      ),
    );
  }
}