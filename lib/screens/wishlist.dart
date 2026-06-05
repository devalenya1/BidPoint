import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/custom/useful_elements.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/wishlist_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:toast/toast.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({Key? key}) : super(key: key);

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  int _selectedTab = 0; // 0: All, 1: Live, 2: Ending Soon, 3: Outbid
  
  // Demo wishlist data
  List<Map<String, dynamic>> _wishlistItems = [];
  List<Map<String, dynamic>> _liveItems = [];
  List<Map<String, dynamic>> _endingSoonItems = [];
  List<Map<String, dynamic>> _outbidItems = [];
  
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
    final now = DateTime.now();
    final endingSoonThreshold = now.add(const Duration(days: 2));
    
    _wishlistItems = [
      {
        'id': 1,
        'wishlistId': 101,
        'productId': 1001,
        'productName': 'Vintage Rolex Watch - Limited Edition',
        'productImage': null,
        'auctionEndDate': now.add(const Duration(days: 5, hours: 2)),
        'currentBid': 1350.00,
        'userBid': 1250.00,
        'pointsPerBid': 10,
        'isEnded': false,
      },
      {
        'id': 2,
        'wishlistId': 102,
        'productId': 1002,
        'productName': 'iPhone 15 Pro Max - 1TB',
        'productImage': null,
        'auctionEndDate': now.add(const Duration(days: 1, hours: 3)),
        'currentBid': 850.00,
        'userBid': 850.00,
        'pointsPerBid': 15,
        'isEnded': false,
      },
      {
        'id': 3,
        'wishlistId': 103,
        'productId': 1003,
        'productName': 'Samsung Galaxy S24 Ultra',
        'productImage': null,
        'auctionEndDate': now.add(const Duration(hours: 12)),
        'currentBid': 620.00,
        'userBid': 620.00,
        'pointsPerBid': 12,
        'isEnded': false,
      },
      {
        'id': 4,
        'wishlistId': 104,
        'productId': 1004,
        'productName': 'MacBook Pro M3 Max',
        'productImage': null,
        'auctionEndDate': now.add(const Duration(days: 3)),
        'currentBid': 1950.00,
        'userBid': 1950.00,
        'pointsPerBid': 20,
        'isEnded': false,
      },
      {
        'id': 5,
        'wishlistId': 105,
        'productId': 1005,
        'productName': 'Sony PlayStation 5',
        'productImage': null,
        'auctionEndDate': now.add(const Duration(days: 5)),
        'currentBid': 480.00,
        'userBid': 450.00,
        'pointsPerBid': 8,
        'isEnded': false,
      },
      {
        'id': 6,
        'wishlistId': 106,
        'productId': 1006,
        'productName': 'Canon EOS R5 Camera',
        'productImage': null,
        'auctionEndDate': now.subtract(const Duration(days: 1)),
        'currentBid': 2800.00,
        'userBid': 2800.00,
        'pointsPerBid': 25,
        'isEnded': true,
      },
      {
        'id': 7,
        'wishlistId': 107,
        'productId': 1007,
        'productName': 'Nike Air Jordan 1 Retro',
        'productImage': null,
        'auctionEndDate': now.subtract(const Duration(days: 2)),
        'currentBid': 350.00,
        'userBid': 320.00,
        'pointsPerBid': 5,
        'isEnded': true,
      },
    ];
    
    // Filter items for different tabs
    for (var item in _wishlistItems) {
      final endDate = item['auctionEndDate'] as DateTime;
      final isEnded = endDate.isBefore(now);
      final isEndingSoon = !isEnded && endDate.isBefore(endingSoonThreshold);
      final isOutbid = !isEnded && (item['userBid'] < item['currentBid']);
      
      item['isEnded'] = isEnded;
      item['isEndingSoon'] = isEndingSoon;
      item['isOutbid'] = isOutbid;
      item['isWinning'] = !isEnded && !isOutbid && (item['userBid'] == item['currentBid']);
      
      // Add to filtered lists
      if (!isEnded) {
        _liveItems.add(item);
        if (isEndingSoon) {
          _endingSoonItems.add(item);
        }
        if (isOutbid) {
          _outbidItems.add(item);
        }
      }
    }
    
    // Start timers for non-ended items
    for (var item in _wishlistItems) {
      if (!item['isEnded']) {
        _startTimer(item['id'], item['auctionEndDate']);
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
      if (mounted) {
        setState(() {
          _timeLeft[id] = "Ended";
        });
      }
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
    
    if (mounted) {
      setState(() {
        _timeLeft[id] = timeString;
      });
    }
  }
  
  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
  
  void _removeFromWishlist(int wishlistId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove from Wishlist',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to remove this item from your wishlist?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _wishlistItems.removeWhere((item) => item['wishlistId'] == wishlistId);
        _liveItems.removeWhere((item) => item['wishlistId'] == wishlistId);
        _endingSoonItems.removeWhere((item) => item['wishlistId'] == wishlistId);
        _outbidItems.removeWhere((item) => item['wishlistId'] == wishlistId);
      });
      
      ToastComponent.showDialog(
        'Removed from wishlist',
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    }
  }
  
  List<Map<String, dynamic>> _getCurrentItems() {
    switch (_selectedTab) {
      case 1:
        return _liveItems;
      case 2:
        return _endingSoonItems;
      case 3:
        return _outbidItems;
      default:
        return _wishlistItems;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentItems = _getCurrentItems();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'All Favorites',
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
      body: Column(
        children: [
          // Tabs Section
          _buildTabs(),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Tab Content
                  if (currentItems.isEmpty)
                    _buildEmptyState()
                  else
                    Column(
                      children: currentItems.map((item) => 
                        _buildWishlistCard(item)
                      ).toList(),
                    ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabs() {
    final tabs = [
      'All',
      'Live',
      'Ending Soon',
      'Outbid',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildWishlistCard(Map<String, dynamic> item) {
    final isEnded = item['isEnded'];
    final isOutbid = item['isOutbid'] == true;
    final isWinning = item['isWinning'] == true;
    final timeLeft = _timeLeft[item['id']] ?? 'Loading...';
    final isTimerEnded = timeLeft == "Ended";
    
    String statusText;
    if (isEnded) {
      statusText = 'Auction has ended';
    } else if (isOutbid) {
      statusText = 'You were outbid! Someone placed a higher bid';
    } else if (isWinning) {
      statusText = 'You are currently winning this auction';
    } else {
      statusText = 'Place your bid now';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
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
              ),
              // Timer Badge
              if (!isEnded)
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
              // Remove from wishlist button
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _removeFromWishlist(item['wishlistId']),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5E7F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  item['productName'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                // Status Text
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOutbid 
                        ? const Color(0xFFDC2626)
                        : (isWinning ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(height: 8),
                // Bid Label
                const Text(
                  'Current bid',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Bid Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatPrice(item['currentBid']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '1 Bid = ${item['pointsPerBid']}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0092AC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Button
                GestureDetector(
                  onTap: () {
                    ToastComponent.showDialog(
                      'Navigate to ${item['productName']}',
                      gravity: Toast.center,
                      duration: Toast.lengthShort,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: MyTheme.accent_color, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEnded ? 'View Details' : 'Bid Now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String icon;
    String text;
    String subtext;
    
    switch (_selectedTab) {
      case 1:
        icon = '🎯';
        text = 'No live auctions';
        subtext = 'Check back later for active auctions';
        break;
      case 2:
        icon = '⏰';
        text = 'No auctions ending soon';
        subtext = 'Check back later for ending auctions';
        break;
      case 3:
        icon = '🏆';
        text = 'No outbid items';
        subtext = 'You are currently winning all your bids';
        break;
      default:
        icon = '❤️';
        text = 'No items in wishlist';
        subtext = 'Add products to wishlist to see them here';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
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
}