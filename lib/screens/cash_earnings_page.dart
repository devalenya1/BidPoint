import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
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
  // Demo user data
  String _userName = "John Doe";
  String _userAvatar = "";
  double _cashEarnings = 1250.50;
  int _selectedMonthIndex = 0;
  
  // Demo cash logs data
  List<Map<String, dynamic>> _cashLogs = [];
  Map<String, double> _monthlyCash = {};
  List<String> _months = [];
  
  @override
  void initState() {
    super.initState();
    _loadDemoData();
    if (is_logged_in.$ == true) {
      _loadUserData();
    }
  }
 
  // void _loadUserData() {
  //   setState(() {
  //     _userName = user_name.$ ?? "John Doe";
  //     _userEmail = user_email.$ ?? "";
  //     _userPhone = user_phone.$ ?? "";
  //     _userAvatar = avatar_original.$ ?? "";
  //     _userPoints = balance.$ ?? "0";
  //     _cashEarnings = affiliate_balance.$ ?? "0";
  //   });
  // }

  void _loadUserData() async {
    try {
      // Fetch user data from API
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        
        setState(() {
          _userName = user.name ?? "John Doe";
          _userEmail = user.email ?? "";
          _userPhone = user.phone ?? "";
          _userAvatar = user.avatar ?? "";
          _userPoints = user.balance ?? "0";
          _cashEarnings = user.affiliateBalance ?? "0";
        });
        
        // Also update shared preferences if needed
        // user_name.$ = _userName;
        // user_email.$ = _userEmail;
        // user_phone.$ = _userPhone;
        // avatar_original.$ = _userAvatar;
        // Note: You'll need to add balance and affiliate_balance to shared_value_helper.dart
        // if you want to store them globally
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }  
   
  void _loadDemoData() {
    // Demo cash logs (matching the HTML structure)
    _cashLogs = [
      {
        'id': 1,
        'amount': 125.50,
        'user': 'Sarah Johnson',
        'orderId': 'ORD-001234',
        'status': 1, // 1: completed, 0: pending
        'date': DateTime(2024, 5, 15),
      },
      {
        'id': 2,
        'amount': 50.00,
        'user': 'Mike Thompson',
        'orderId': 'ORD-001235',
        'status': 1,
        'date': DateTime(2024, 5, 14),
      },
      {
        'id': 3,
        'amount': 25.50,
        'user': 'Emily Davis',
        'orderId': 'ORD-001236',
        'status': 0,
        'date': DateTime(2024, 5, 13),
      },
      {
        'id': 4,
        'amount': 100.00,
        'user': 'James Wilson',
        'orderId': 'ORD-001237',
        'status': 1,
        'date': DateTime(2024, 4, 28),
      },
      {
        'id': 5,
        'amount': 75.25,
        'user': 'Lisa Anderson',
        'orderId': 'ORD-001238',
        'status': 1,
        'date': DateTime(2024, 4, 20),
      },
      {
        'id': 6,
        'amount': 30.00,
        'user': 'Robert Brown',
        'orderId': 'ORD-001239',
        'status': 0,
        'date': DateTime(2024, 3, 15),
      },
      {
        'id': 7,
        'amount': 200.00,
        'user': 'Maria Garcia',
        'orderId': 'ORD-001240',
        'status': 1,
        'date': DateTime(2024, 3, 10),
      },
    ];
    
    // Calculate monthly cash totals
    final Map<String, double> monthlyTemp = {};
    for (var log in _cashLogs) {
      final date = log['date'] as DateTime;
      final monthKey = _formatMonthYear(date);
      monthlyTemp[monthKey] = (monthlyTemp[monthKey] ?? 0) + (log['amount'] as double);
    }
    
    _monthlyCash = monthlyTemp;
    _months = _monthlyCash.keys.toList();
    _months.sort((a, b) {
      final dateA = DateTime.parse('01 ${a}');
      final dateB = DateTime.parse('01 ${b}');
      return dateB.compareTo(dateA);
    });
    
    // Set default selected month to first
    if (_months.isNotEmpty) {
      _selectedMonthIndex = 0;
    }
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
      final date = log['date'] as DateTime;
      return _formatMonthYear(date) == selectedMonth;
    }).toList();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(),
            
            // Cash History Section
            _buildCashHistorySection(filteredLogs),
            
            // Monthly Cash Balance Section
            if (_months.isNotEmpty) 
              _buildMonthlySection(),
          ],
        ),
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
                      '\$${_cashEarnings.toStringAsFixed(2)}',
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
    
  Widget _buildCashHistorySection(List<Map<String, dynamic>> logs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Cash Earnings History',
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
          
          // Pagination (demo - showing limited items)
          if (logs.isNotEmpty && logs.length >= 5)
            _buildPagination(),
        ],
      ),
    );
  }
    
  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final date = log['date'] as DateTime;
    
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
            '${date.day} ${_getMonthAbbreviation(date.month)} ${date.year}',
          ),
          _buildHistoryRow(
            'User',
            log['user'],
          ),
          _buildHistoryRow(
            'Amount',
            '\$${log['amount'].toStringAsFixed(2)}',
            isHighlighted: true,
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
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted 
                  ? const Color(0xFF10B981)
                  : (statusColor ?? const Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Cash Balance',
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
                  'Total Cash Earned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${(_monthlyCash[_months[_selectedMonthIndex]] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
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
  
  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}