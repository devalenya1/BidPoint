import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({Key? key}) : super(key: key);

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}
 
class _PointsHistoryPageState extends State<PointsHistoryPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'All';
  int _selectedMonthIndex = 0;
  
  // ============ PAGINATION STATE ============
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  // FIXED: Use PointHistory instead of AffiliateLog
  List<PointHistory> _allPointsLogs = [];
  List<PointHistory> _filteredPointsLogs = [];
  Map<String, int> _monthlyPoints = {};
  List<String> _months = [];
  
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
  
  // ============ FETCH DATA FROM API WITH PAGINATION ============
  Future<void> _fetchUserData({bool loadMore = false}) async {
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
          _allPointsLogs.clear();
          _filteredPointsLogs.clear();
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
            final newPoints = newUserInfo.pointHistory ?? [];
            _allPointsLogs.addAll(newPoints);
          } else {
            // First page - replace all data
            _userInfo = newUserInfo;
            _allPointsLogs = newUserInfo.pointHistory ?? [];
          }
        });
        
        _applyFilter();
        _calculateMonthlyPoints();
        
        points_balance.$ = _userInfo?.balance?.toString() ?? "0";
        points_balance.save();
        
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      } else {
        if (!loadMore) {
          setState(() {
            _allPointsLogs = [];
            _filteredPointsLogs = [];
            _monthlyPoints = {};
            _months = [];
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_points_history);
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
    await _fetchUserData(loadMore: true);
  }
  
  // ============ PROCESS POINTS HISTORY ============
  void _processPointsHistory() {
    if (_userInfo == null) return;
    
    // FIXED: Use pointHistory instead of affiliateLogs
    _allPointsLogs = _userInfo!.pointHistory ?? [];
    
    _applyFilter();
    _calculateMonthlyPoints();
  }
  
  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      switch (_selectedFilter) {
        case 'Today':
          _filteredPointsLogs = _allPointsLogs.where((log) {
            final logDate = log.createdAt;
            if (logDate == null) return false;
            return logDate.year == today.year && 
                   logDate.month == today.month && 
                   logDate.day == today.day;
          }).toList();
          break;
        case '7':
          final sevenDaysAgo = today.subtract(const Duration(days: 7));
          _filteredPointsLogs = _allPointsLogs.where((log) {
            final logDate = log.createdAt;
            if (logDate == null) return false;
            return logDate.isAfter(sevenDaysAgo) || logDate.isAtSameMomentAs(sevenDaysAgo);
          }).toList();
          break;
        case '30':
          final thirtyDaysAgo = today.subtract(const Duration(days: 30));
          _filteredPointsLogs = _allPointsLogs.where((log) {
            final logDate = log.createdAt;
            if (logDate == null) return false;
            return logDate.isAfter(thirtyDaysAgo) || logDate.isAtSameMomentAs(thirtyDaysAgo);
          }).toList();
          break;
        default:
          _filteredPointsLogs = List.from(_allPointsLogs);
      }
    });
  }
  
  void _calculateMonthlyPoints() {
    final Map<String, int> monthlyTemp = {};
    
    for (var log in _allPointsLogs) {
      final date = log.createdAt;
      if (date == null) continue;
      
      final monthKey = _formatMonthYear(date);
      final amountValue = log.amount ?? 0;
      int pointsValue = amountValue.abs();
      final isEarned = amountValue > 0;
      final pointsToAdd = isEarned ? pointsValue : -pointsValue;
      
      monthlyTemp[monthKey] = (monthlyTemp[monthKey] ?? 0) + pointsToAdd;
    }
    
    _monthlyPoints = monthlyTemp;
    _months = _monthlyPoints.keys.toList();
    _months.sort((a, b) {
      final dateA = _parseMonthYear(a);
      final dateB = _parseMonthYear(b);
      return dateB.compareTo(dateA);
    });
    
    if (_months.isNotEmpty) {
      _selectedMonthIndex = 0;
    }
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData(loadMore: false);
  }
  
  // Helper getters for user data
  String get _userName => _userInfo?.name ?? "";
  String get _userEmail => _userInfo?.email ?? "";
  String get _userPhone => _userInfo?.phone ?? "";
  String get _userAvatar => _userInfo?.avatar ?? "";
  double get _pointsBalance => _userInfo?.balance ?? 0.0;
  double get _userCash => _userInfo?.affiliateBalance ?? 0.0;
  
  DateTime _parseMonthYear(String monthYear) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    
    final parts = monthYear.split(' ');
    final monthName = parts[0];
    final year = int.parse(parts[1]);
    final month = months[monthName] ?? 1;
    
    return DateTime(year, month);
  }
  
  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
  
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  // FIXED: Use PointHistory type
  String _getUserDisplay(PointHistory log) {
    if (log.cameFrom != null && log.cameFrom!.isNotEmpty) {
      return log.cameFrom!;
    }
    return _userName;
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.points_history,
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
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),
                      _buildFilterTabs(),
                      _buildPointsHistorySection(),
                      if (_months.isNotEmpty) _buildMonthlySection(),
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
      padding: EdgeInsets.fromLTRB(0, 0, 0, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: ShimmerHelper().buildBasicShimmer(height: 87.h, radius: 20.r),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (index) => 
                  Container(
                    margin: EdgeInsets.only(right: 8.w),
                    width: 60.w,
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: MyTheme.shimmer_base,
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              AppLocalizations.of(context)!.points_history,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: List.generate(3, (index) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: ShimmerHelper().buildBasicShimmer(height: 100.h, radius: 14.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.points_balance,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${FormatHelper.formatPrice(_pointsBalance)} ${AppLocalizations.of(context)!.points_ucf}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0092AC),
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
  
  Widget _buildFilterTabs() {
    final filters = [AppLocalizations.of(context)!.all_ucf, AppLocalizations.of(context)!.today_ucf, '7', '30'];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isActive = _selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0092AC) : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Text(
                  filter == '7' ? '${AppLocalizations.of(context)!.days_ucf} 7' : (filter == '30' ? '${AppLocalizations.of(context)!.days_ucf} 30' : filter),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPointsHistorySection() {
    final displayList = _filteredPointsLogs;
    final hasMore = _hasMore;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.points_history,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.total_ucf}: $_totalItems',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          if (displayList.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                ...displayList.map((log) => _buildHistoryCard(log)).toList(),
                // Loading indicator at bottom
                if (_isLoadingMore)
                  Padding(
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
                  ),
                // End of list message
                if (!hasMore && displayList.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Text(
                      'No more points history',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF999999),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
  
  // FIXED: Use PointHistory type
  Widget _buildHistoryCard(PointHistory log) {
    final date = log.createdAt;
    final amountValue = log.amount ?? 0;
    final pointsValue = amountValue.abs();
    final isEarned = amountValue > 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
      ),
      child: Column(
        children: [
          _buildHistoryRow(
            AppLocalizations.of(context)!.date_ucf,
            date != null 
                ? '${date.day} ${_getMonthAbbreviation(date.month)} ${date.year}, ${_formatTime(date)}'
                : AppLocalizations.of(context)!.unknown,
          ),
          _buildHistoryRow(
            AppLocalizations.of(context)!.description_ucf,
            log.cameFrom ?? AppLocalizations.of(context)!.points_transaction,
          ),
          _buildHistoryRow(
            AppLocalizations.of(context)!.points_ucf,
            '${isEarned ? '+' : '-'}$pointsValue ${AppLocalizations.of(context)!.points_ucf}',
            isHighlighted: true,
            highlightColor: isEarned ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryRow(String label, String value, {
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: isHighlighted 
                    ? (highlightColor ?? const Color(0xFF10B981))
                    : const Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            '⭐',
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.no_points_history_found,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context)!.share_referral_link_to_earn_points,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlySection() {
    final selectedMonth = _months[_selectedMonthIndex];
    final monthPoints = _monthlyPoints[selectedMonth] ?? 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.monthly_points_balance,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_months.length, (index) {
                final isActive = _selectedMonthIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonthIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 6.w),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF0092AC) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Text(
                      _months[index],
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.net_points,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$monthPoints ${AppLocalizations.of(context)!.points_ucf}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0092AC),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  monthPoints >= 0 
                      ? AppLocalizations.of(context)!.earned_this_month 
                      : AppLocalizations.of(context)!.spent_this_month,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}