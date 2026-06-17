import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/wishlist_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';
import 'package:go_router/go_router.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({Key? key}) : super(key: key);

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  int _selectedTab = 0; // 0: All, 1: Live, 2: Ending Soon, 3: Outbid
  
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;  // Store the complete user info response
  
  // Processed wishlist data (derived from _userInfo)
  List<WishlistItem> _wishlistItems = [];
  List<WishlistItem> _liveItems = [];
  List<WishlistItem> _endingSoonItems = [];
  List<WishlistItem> _outbidItems = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchWishlistData();  // Fetch fresh data from API
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
  
  // ============ FETCH DATA FROM API (Like ProductDetails) ============
  Future<void> _fetchWishlistData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally like _productDetails
        });
        
        // Process wishlist data from the stored user info
        _processWishlistData();
        
        // Optional: Update global SharedValue for wishlist count
        wishlist_count.$ = _userInfo?.wishlistCount ?? 0;
        wishlist_count.save();
      } else {
        // Handle empty response
        setState(() {
          _wishlistItems = [];
          _liveItems = [];
          _endingSoonItems = [];
          _outbidItems = [];
        });
      }
    } catch (e) {
      print("Error loading wishlist data: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_wishlist);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PROCESS WISHLIST DATA (Extract from stored user info) ============
  void _processWishlistData() {
    if (_userInfo == null) return;
    
    final wishlist = _userInfo!.wishlist ?? [];
    final now = DateTime.now();
    final endingSoonThreshold = now.add(const Duration(days: 2));
    
    // Process and categorize wishlist items
    List<WishlistItem> allItems = [];
    List<WishlistItem> live = [];
    List<WishlistItem> endingSoon = [];
    List<WishlistItem> outbid = [];
    
    for (var item in wishlist) {
      // Determine auction status
      final isEnded = false; // Would need auction end date from API
      final isOutbid = false; // Would need to compare user bid with current bid
      
      allItems.add(item);
      
      if (!isEnded) {
        live.add(item);
      }
      
      if (isOutbid && !isEnded) {
        outbid.add(item);
      }
    }
    
    setState(() {
      _wishlistItems = allItems;
      _liveItems = live;
      _endingSoonItems = endingSoon;
      _outbidItems = outbid;
    });
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchWishlistData();
  }
  
  // ============ TIMER HELPERS ============
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
          _timeLeft[id] = AppLocalizations.of(context)!.ended_ucf;
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
  
  String _formatPrice(dynamic price) {
    if (price == null) return FormatHelper.formatPrice(0);
    if (price is double) return FormatHelper.formatPrice(price);
    if (price is int) return FormatHelper.formatPrice(price.toDouble());
    return FormatHelper.formatPrice(double.tryParse(price.toString()) ?? 0);
  }
  
  // ============ NAVIGATION HELPERS ============
  void _navigateToProductDetails(String slug) {
    if (slug.isNotEmpty) {
      // Using GoRouter for proper navigation
      context.go('/product/$slug');
    } else {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_details_not_available,
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    }
  }
  
  void _navigateToAuctionProductDetails(String slug) {
    if (slug.isNotEmpty) {
      // Using GoRouter for proper navigation to auction product
      context.go('/auction-product/$slug');
    } else {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_details_not_available,
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    }
  }
  
  // ============ REMOVE FROM WISHLIST ============
  Future<void> _removeFromWishlist(int wishlistId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.remove_from_wishlist,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.remove_from_wishlist_confirmation,
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
      try {
        // TODO: Call API to remove from wishlist
        // await WishlistRepository().removeFromWishlist(wishlistId);
        
        setState(() {
          _wishlistItems.removeWhere((item) => item.id == wishlistId);
          _liveItems.removeWhere((item) => item.id == wishlistId);
          _endingSoonItems.removeWhere((item) => item.id == wishlistId);
          _outbidItems.removeWhere((item) => item.id == wishlistId);
        });
        
        // Update wishlist count in SharedPreferences
        wishlist_count.$ = _wishlistItems.length;
        wishlist_count.save();
        
        ToastComponent.showDialog(
          AppLocalizations.of(context)!.removed_from_wishlist,
          gravity: Toast.center,
          duration: Toast.lengthShort,
        );
      } catch (e) {
        print("Error removing from wishlist: $e");
        ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_remove_from_wishlist);
      }
    }
  }
  
  List<WishlistItem> _getCurrentItems() {
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
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.all_favorite,
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
            ? _buildShimmer()  // Show shimmer while loading
            : _buildBody(),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return Column(
      children: [
        // Tabs shimmer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => 
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 100,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MyTheme.shimmer_base,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Cards shimmer
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(3, (index) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShimmerHelper().buildBasicShimmer(height: 140, radius: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // ============ MAIN BODY ============
  Widget _buildBody() {
    final currentItems = _getCurrentItems();
    
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
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
    );
  }
  
  Widget _buildTabs() {
    final tabs = [
      '${AppLocalizations.of(context)!.all_ucf} (${_wishlistItems.length})',
      '${AppLocalizations.of(context)!.live_ucf} (${_liveItems.length})',
      '${AppLocalizations.of(context)!.ending_soon_ucf} (${_endingSoonItems.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidItems.length})',
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
  
  Widget _buildWishlistCard(WishlistItem item) {
    final timeLeft = _timeLeft[item.id] ?? AppLocalizations.of(context)!.loading;
    final isTimerEnded = timeLeft == AppLocalizations.of(context)!.ended_ucf;
    
    // Get point per bid from API (real value)
    final int pointPerBid = item.pointPerBid ?? 10;
    
    // Determine status
    final isEnded = false; // Would need auction end date
    final isOutbid = false; // Would need comparison
    final isWinning = !isEnded && !isOutbid;
    
    String statusText;
    Color statusColor;
    
    if (isEnded) {
      statusText = AppLocalizations.of(context)!.auction_has_ended;
      statusColor = const Color(0xFF64748B);
    } else if (isOutbid) {
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      statusColor = const Color(0xFFDC2626);
    } else if (isWinning) {
      statusText = AppLocalizations.of(context)!.currently_winning;
      statusColor = const Color(0xFF10B981);
    } else {
      statusText = AppLocalizations.of(context)!.place_your_bid_now;
      statusColor = const Color(0xFFF59E0B);
    }
    
    // Determine if this is an auction product
    final bool isAuctionProduct = item.isAuction ?? false;
    final String productSlug = item.slug ?? '';
    
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
          // Product Image - Clickable
          GestureDetector(
            onTap: () {
              if (productSlug.isNotEmpty) {
                if (isAuctionProduct) {
                  _navigateToAuctionProductDetails(productSlug);
                } else {
                  _navigateToProductDetails(productSlug);
                }
              } else {
                ToastComponent.showDialog(
                  AppLocalizations.of(context)!.product_details_not_available,
                  gravity: Toast.center,
                  duration: Toast.lengthShort,
                );
              }
            },
            child: Stack(
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
                    child: item.productImage != null && item.productImage!.isNotEmpty
                        ? Image.network(
                            item.productImage!,
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
                ),
                // Remove from wishlist button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(item.id!),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB5E7F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Auction badge
                if (isAuctionProduct)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.auction_ucf,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name - Clickable
                GestureDetector(
                  onTap: () {
                    if (productSlug.isNotEmpty) {
                      if (isAuctionProduct) {
                        _navigateToAuctionProductDetails(productSlug);
                      } else {
                        _navigateToProductDetails(productSlug);
                      }
                    }
                  },
                  child: Text(
                    item.productName ?? AppLocalizations.of(context)!.unknown_product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Status Text
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
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
                      _formatPrice(item.highestBid ?? item.productPrice ?? 0),
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
                        AppLocalizations.of(context)!.bid_points(pointPerBid),
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
                    if (productSlug.isNotEmpty) {
                      if (isAuctionProduct) {
                        _navigateToAuctionProductDetails(productSlug);
                      } else {
                        _navigateToProductDetails(productSlug);
                      }
                    } else {
                      ToastComponent.showDialog(
                        AppLocalizations.of(context)!.product_details_not_available,
                        gravity: Toast.center,
                        duration: Toast.lengthShort,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isAuctionProduct ? MyTheme.accent_color : Colors.white,
                      border: Border.all(color: MyTheme.accent_color, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAuctionProduct 
                          ? (isEnded ? AppLocalizations.of(context)!.view_details : AppLocalizations.of(context)!.bid_now)
                          : AppLocalizations.of(context)!.view_details,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAuctionProduct ? Colors.white : MyTheme.accent_color,
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
        text = AppLocalizations.of(context)!.no_live_auctions;
        subtext = AppLocalizations.of(context)!.no_live_auctions_subtext;
        break;
      case 2:
        icon = '⏰';
        text = AppLocalizations.of(context)!.no_ending_soon_auctions;
        subtext = AppLocalizations.of(context)!.no_ending_soon_auctions_subtext;
        break;
      case 3:
        icon = '🏆';
        text = AppLocalizations.of(context)!.no_outbid_items;
        subtext = AppLocalizations.of(context)!.no_outbid_items_subtext;
        break;
      default:
        icon = '❤️';
        text = AppLocalizations.of(context)!.no_items_in_wishlist;
        subtext = AppLocalizations.of(context)!.no_items_in_wishlist_subtext;
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
            textAlign: TextAlign.center,
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