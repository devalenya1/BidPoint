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
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../repositories/auth_repository.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class CashEarningsPage extends StatefulWidget {
  const CashEarningsPage({Key? key}) : super(key: key);

  @override
  State<CashEarningsPage> createState() => _CashEarningsPageState();
}

class _CashEarningsPageState extends State<CashEarningsPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _selectedMonthIndex = 0;
  
  // ============ PAGINATION STATE ============
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;
  bool _isLoadingMore = false;
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  // Derived data (processed from _userInfo)
  List<Map<String, dynamic>> _cashLogs = [];
  List<Map<String, dynamic>> _paginatedCashLogs = [];
  Map<String, double> _monthlyCash = {};
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
  Future<void> _fetchUserData({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
      
      // For cash history, we need to fetch user info with cash pagination
      var response = await ProfileRepository().getUserInfoResponse(
        notificationPage: 1,
        notificationPerPage: 10,
        pointPage: 1,
        pointPerPage: 10,
        cashPage: page,
        cashPerPage: _perPage,
        withdrawPage: 1,
        withdrawPerPage: 10,
      );
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final newUserInfo = response.data![0];
        
        // Update pagination info from cash_pagination
        final pagination = newUserInfo.cashPagination;
        if (pagination != null) {
          _currentPage = pagination.currentPage;
          _totalPages = pagination.totalPages;
          _totalItems = pagination.total;
          _perPage = pagination.perPage;
        }
        
        setState(() {
          if (page == 1) {
            // First page - replace all data
            _userInfo = newUserInfo;
          } else {
            // Subsequent pages - update user info but keep existing data
            _userInfo = UserInformation(
              id: _userInfo?.id ?? newUserInfo.id,
              name: _userInfo?.name ?? newUserInfo.name,
              email: _userInfo?.email ?? newUserInfo.email,
              avatar: _userInfo?.avatar ?? newUserInfo.avatar,
              address: _userInfo?.address ?? newUserInfo.address,
              country: _userInfo?.country ?? newUserInfo.country,
              state: _userInfo?.state ?? newUserInfo.state,
              city: _userInfo?.city ?? newUserInfo.city,
              postalCode: _userInfo?.postalCode ?? newUserInfo.postalCode,
              phone: _userInfo?.phone ?? newUserInfo.phone,
              balance: _userInfo?.balance ?? newUserInfo.balance,
              referralCode: _userInfo?.referralCode ?? newUserInfo.referralCode,
              remainingUploads: _userInfo?.remainingUploads ?? newUserInfo.remainingUploads,
              packageId: _userInfo?.packageId ?? newUserInfo.packageId,
              packageName: _userInfo?.packageName ?? newUserInfo.packageName,
              // Keep existing cash history and add new ones
              affiliateLogs: page == 1 
                  ? newUserInfo.affiliateLogs 
                  : [...?_userInfo?.affiliateLogs, ...?newUserInfo.affiliateLogs],
              totalAffiliateEarnings: newUserInfo.totalAffiliateEarnings,
              affiliateWithdrawRequests: page == 1 
                  ? newUserInfo.affiliateWithdrawRequests 
                  : [...?_userInfo?.affiliateWithdrawRequests, ...?newUserInfo.affiliateWithdrawRequests],
              totalWithdrawnAmount: _userInfo?.totalWithdrawnAmount ?? newUserInfo.totalWithdrawnAmount,
              pendingWithdrawAmount: _userInfo?.pendingWithdrawAmount ?? newUserInfo.pendingWithdrawAmount,
              addresses: _userInfo?.addresses ?? newUserInfo.addresses,
              addressCount: _userInfo?.addressCount ?? newUserInfo.addressCount,
              defaultAddressCount: _userInfo?.defaultAddressCount ?? newUserInfo.defaultAddressCount,
              customerPackagePayments: _userInfo?.customerPackagePayments ?? newUserInfo.customerPackagePayments,
              totalPackagePayments: _userInfo?.totalPackagePayments ?? newUserInfo.totalPackagePayments,
              wishlist: _userInfo?.wishlist ?? newUserInfo.wishlist,
              wishlistCount: _userInfo?.wishlistCount ?? newUserInfo.wishlistCount,
              auctionBids: _userInfo?.auctionBids ?? newUserInfo.auctionBids,
              auctionBidsCount: _userInfo?.auctionBidsCount ?? newUserInfo.auctionBidsCount,
              distinctAuctionBids: _userInfo?.distinctAuctionBids ?? newUserInfo.distinctAuctionBids,
              distinctAuctionBidsCount: _userInfo?.distinctAuctionBidsCount ?? newUserInfo.distinctAuctionBidsCount,
              affiliateId: _userInfo?.affiliateId ?? newUserInfo.affiliateId,
              paypalEmail: _userInfo?.paypalEmail ?? newUserInfo.paypalEmail,
              bankName: _userInfo?.bankName ?? newUserInfo.bankName,
              accountHolder: _userInfo?.accountHolder ?? newUserInfo.accountHolder,
              accountNumber: _userInfo?.accountNumber ?? newUserInfo.accountNumber,
              ifscCode: _userInfo?.ifscCode ?? newUserInfo.ifscCode,
              affiliateBalance: _userInfo?.affiliateBalance ?? newUserInfo.affiliateBalance,
              affiliateStatus: _userInfo?.affiliateStatus ?? newUserInfo.affiliateStatus,
              notifications: _userInfo?.notifications ?? newUserInfo.notifications,
              unreadNotificationsCount: _userInfo?.unreadNotificationsCount ?? newUserInfo.unreadNotificationsCount,
              unreadMessagesCount: _userInfo?.unreadMessagesCount ?? newUserInfo.unreadMessagesCount,
            );
          }
        });
        
        _processCashLogs();
        
        affiliate_balance.$ = _userInfo?.affiliateBalance?.toString() ?? "0";
        affiliate_balance.save();
        
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_cash_earnings);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
      });
    }
  }
  
  // ============ GO TO PAGE ============
  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    await _fetchUserData(page: page);
  }
  
  // ============ GO TO NEXT PAGE ============
  Future<void> _nextPage() async {
    if (_currentPage < _totalPages) {
      await _goToPage(_currentPage + 1);
    }
  }
  
  // ============ GO TO PREVIOUS PAGE ============
  Future<void> _previousPage() async {
    if (_currentPage > 1) {
      await _goToPage(_currentPage - 1);
    }
  }
  
  // ============ PROCESS CASH LOGS ============
  void _processCashLogs() {
    if (_userInfo == null) return;
    
    final affiliateLogs = _userInfo!.affiliateLogs ?? [];
    final withdrawRequests = _userInfo!.affiliateWithdrawRequests ?? [];
    
    List<Map<String, dynamic>> allCashTransactions = [];
    
    // Add earnings from affiliate logs (positive amounts)
    for (var log in affiliateLogs) {
      if (log.bonusType != 'point' && (log.amount ?? 0) > 0) {
        allCashTransactions.add({
          'type': 'earning',
          'amount': (log.amount ?? 0).toDouble(),
          'cameFrom': log.cameFrom ?? AppLocalizations.of(context)!.affiliate_earning,
          'status': log.status == 1 ? 1 : 0,
          'createdAt': log.createdAt,
          'orderId': log.orderId,
        });
      }
    }
    
    // Add withdrawals (negative amounts)
    for (var request in withdrawRequests) {
      allCashTransactions.add({
        'type': 'withdrawal',
        'amount': -(request.amount ?? 0).toDouble(),
        'cameFrom': AppLocalizations.of(context)!.withdrawal_request,
        'status': request.status == 1 ? 1 : 0,
        'createdAt': request.createdAt,
        'orderId': null,
      });
    }
    
    // Sort by date (newest first)
    allCashTransactions.sort((a, b) {
      final dateA = a['createdAt'];
      final dateB = b['createdAt'];
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });
    
    _cashLogs = allCashTransactions;
    
    // Calculate monthly cash totals
    final Map<String, double> monthlyTemp = {};
    for (var log in _cashLogs) {
      final date = log['createdAt'];
      if (date == null) continue;
      
      final monthKey = _formatMonthYear(date);
      monthlyTemp[monthKey] = (monthlyTemp[monthKey] ?? 0) + (log['amount'] as double);
    }
    
    _monthlyCash = monthlyTemp;
    _months = _monthlyCash.keys.toList();
    _months.sort((a, b) {
      final dateA = _parseMonthYear(a);
      final dateB = _parseMonthYear(b);
      return dateB.compareTo(dateA);
    });
    
    if (_months.isNotEmpty) {
      _selectedMonthIndex = 0;
    }
    
    // Update paginated logs
    _updatePaginatedLogs();
    
    setState(() {});
  }
  
  void _updatePaginatedLogs() {
    final filtered = _getFilteredLogs();
    final start = (_currentPage - 1) * _perPage;
    final end = start + _perPage;
    _paginatedCashLogs = filtered.skip(start).take(_perPage).toList();
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData(page: 1);
  }
  
  // Helper getters for user data
  String get _userName => _userInfo?.name ?? "";
  String get _userEmail => _userInfo?.email ?? "";
  String get _userPhone => _userInfo?.phone ?? "";
  String get _userAvatar => _userInfo?.avatar ?? "";
  int get _userPoints => (_userInfo?.balance ?? 0).toInt();
  double get _cashEarnings => _userInfo?.affiliateBalance ?? 0.0;
  
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
  
  List<Map<String, dynamic>> _getFilteredLogs() {
    if (_months.isEmpty) return [];
    final selectedMonth = _months[_selectedMonthIndex];
    return _cashLogs.where((log) {
      final date = log['createdAt'];
      if (date == null) return false;
      return _formatMonthYear(date) == selectedMonth;
    }).toList();
  }
  
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    final totalFilteredItems = filteredLogs.length;
    final totalFilteredPages = totalFilteredItems > 0 ? (totalFilteredItems / _perPage).ceil() : 1;
    
    // Ensure current page is valid
    if (_currentPage > totalFilteredPages) {
      _currentPage = totalFilteredPages;
    }
    
    // Update paginated logs
    _paginatedCashLogs = filteredLogs.skip((_currentPage - 1) * _perPage).take(_perPage).toList();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.cash_earnings,
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
                padding: EdgeInsets.fromLTRB(0, 0, 0, 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    _buildCashHistorySection(_paginatedCashLogs),
                    if (_months.isNotEmpty) _buildMonthlySection(),
                    // =============================================
                    // PAGINATION CONTROLS
                    // =============================================
                    if (totalFilteredPages > 1) _buildPaginationControls(totalFilteredPages),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ PAGINATION CONTROLS ============
  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // Page info
          Text(
            '${AppLocalizations.of(context)!.page_ucf} $_currentPage ${AppLocalizations.of(context)!.of_ucf} $totalPages',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8.h),
          // Pagination buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              GestureDetector(
                onTap: _currentPage > 1 ? _previousPage : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _currentPage > 1 ? const Color(0xFF0092AC) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 16.sp,
                        color: _currentPage > 1 ? Colors.white : const Color(0xFF999999),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        AppLocalizations.of(context)!.previous_ucf,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _currentPage > 1 ? Colors.white : const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Page numbers
              ..._buildPageNumbers(totalPages),
              SizedBox(width: 8.w),
              // Next button
              GestureDetector(
                onTap: _currentPage < totalPages ? _nextPage : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _currentPage < totalPages ? const Color(0xFF0092AC) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.next_ucf,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _currentPage < totalPages ? Colors.white : const Color(0xFF999999),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward,
                        size: 16.sp,
                        color: _currentPage < totalPages ? Colors.white : const Color(0xFF999999),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Loading more indicator
          if (_isLoadingMore)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: CircularProgressIndicator(
                color: MyTheme.accent_color,
                strokeWidth: 2.w,
              ),
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> widgets = [];
    int maxVisible = 5;
    int startPage = 1;
    int endPage = totalPages;
    
    if (totalPages > maxVisible) {
      if (_currentPage <= 3) {
        startPage = 1;
        endPage = maxVisible;
      } else if (_currentPage >= totalPages - 2) {
        startPage = totalPages - maxVisible + 1;
        endPage = totalPages;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
      }
    }
    
    if (startPage > 1) {
      widgets.add(_buildPageNumber(1, totalPages));
      if (startPage > 2) {
        widgets.add(Text(
          '...',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ));
      }
    }
    
    for (int i = startPage; i <= endPage && i <= totalPages; i++) {
      widgets.add(_buildPageNumber(i, totalPages));
    }
    
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        widgets.add(Text(
          '...',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ));
      }
      widgets.add(_buildPageNumber(totalPages, totalPages));
    }
    
    return widgets;
  }
  
  Widget _buildPageNumber(int page, int totalPages) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: () => _goToPage(page),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0092AC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: isActive ? null : Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1.w,
          ),
        ),
        child: Center(
          child: Text(
            page.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
            child: Text(
              AppLocalizations.of(context)!.cash_history,
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
                  child: ShimmerHelper().buildBasicShimmer(height: 120.h, radius: 14.r),
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
                    fontSize: 16.sp,
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
                      AppLocalizations.of(context)!.cash_earnings,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      FormatHelper.formatPrice(_cashEarnings),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
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
    
  Widget _buildCashHistorySection(List<Map<String, dynamic>> logs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.cash_history,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.total_ucf}: ${_getFilteredLogs().length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          if (logs.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: logs.map((log) => _buildHistoryCard(log)).toList(),
            ),
        ],
      ),
    );
  }
    
  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final date = log['createdAt'];
    final amount = log['amount'] as double;
    final isEarning = amount > 0;
    final isWithdrawal = log['type'] == 'withdrawal';
    
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
            log['cameFrom'] ?? (isWithdrawal 
                ? AppLocalizations.of(context)!.cash_withdrawal 
                : AppLocalizations.of(context)!.affiliate_earning),
          ),
          _buildHistoryRow(
            isWithdrawal ? AppLocalizations.of(context)!.withdrawn_ucf : AppLocalizations.of(context)!.earned_ucf,
            '${isEarning ? '+' : ''}${FormatHelper.formatPrice(amount.abs())}',
            isHighlighted: true,
            highlightColor: isEarning ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          if (log['orderId'] != null)
            _buildHistoryRow(
              AppLocalizations.of(context)!.order_id_ucf,
              '#${log['orderId']}',
            ),
          _buildHistoryRow(
            AppLocalizations.of(context)!.status_ucf,
            log['status'] == 1 ? AppLocalizations.of(context)!.completed_ucf : AppLocalizations.of(context)!.pending_ucf,
            statusColor: log['status'] == 1 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryRow(String label, String value, {
    bool isHighlighted = false,
    Color? highlightColor,
    Color? statusColor,
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
                    : (statusColor ?? const Color(0xFF333333)),
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
            '💰',
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.no_cash_earnings_yet,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context)!.share_referral_link_to_earn_cash,
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
    final monthCash = _monthlyCash[selectedMonth] ?? 0.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.monthly_cash_summary,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Month Selection Tabs
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
                    // Update pagination when month changes
                    _currentPage = 1;
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
          
          // Summary Card for selected month
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
                  AppLocalizations.of(context)!.net_cash,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  FormatHelper.formatPrice(monthCash.abs()),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: monthCash >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  monthCash >= 0 
                      ? AppLocalizations.of(context)!.net_earned_this_month 
                      : AppLocalizations.of(context)!.net_withdrawn_this_month,
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