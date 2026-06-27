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
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  // Derived data (processed from _userInfo)
  List<Map<String, dynamic>> _cashLogs = [];
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
  
  // ============ FETCH DATA FROM API ============
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
        
        _processCashLogs();
        
        affiliate_balance.$ = _userInfo?.affiliateBalance?.toString() ?? "0";
        affiliate_balance.save();
        
        // if (_userInfo != null) {
        //   UserDataHelper.saveUserData(_userInfo!);
        // }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_cash_earnings);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
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
    
    setState(() {});
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
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
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.cash_earnings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    _buildCashHistorySection(filteredLogs),
                    if (_months.isNotEmpty) _buildMonthlySection(),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShimmerHelper().buildBasicShimmer(height: 87, radius: 20),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Cash History'),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(3, (index) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerHelper().buildBasicShimmer(height: 120, radius: 14),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
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
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.cash_earnings,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FormatHelper.formatPrice(_cashEarnings),
                      style: const TextStyle(
                        fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.cash_history,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2F8)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: isHighlighted 
                    ? (highlightColor ?? const Color(0xFF10B981))
                    : (statusColor ?? const Color(0xFF333333)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            '💰',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.no_cash_earnings_yet,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.share_referral_link_to_earn_cash,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.monthly_cash_summary,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
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
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF0092AC) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _months[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Card for selected month
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F8)),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.net_cash,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FormatHelper.formatPrice(monthCash.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: monthCash >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthCash >= 0 
                      ? AppLocalizations.of(context)!.net_earned_this_month 
                      : AppLocalizations.of(context)!.net_withdrawn_this_month,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}