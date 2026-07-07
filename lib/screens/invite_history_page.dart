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
  bool _isLoadingMore = false;
  
  // ============ PAGINATION STATE ============
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;
  bool _hasMore = true;
  
  UserInformation? _userInfo;  // Store user info for referral data
  
  // ============ CACHED LISTS ============
  List<AffiliateLog> _allInviteHistory = [];
  
  // Referral data derived from _userInfo
  int get _totalReferrals => _userInfo?.affiliateLogs?.where((log) => log.bonusType == 'referral').length ?? 0;
  int get _totalPoints => (_userInfo?.balance ?? 0).toInt();
  double get _totalEarnings => _userInfo?.affiliateBalance ?? 0.0;
  String get _referralCode => _userInfo?.referralCode ?? "";
  
  String get _referralLink => "${AppConfig.RAW_BASE_URL}/registration?referral_code=$_referralCode";
  
  // Display list (paginated)
  List<AffiliateLog> get _displayHistory => _allInviteHistory;
  
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
  
  // ============ FETCH REFERRAL DATA FROM API WITH PAGINATION ============
  Future<void> _fetchReferralData({bool loadMore = false}) async {
    try {
      if (loadMore) {
        if (_isLoadingMore || !_hasMore) return;
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _currentPage = 1;
          _hasMore = true;
          _allInviteHistory.clear();
        });
      }

      final page = loadMore ? _currentPage + 1 : 1;

      var response = await ProfileRepository().getUserInfoResponse(
        notificationPage: 1,
        notificationPerPage: 10,
        pointPage: page,
        pointPerPage: _perPage,
        cashPage: 1,
        cashPerPage: 10,
        withdrawPage: 1,
        withdrawPerPage: 10,
      );
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final newUserInfo = response.data![0];
        
        // Update pagination info from points_pagination
        final pagination = newUserInfo.pointsPagination;
        if (pagination != null) {
          _currentPage = pagination.currentPage;
          _totalPages = pagination.totalPages;
          _totalItems = pagination.total;
          _perPage = pagination.perPage;
          _hasMore = pagination.hasNext;
        }
        
        setState(() {
          if (loadMore) {
            // Append new items to existing list
            final newLogs = newUserInfo.affiliateLogs ?? [];
            _allInviteHistory.addAll(newLogs);
          } else {
            // First page - replace all data
            _userInfo = newUserInfo;
            _allInviteHistory = newUserInfo.affiliateLogs?.where((log) => 
              log.bonusType == 'referral' && log.cameFrom != null
            ).toList() ?? [];
          }
        });
      } else {
        if (!loadMore) {
          setState(() {
            _allInviteHistory = [];
          });
        }
      }
    } catch (e) {
      print("Error loading referral data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_referral_data);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
      });
    }
  }
  
  // ============ LOAD MORE (INFINITE SCROLL) ============
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await _fetchReferralData(loadMore: true);
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchReferralData(loadMore: false);
  }
  
  void _copyToClipboard() {
    if (_referralCode.isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.referral_code_not_available);
      return;
    }
    
    Clipboard.setData(ClipboardData(text: _referralLink));
    ToastComponent.showSuccess(AppLocalizations.of(context)!.copied_to_clipboard);
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
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // Detect when user scrolls to bottom
                  if (!_isLoadingMore &&
                      _hasMore &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                    _loadMore();
                  }
                  return true;
                },
                child: SingleChildScrollView(
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
    final history = _displayHistory;
    
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length + (_hasMore ? 1 : 0),
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: const Color(0xFFEEF2F8),
              ),
              itemBuilder: (context, index) {
                // Show loading indicator at the end if there are more items
                if (index == history.length && _hasMore) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: SizedBox(
                        height: 24.w,
                        width: 24.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ),
                  );
                }
                final item = history[index];
                return _buildHistoryItem(item, index);
              },
            ),
          ),
        
        // Show "End of list" message when no more items
        if (!_hasMore && history.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Text(
              AppLocalizations.of(context)!.no_more_notifications,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF999999),
              ),
            ),
          ),
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
}