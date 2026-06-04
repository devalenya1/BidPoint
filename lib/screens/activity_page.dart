import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'dart:async';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: All, 1: Outbid, 2: Winning, 3: Recently Ended
  
  // Demo activity data
  List<Map<String, dynamic>> _allActivities = [];
  List<Map<String, dynamic>> _outbidActivities = [];
  List<Map<String, dynamic>> _winningActivities = [];
  List<Map<String, dynamic>> _endedActivities = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }
  
  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }
  
  void _loadDemoData() {
    // Demo activity data
    _allActivities = [
      {
        'id': 1,
        'productName': 'Vintage Rolex Watch',
        'productImage': null,
        'myBid': 1250.00,
        'currentBid': 1350.00,
        'pointsPerBid': 10,
        'endDate': DateTime.now().add(const Duration(days: 2, hours: 5)),
        'status': 'outbid', // outbid, winning, won, ended
        'isAuctionEnded': false,
      },
      {
        'id': 2,
        'productName': 'iPhone 15 Pro Max - 1TB',
        'productImage': null,
        'myBid': 850.00,
        'currentBid': 850.00,
        'pointsPerBid': 15,
        'endDate': DateTime.now().add(const Duration(days: 1, hours: 3)),
        'status': 'winning',
        'isAuctionEnded': false,
      },
      {
        'id': 3,
        'productName': 'Samsung Galaxy S24 Ultra',
        'productImage': null,
        'myBid': 620.00,
        'currentBid': 620.00,
        'pointsPerBid': 12,
        'endDate': DateTime.now().add(const Duration(hours: 12)),
        'status': 'winning',
        'isAuctionEnded': false,
      },
      {
        'id': 4,
        'productName': 'MacBook Pro M3',
        'productImage': null,
        'myBid': 1950.00,
        'currentBid': 1950.00,
        'pointsPerBid': 20,
        'endDate': DateTime.now().add(const Duration(days: 3)),
        'status': 'winning',
        'isAuctionEnded': false,
      },
      {
        'id': 5,
        'productName': 'Sony PlayStation 5',
        'productImage': null,
        'myBid': 450.00,
        'currentBid': 480.00,
        'pointsPerBid': 8,
        'endDate': DateTime.now().add(const Duration(days: 5)),
        'status': 'outbid',
        'isAuctionEnded': false,
      },
      {
        'id': 6,
        'productName': 'Canon EOS R5 Camera',
        'productImage': null,
        'myBid': 2800.00,
        'currentBid': 2800.00,
        'pointsPerBid': 25,
        'endDate': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'won',
        'isAuctionEnded': true,
      },
      {
        'id': 7,
        'productName': 'Nike Air Jordan 1',
        'productImage': null,
        'myBid': 320.00,
        'currentBid': 350.00,
        'pointsPerBid': 5,
        'endDate': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'ended',
        'isAuctionEnded': true,
      },
    ];
    
    // Filter activities by status
    _outbidActivities = _allActivities.where((a) => a['status'] == 'outbid' && a['isAuctionEnded'] == false).toList();
    _winningActivities = _allActivities.where((a) => a['status'] == 'winning' && a['isAuctionEnded'] == false).toList();
    _endedActivities = _allActivities.where((a) => a['isAuctionEnded'] == true).toList();
    
    // Start timers
    for (var activity in _allActivities) {
      if (!activity['isAuctionEnded']) {
        _startTimer(activity['id'], activity['endDate']);
      }
    }
  }
  
  void _startTimer(int id, DateTime endDate) {
    _updateTimeLeft(id, endDate);
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft(id, endDate);
    });
    _timers[id] = timer;
  }
  
  void _updateTimeLeft(int id, DateTime endDate) {
    final now = DateTime.now();
    final distance = endDate.difference(now);
    
    if (distance.isNegative) {
      setState(() {
        _timeLeft[id] = "Ended";
      });
      _timers[id]?.cancel();
      return;
    }
    
    final days = distance.inDays;
    final hours = distance.inHours % 24;
    final minutes = distance.inMinutes % 60;
    final seconds = distance.inSeconds % 60;
    
    String timeString;
    if (days > 0) {
      timeString = "${days}d ${hours}h";
    } else if (hours > 0) {
      timeString = "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      timeString = "${minutes}m ${seconds}s";
    } else {
      timeString = "${seconds}s";
    }
    
    setState(() {
      _timeLeft[id] = timeString;
    });
  }
  
  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Header
          _buildHeader(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Tabs
                    _buildTabs(),
                    const SizedBox(height: 20),
                    // Tab Content
                    _selectedTab == 0 ? _buildActivityList(_allActivities, "all") :
                    _selectedTab == 1 ? _buildActivityList(_outbidActivities, "outbid") :
                    _selectedTab == 2 ? _buildActivityList(_winningActivities, "winning") :
                    _buildActivityList(_endedActivities, "ended"),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: MyTheme.light_grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel/Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MyTheme.light_grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          // Title
          Text(
            AppLocalizations.of(context)!.activity_ucf,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MyTheme.dark_font_grey,
            ),
          ),
          // Invisible placeholder for balance
          const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  Widget _buildTabs() {
    final List<String> tabNames = ['All', 'Outbid', 'Winning', 'Recently Ended'];
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MyTheme.light_grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabNames.length, (index) {
          final isActive = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  tabNames[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildActivityList(List<Map<String, dynamic>> activities, String type) {
    if (activities.isEmpty) {
      return _buildEmptyState(type);
    }
    
    return Column(
      children: activities.map((activity) {
        return _buildActivityCard(activity);
      }).toList(),
    );
  }
  
  Widget _buildEmptyState(String type) {
    String icon;
    String title;
    String subtitle;
    
    switch (type) {
      case "outbid":
        icon = "🎯";
        title = "No outbid activities";
        subtitle = "Your bids are currently leading!";
        break;
      case "winning":
        icon = "🏆";
        title = "No winning bids yet";
        subtitle = "Place a bid to become the highest bidder";
        break;
      case "ended":
        icon = "⏰";
        title = "No ended auctions";
        subtitle = "Check back later for completed auctions";
        break;
      default:
        icon = "📭";
        title = "No activity found";
        subtitle = "Start bidding on auctions to see your activity here";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isOutbid = activity['status'] == 'outbid' && !activity['isAuctionEnded'];
    final isWinning = activity['status'] == 'winning' && !activity['isAuctionEnded'];
    final isWon = activity['status'] == 'won' && activity['isAuctionEnded'];
    final isEnded = activity['status'] == 'ended' && activity['isAuctionEnded'];
    
    String statusText;
    Color statusColor;
    
    if (isOutbid) {
      statusText = "You were outbid";
      statusColor = const Color(0xFFDC2626);
    } else if (isWinning) {
      statusText = "Currently winning";
      statusColor = const Color(0xFF10B981);
    } else if (isWon) {
      statusText = "You won this auction!";
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusText = "Auction ended";
      statusColor = const Color(0xFF64748B);
    }
    
    final timeLeft = _timeLeft[activity['id']] ?? "Loading...";
    final isTimerEnded = timeLeft == "Ended";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 120,
            height: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(
                      Icons.inventory_2,
                      size: 50,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                // Timer Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTimerEnded ? const Color(0xFFDC3545) : const Color(0xFF009572),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeLeft,
                          style: const TextStyle(
                            fontSize: 10,
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
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Product Title
                Text(
                  isOutbid 
                      ? "Someone placed a higher bid on ${activity['productName']}"
                      : isWinning
                          ? "Your bid is currently the highest on ${activity['productName']}"
                          : isWon
                              ? "Congratulations! You won ${activity['productName']}"
                              : "You didn't win ${activity['productName']}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF80818B),
                  ),
                ),
                const SizedBox(height: 8),
                // Bid Label
                Text(
                  isWon || isEnded ? "Final bid:" : "Current bid:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF80818B),
                  ),
                ),
                const SizedBox(height: 4),
                // Bid Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatPrice(activity['currentBid']),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: MyTheme.dark_font_grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Color(0xFF0092AC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "1 Bid = ${activity['pointsPerBid']}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0092AC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Button
                if (isOutbid)
                  _buildOutbidButton(activity)
                else if (isWinning || isWon)
                  _buildViewDetailsButton()
                else if (isEnded)
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOutbidButton(Map<String, dynamic> activity) {
    return GestureDetector(
      onTap: () {
        // Navigate to bid again
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid again on ${activity['productName']}'),
            backgroundColor: MyTheme.accent_color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: MyTheme.accent_color, width: 1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          'Bid Again',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MyTheme.accent_color,
          ),
        ),
      ),
    );
  }
  
  Widget _buildViewDetailsButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('View product details'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: MyTheme.accent_color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          'View Details',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}