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
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';

class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({Key? key}) : super(key: key);

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  // Demo user data
  String _userName = "John Doe";
  String _userAvatar = "";
  int _pointsBalance = 1250;
  String _selectedFilter = 'All'; // All, Today, 7, 30
  
  // Demo points logs data
  List<Map<String, dynamic>> _allPointsLogs = [];
  List<Map<String, dynamic>> _filteredPointsLogs = [];
  Map<String, int> _monthlyPoints = {};
  List<String> _months = [];
  int _selectedMonthIndex = 0;
  
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
  //     _userAvatar = avatar_original.$ ?? "";
  //     _pointsBalance = balance.$ ?? "0";
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
          _pointsBalance = user.balance ?? "0";
          _userCash = user.affiliateBalance ?? "0";
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
    // Demo points logs
    _allPointsLogs = [
      {
        'id': 1,
        'points': 500,
        'type': 'earned',
        'user': 'Sarah Johnson',
        'came_from': 'Sarah Johnson',
        'status': 1,
        'date': DateTime(2024, 5, 15, 14, 30),
      },
      {
        'id': 2,
        'points': 100,
        'type': 'earned',
        'user': 'System',
        'came_from': 'Daily Bonus',
        'status': 1,
        'date': DateTime(2024, 5, 14, 9, 15),
      },
      {
        'id': 3,
        'points': 50,
        'type': 'spent',
        'user': 'System',
        'came_from': 'Bid placed on product',
        'status': 1,
        'date': DateTime(2024, 5, 13, 20, 0),
      },
      {
        'id': 4,
        'points': 200,
        'type': 'earned',
        'user': 'Mike Thompson',
        'came_from': 'Mike Thompson',
        'status': 1,
        'date': DateTime(2024, 4, 28, 11, 45),
      },
      {
        'id': 5,
        'points': 75,
        'type': 'earned',
        'user': 'System',
        'came_from': 'Weekly challenge',
        'status': 1,
        'date': DateTime(2024, 4, 20, 16, 20),
      },
      {
        'id': 6,
        'points': 30,
        'type': 'spent',
        'user': 'System',
        'came_from': 'Bid placed',
        'status': 0,
        'date': DateTime(2024, 3, 15, 10, 0),
      },
      {
        'id': 7,
        'points': 300,
        'type': 'earned',
        'user': 'System',
        'came_from': 'Special promotion',
        'status': 1,
        'date': DateTime(2024, 3, 10, 8, 30),
      },
      {
        'id': 8,
        'points': 150,
        'type': 'earned',
        'user': 'Emily Davis',
        'came_from': 'Emily Davis',
        'status': 1,
        'date': DateTime(2024, 2, 25, 13, 0),
      },
      {
        'id': 9,
        'points': 80,
        'type': 'earned',
        'user': 'James Wilson',
        'came_from': 'James Wilson',
        'status': 1,
        'date': DateTime(2024, 2, 18, 9, 45),
      },
    ];
    
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
            final logDate = log['date'] as DateTime;
            return logDate.year == today.year && 
                   logDate.month == today.month && 
                   logDate.day == today.day;
          }).toList();
          break;
        case '7':
          final sevenDaysAgo = today.subtract(const Duration(days: 7));
          _filteredPointsLogs = _allPointsLogs.where((log) {
            final logDate = log['date'] as DateTime;
            return logDate.isAfter(sevenDaysAgo) || logDate.isAtSameMomentAs(sevenDaysAgo);
          }).toList();
          break;
        case '30':
          final thirtyDaysAgo = today.subtract(const Duration(days: 30));
          _filteredPointsLogs = _allPointsLogs.where((log) {
            final logDate = log['date'] as DateTime;
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
      final date = log['date'] as DateTime;
      final monthKey = _formatMonthYear(date);
      final points = log['points'] as int;
      final isEarned = log['type'] == 'earned';
      monthlyTemp[monthKey] = (monthlyTemp[monthKey] ?? 0) + (isEarned ? points : -points);
    }
    
    _monthlyPoints = monthlyTemp;
    _months = _monthlyPoints.keys.toList();
    _months.sort((a, b) {
      final dateA = DateTime.parse('01 $a');
      final dateB = DateTime.parse('01 $b');
      return dateB.compareTo(dateA);
    });
    
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
  
  String _getUserDisplay(Map<String, dynamic> log) {
    if (log['came_from'] != null && log['came_from'].toString().isNotEmpty) {
      return log['came_from'];
    }
    return log['user'];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Points History',
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
            
            // Filter Tabs
            _buildFilterTabs(),
            
            // Points History Section
            _buildPointsHistorySection(),
            
            // Monthly Points Balance Section
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
                      'Points Balance',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_pointsBalance.toString()} points',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0092AC),
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
    final filters = ['All', 'Today', '7', '30'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
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
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0092AC) : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_filteredPointsLogs.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: _filteredPointsLogs.map((log) => _buildHistoryCard(log)).toList(),
            ),
          
          // Pagination (demo)
          if (_filteredPointsLogs.isNotEmpty)
            _buildPagination(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final date = log['date'] as DateTime;
    final pointsValue = log['points'] as int;
    final isEarned = log['type'] == 'earned';
    
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
            _getUserDisplay(log),
          ),
          _buildHistoryRow(
            'Points',
            '${isEarned ? '+' : '-'}${pointsValue.toString()} pts',
            isHighlighted: true,
            highlightColor: MyTheme.accent_color,
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
                  ? (highlightColor ?? const Color(0xFF10B981))
                  : const Color(0xFF333333),
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
            '⭐',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          const Text(
            'No points history found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your referral link to earn points',
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
            'Monthly Points Balance',
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
                  'Total Points Earned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_monthlyPoints[_months[_selectedMonthIndex]] ?? 0).toString()} points',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0092AC),
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
                color: Color(0xFF0092AC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}