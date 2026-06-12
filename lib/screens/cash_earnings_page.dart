import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/auth_repository.dart';

class CashEarningsPage extends StatefulWidget {
  const CashEarningsPage({Key? key}) : super(key: key);

  @override
  State<CashEarningsPage> createState() => _CashEarningsPageState();
}

class _CashEarningsPageState extends State<CashEarningsPage> {
  // User data
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userAvatar = "";
  String _userPoints = "0";
  String _cashEarnings = "0";
  int _selectedMonthIndex = 0;
  
  // Cash logs data from API
  List<dynamic> _cashLogs = [];
  Map<String, double> _monthlyCash = {};
  List<String> _months = [];
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadCashEarningsHistory();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Replace the _loadUserData method with:
  Future<void> _loadUserData() async {
    try {
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        
        setState(() {
          _userName = user.name ?? "";
          _userEmail = user.email ?? "";
          _userPhone = user.phone ?? "";
          _userAvatar = user.avatar ?? "";
          _userPoints = user.balance ?? "0";
          _cashEarnings = user.affiliateBalance?.toString() ?? "0";
        });
        
        // Save all user data to SharedPreferences
        UserDataHelper.saveUserData(user);
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadCashEarningsHistory() async {
    try {
      // Get affiliate logs from user info response
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        final affiliateLogs = user.affiliateLogs ?? [];
        
        // Get affiliate withdraw requests for withdrawal history
        final withdrawRequests = user.affiliateWithdrawRequests ?? [];
        
        // Process affiliate logs for cash earnings (filter for bonus_type that earn cash)
        // Based on your data, cash earnings would come from referral bonuses or sales
        // For now, we'll track both earnings (positive amounts) and withdrawals
        List<dynamic> allCashTransactions = [];
        
        // Add earnings from affiliate logs (positive amounts)
        for (var log in affiliateLogs) {
          // Skip point transactions, only include cash earnings
          if (log.bonusType != 'point' && (log.amount ?? 0) > 0) {
            allCashTransactions.add({
              'type': 'earning',
              'amount': (log.amount ?? 0).toDouble(),
              'cameFrom': log.cameFrom ?? 'Affiliate earning',
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
            'cameFrom': 'Withdrawal request',
            'status': request.status == 1 ? 1 : 0,
            'createdAt': request.createdAt,
            'orderId': null,
          });
        }
        
        // Sort by date
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
    } catch (e) {
      print("Error loading cash earnings history: $e");
      _cashLogs = [];
    }
  }
  
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
  
  List<dynamic> _getFilteredLogs() {
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
  
  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cash Earnings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
    );
  }
  
  Widget _buildProfileCard() {
    double cashEarningsValue = double.tryParse(_cashEarnings) ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
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
                  _userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Cash Earnings',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${cashEarningsValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
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
    
  Widget _buildCashHistorySection(List<dynamic> logs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Cash History',
            style: TextStyle(
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
    
  Widget _buildHistoryCard(dynamic log) {
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
            'Date',
            date != null 
                ? '${date.day} ${_getMonthAbbreviation(date.month)} ${date.year}, ${_formatTime(date)}'
                : 'Unknown',
          ),
          _buildHistoryRow(
            'Description',
            log['cameFrom'] ?? (isWithdrawal ? 'Cash Withdrawal' : 'Affiliate Earning'),
          ),
          _buildHistoryRow(
            isWithdrawal ? 'Withdrawn' : 'Earned',
            '${isEarning ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
            isHighlighted: true,
            highlightColor: isEarning ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          if (log['orderId'] != null)
            _buildHistoryRow(
              'Order ID',
              '#${log['orderId']}',
            ),
          _buildHistoryRow(
            'Status',
            log['status'] == 1 ? 'Completed' : 'Pending',
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
          const Text(
            'No cash earnings yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your referral link to earn cash',
            style: TextStyle(
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
          const Text(
            'Monthly Cash Summary',
            style: TextStyle(
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
                const Text(
                  'Net Cash',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${monthCash.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: monthCash >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthCash >= 0 ? 'Net earned this month' : 'Net withdrawn this month',
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