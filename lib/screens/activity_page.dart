import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'dart:async';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: All, 1: Outbid, 2: Winning, 3: Recently Ended
  
  // Real activity data from API
  List<dynamic> _allActivities = [];
  List<dynamic> _outbidActivities = [];
  List<dynamic> _winningActivities = [];
  List<dynamic> _endedActivities = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _loadActivities();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }
  
  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        final auctionBids = user.auctionBids ?? [];
        final distinctAuctionBids = user.distinctAuctionBids ?? [];
        
        // Save all user data to SharedPreferences
        UserDataHelper.saveUserData(user);
        
        // Process auction bids to create activities
        List<dynamic> activities = [];
        
        // Get all products the user has bid on from distinct auction bids
        for (var product in distinctAuctionBids) {
          if (product.productId == null) continue;
          
          // Get user's highest bid for this product
          final userBids = auctionBids.where((bid) => bid.productId == product.productId).toList();
          final userHighestBid = userBids.isNotEmpty 
              ? userBids.map((b) => b.amount ?? 0).reduce((a, b) => a > b ? a : b)
              : 0;
          
          // Get highest bid overall for this product
          final productHighestBid = product.amount ?? 0;
          
          // Determine status
          bool isEnded = false; // You would need end date from product API
          String status;
          
          if (userHighestBid >= productHighestBid && userHighestBid > 0) {
            status = 'winning';
          } else if (userHighestBid > 0 && userHighestBid < productHighestBid) {
            status = 'outbid';
          } else {
            status = 'ended';
          }
          
          // Create activity object
          activities.add({
            'id': product.productId,
            'productId': product.productId,
            'productName': product.productName ?? 'Unknown Product',
            'productImage': product.productImage,
            'myBid': userHighestBid,
            'currentBid': productHighestBid,
            'pointsPerBid': 10, // This might need to come from product data
            'endDate': null, // You would need end date from product API
            'status': status,
            'isAuctionEnded': isEnded,
            'formattedAmount': product.formattedAmount ?? '\$${productHighestBid.toString()}',
          });
        }
        
        // Update counts in SharedPreferences
        auction_bids_count.$ = auctionBids.length;
        distinct_auction_bids_count.$ = distinctAuctionBids.length;
        
        // Filter activities
        _outbidActivities = activities.where((a) => a['status'] == 'outbid' && a['isAuctionEnded'] == false).toList();
        _winningActivities = activities.where((a) => a['status'] == 'winning' && a['isAuctionEnded'] == false).toList();
        _endedActivities = activities.where((a) => a['isAuctionEnded'] == true).toList();
        _allActivities = activities;
        
        // Start timers for activities with end dates
        for (var activity in _allActivities) {
          if (activity['endDate'] != null && !activity['isAuctionEnded']) {
            _startTimer(activity['id'], activity['endDate']);
          }
        }
      }
    } catch (e) {
      print("Error loading activities: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        _timeLeft[id] = AppLocalizations.of(context)!.ended_ucf;
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.activity_ucf,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildTabs(),
                          const SizedBox(height: 20),
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
  
  Widget _buildTabs() {
    final List<String> tabNames = [
      AppLocalizations.of(context)!.all_ucf,
      AppLocalizations.of(context)!.outbid_ucf,
      AppLocalizations.of(context)!.winning_ucf,
      AppLocalizations.of(context)!.recently_ended_ucf
    ];
    
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
  
  Widget _buildActivityList(List<dynamic> activities, String type) {
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
        title = AppLocalizations.of(context)!.no_outbid_activities;
        subtitle = AppLocalizations.of(context)!.no_outbid_subtitle;
        break;
      case "winning":
        icon = "🏆";
        title = AppLocalizations.of(context)!.no_winning_bids;
        subtitle = AppLocalizations.of(context)!.no_winning_subtitle;
        break;
      case "ended":
        icon = "⏰";
        title = AppLocalizations.of(context)!.no_ended_auctions;
        subtitle = AppLocalizations.of(context)!.no_ended_subtitle;
        break;
      default:
        icon = "📭";
        title = AppLocalizations.of(context)!.no_activity_found;
        subtitle = AppLocalizations.of(context)!.no_activity_subtitle;
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(dynamic activity) {
    final isOutbid = activity['status'] == 'outbid' && !activity['isAuctionEnded'];
    final isWinning = activity['status'] == 'winning' && !activity['isAuctionEnded'];
    final isWon = activity['status'] == 'won' && activity['isAuctionEnded'];
    final isEnded = activity['status'] == 'ended' && activity['isAuctionEnded'];
    
    String statusText;
    Color statusColor = MyTheme.dark_font_grey;
    
    if (isOutbid) {
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      statusColor = MyTheme.dark_font_grey;
    } else if (isWinning) {
      statusText = AppLocalizations.of(context)!.currently_winning;
      statusColor = MyTheme.dark_font_grey;
    } else if (isWon) {
      statusText = AppLocalizations.of(context)!.you_won_auction;
      statusColor = MyTheme.dark_font_grey;
    } else {
      statusText = AppLocalizations.of(context)!.auction_ended;
      statusColor = MyTheme.dark_font_grey;
    }
    
    final timeLeft = activity['endDate'] != null 
        ? (_timeLeft[activity['id']] ?? AppLocalizations.of(context)!.loading)
        : AppLocalizations.of(context)!.ended_ucf;
    final isTimerEnded = timeLeft == AppLocalizations.of(context)!.ended_ucf;
    
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
                  child: activity['productImage'] != null && activity['productImage'].toString().isNotEmpty
                      ? Image.network(
                          activity['productImage'],
                          fit: BoxFit.cover,
                          width: 120,
                          height: 140,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.inventory_2,
                                size: 50,
                                color: Color(0xFF94A3B8),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.inventory_2,
                            size: 50,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                ),
                // Timer Badge
                if (activity['endDate'] != null)
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
                      ? 'Someone placed a higher bid on ${activity['productName']}'
                      : isWinning
                          ? AppLocalizations.of(context)!.winning_message(activity['productName'])
                          : isWon
                              ? AppLocalizations.of(context)!.won_message(activity['productName'])
                              : AppLocalizations.of(context)!.lost_message(activity['productName']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF80818B),
                  ),
                ),
                const SizedBox(height: 8),
                // Bid Label
                Text(
                  isWon || isEnded 
                      ? AppLocalizations.of(context)!.final_bid
                      : AppLocalizations.of(context)!.current_bid,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF80818B),
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
                            AppLocalizations.of(context)!.bid_points(activity['pointsPerBid']),
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
                  _buildViewDetailsButton(activity['productId'])
                else if (isEnded)
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOutbidButton(dynamic activity) {
    return GestureDetector(
      onTap: () {
        // Navigate to bid again
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bid_again_message(activity['productName'])),
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
          AppLocalizations.of(context)!.bid_again,
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
  
  Widget _buildViewDetailsButton(int? productId) {
    return GestureDetector(
      onTap: () {
        if (productId != null) {
          // Navigate to product details page
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(productId: productId)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View product #$productId details'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: MyTheme.accent_color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          AppLocalizations.of(context)!.view_details,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}