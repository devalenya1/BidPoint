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
  
  void _removeFromWishlist(int wishlistId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.remove_from_wishlist,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.are_you_sure_remove_from_wishlist,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.remove_ucf),
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
        AppLocalizations.of(context)!.removed_from_wishlist,
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    }
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
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
      body: Column(
        children: [
          // Top Header
          _buildTopHeader(),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Tabs Section
                    _buildTabs(),
                    const SizedBox(height: 16),
                    
                    // Tab Content
                    if (currentItems.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: currentItems.map((item) => 
                          _buildActivityCard(item)
                        ).toList(),
                      ),
                    
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
  
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEEF2F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel/Back Button
          GestureDetector(
            onTap: _navigateBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
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
            AppLocalizations.of(context)!.all_favorites,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          // Invisible placeholder for balance
          const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  Widget _buildTabs() {
    final tabs = [
      AppLocalizations.of(context)!.all_ucf,
      AppLocalizations.of(context)!.live_ucf,
      AppLocalizations.of(context)!.ending_soon_ucf,
      AppLocalizations.of(context)!.outbid_ucf,
    ];
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEEF2F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
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
                  tabs[index],
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
  
  Widget _buildActivityCard(Map<String, dynamic> item) {
    final isEnded = item['isEnded'];
    final isOutbid = item['isOutbid'] == true;
    final isWinning = item['isWinning'] == true;
    final isEndingSoon = item['isEndingSoon'] == true;
    final timeLeft = _timeLeft[item['id']] ?? AppLocalizations.of(context)!.loading;
    final isTimerEnded = timeLeft == AppLocalizations.of(context)!.ended_ucf;
    
    String statusText;
    if (isEnded) {
      statusText = AppLocalizations.of(context)!.auction_has_ended;
    } else if (isOutbid) {
      statusText = AppLocalizations.of(context)!.someone_placed_higher_bid;
    } else if (isWinning) {
      statusText = AppLocalizations.of(context)!.you_are_currently_winning;
    } else if (isEndingSoon) {
      statusText = AppLocalizations.of(context)!.ending_soon_place_your_bid;
    } else {
      statusText = AppLocalizations.of(context)!.place_your_bid_now;
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                // Status Text
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOutbid || isEnded 
                        ? const Color(0xFF64748B) 
                        : (isWinning ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(height: 8),
                // Bid Label
                Text(
                  AppLocalizations.of(context)!.current_bid,
                  style: const TextStyle(
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
                        '${AppLocalizations.of(context)!.one_bid} = ${_formatPrice(item['pointsPerBid'])}',
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
                if (!isEnded)
                  _buildBidNowButton(item)
                else
                  _buildViewDetailsButton(item),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBidNowButton(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details
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
          AppLocalizations.of(context)!.bid_now,
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
  
  Widget _buildViewDetailsButton(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details
        ToastComponent.showDialog(
          'View details of ${item['productName']}',
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
          AppLocalizations.of(context)!.view_details,
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
  
  Widget _buildEmptyState() {
    String icon;
    String text;
    String subtext;
    
    switch (_selectedTab) {
      case 1:
        icon = '🎯';
        text = AppLocalizations.of(context)!.no_live_auction;
        subtext = AppLocalizations.of(context)!.check_back_later_for_active_auctions;
        break;
      case 2:
        icon = '⏰';
        text = AppLocalizations.of(context)!.no_auctions_ending_soon;
        subtext = AppLocalizations.of(context)!.check_back_later_for_ending_auctions;
        break;
      case 3:
        icon = '🏆';
        text = AppLocalizations.of(context)!.no_outbid_items;
        subtext = AppLocalizations.of(context)!.you_are_currently_winning_all_bids;
        break;
      default:
        icon = '❤️';
        text = AppLocalizations.of(context)!.no_item_in_wishlist;
        subtext = AppLocalizations.of(context)!.add_products_to_wishlist_to_see_here;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.only(top: 20),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
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