import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
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

class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({Key? key}) : super(key: key);

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}
 
class _PointsHistoryPageState extends State<PointsHistoryPage> {
  // User data
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userAvatar = "";
  int _pointsBalance = 0;
  double _userCash = 0.0;
  String _selectedFilter = 'All';
  
  // Points logs data from API
  List<dynamic> _allPointsLogs = [];
  List<dynamic> _filteredPointsLogs = [];
  Map<String, int> _monthlyPoints = {};
  List<String> _months = [];
  int _selectedMonthIndex = 0;
  
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
    await _loadPointsHistory();
    
    setState(() {
      _isLoading = false;
    });
  }
  
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
          _pointsBalance = (user.balance ?? 0).toInt();
          _userCash = user.affiliateBalance ?? 0.0;
        });
        
        // Save all user data to SharedPreferences
        UserDataHelper.saveUserData(user);
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }
    
  Future<void> _loadPointsHistory() async {
    try {
      // Use affiliate_logs from user info response since it contains points transactions
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        final affiliateLogs = user.affiliateLogs ?? [];
        
        // Filter for point transactions only
        _allPointsLogs = affiliateLogs.where((log) {
          return log.bonusType == 'point';
        }).toList();
        
        _applyFilter();
        _calculateMonthlyPoints();
      }
    } catch (e) {
      print("Error loading points history: $e");
      _allPointsLogs = [];
      _filteredPointsLogs = [];
    }
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
      
      // Get the amount and ensure it's an int
      final amount = log.amount;
      int pointsValue = 0;
      if (amount != null) {
        if (amount is int) {
          pointsValue = amount.abs();
        } else if (amount is double) {
          pointsValue = amount.abs().toInt();
        } else {
          pointsValue = (amount as num).abs().toInt();
        }
      }
      
      // Points are negative for spending, positive for earning
      final isEarned = (log.amount ?? 0) > 0;
      final pointsToAdd = isEarned ? pointsValue : -pointsValue;
      
      // Get current value or default to 0
      int currentValue = monthlyTemp[monthKey] ?? 0;
      // Calculate new value
      int newValue = currentValue + pointsToAdd;
      // Assign back to map
      monthlyTemp[monthKey] = newValue;
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
  
  String _getUserDisplay(dynamic log) {
    if (log.cameFrom != null && log.cameFrom.toString().isNotEmpty) {
      return log.cameFrom;
    }
    return _userName;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
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
                      '$_pointsBalance points',
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
        ],
      ),
    );
  }
  
  Widget _buildHistoryCard(dynamic log) {
    final date = log.createdAt;
    final pointsValue = (log.amount ?? 0).abs().toInt();
    // If amount is negative, it's spent (deducted), if positive it's earned
    final isEarned = (log.amount ?? 0) > 0;
    
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
            log.cameFrom ?? 'Points transaction',
          ),
          _buildHistoryRow(
            'Points',
            '${isEarned ? '+' : '-'}$pointsValue pts',
            isHighlighted: true,
            highlightColor: isEarned ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildHistoryRow(String label, String value, {
    bool isHighlighted = false,
    Color? highlightColor,
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
                    : const Color(0xFF333333),
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
    final selectedMonth = _months[_selectedMonthIndex];
    final monthPoints = _monthlyPoints[selectedMonth] ?? 0;
    
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
                  'Net Points',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$monthPoints points',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0092AC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthPoints >= 0 ? 'Earned this month' : 'Spent this month',
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