import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({Key? key}) : super(key: key);

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  int _selectedTab = 0; // 0: All, 1: Live, 2: Ending Soon, 3: Outbid
  
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;
  
  // Processed wishlist data
  List<WishlistItem> _wishlistItems = [];
  List<WishlistItem> _liveItems = [];
  List<WishlistItem> _endingSoonItems = [];
  List<WishlistItem> _outbidItems = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchWishlistData();
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
  
  // ============ FETCH DATA FROM API ============
  Future<void> _fetchWishlistData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await _profileRepository.getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        _processWishlistData();
        
        wishlist_count.$ = _userInfo?.wishlistCount ?? 0;
        wishlist_count.save();
      } else {
        setState(() {
          _wishlistItems = [];
          _liveItems = [];
          _endingSoonItems = [];
          _outbidItems = [];
        });
      }
    } catch (e) {
      print("Error loading wishlist data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_wishlist);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PROCESS WISHLIST DATA ============
  void _processWishlistData() {
    if (_userInfo == null) return;
    
    final wishlist = _userInfo!.wishlist ?? [];
    
    List<WishlistItem> allItems = [];
    List<WishlistItem> live = [];
    List<WishlistItem> endingSoon = [];
    List<WishlistItem> outbid = [];
    
    final now = DateTime.now();
    
    for (var item in wishlist) {
      // Use API data directly
      final isLive = item.isLive ?? false;
      final isEndingSoon = item.endingSoon ?? false;
      final isOutbid = item.outbid ?? false;
      final isAuction = item.isAuction ?? false;
      
      // Add to all items
      allItems.add(item);
      
      // Categorize based on API data
      if (isAuction && isLive) {
        live.add(item);
      }
      
      if (isAuction && isEndingSoon && isLive) {
        endingSoon.add(item);
      }
      
      if (isAuction && isOutbid && isLive) {
        outbid.add(item);
      }
    }
    
    // Sort all items by created_at (newest first)
    allItems.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    live.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    endingSoon.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    outbid.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _wishlistItems = allItems;
      _liveItems = live;
      _endingSoonItems = endingSoon;
      _outbidItems = outbid;
    });
  }
  
  // ============ PULL TO REFRESH ============
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetails(slug: slug),
        ),
      );
    } else {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.product_details_not_available,
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    }
  }
  
  // ============ REMOVE FROM WISHLIST ============
  Future<void> _removeFromWishlist(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppLocalizations.of(context)!.remove_from_wishlist,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.remove_from_wishlist_confirmation,
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizations.of(context)!.remove_ucf,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final response = await ProfileRepository().removeFromWishlist(productId);
        
        if (response['success'] == true) {
          setState(() {
            _wishlistItems.removeWhere((item) => item.productId == productId);
            _liveItems.removeWhere((item) => item.productId == productId);
            _endingSoonItems.removeWhere((item) => item.productId == productId);
            _outbidItems.removeWhere((item) => item.productId == productId);
          });
          
          wishlist_count.$ = _wishlistItems.length;
          wishlist_count.save();
          
          ToastComponent.showSuccess(
            response['message'] ?? AppLocalizations.of(context)!.removed_from_wishlist,
            gravity: Toast.center,
            duration: Toast.lengthShort,
          );
        } else {
          ToastComponent.showError(
            response['message'] ?? AppLocalizations.of(context)!.failed_to_remove_from_wishlist,
            gravity: Toast.center,
            duration: Toast.lengthShort,
          );
        }
      } catch (e) {
        print("Error removing from wishlist: $e");
        ToastComponent.showError(AppLocalizations.of(context)!.failed_to_remove_from_wishlist);
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
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.all_favorite,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : isLargeScreen 
                ? _buildDesktopTabletBody()
                : _buildBody(),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final shimmerCount = isTablet ? 6 : 3;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          margin: EdgeInsets.only(bottom: 16.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => 
                Container(
                  margin: EdgeInsets.only(right: 4.w),
                  width: isTablet ? 120.w : 100.w,
                  height: isTablet ? 48.h : 42.h,
                  decoration: BoxDecoration(
                    color: MyTheme.shimmer_base,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.w : 16.w),
            child: isTablet
                ? Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: List.generate(shimmerCount, (index) => 
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80.w) / 2,
                        child: ShimmerHelper().buildBasicShimmer(
                          height: 180.h, 
                          radius: 16.r,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(shimmerCount, (index) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: ShimmerHelper().buildBasicShimmer(height: 140.h, radius: 16.r),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  // ============ MOBILE BODY ============
  Widget _buildBody() {
    final currentItems = _getCurrentItems();
    
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                if (currentItems.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    children: currentItems.map((item) => 
                      _buildWishlistCard(item)
                    ).toList(),
                  ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // ============ TABLET/DESKTOP BODY ============
  Widget _buildDesktopTabletBody() {
    final currentItems = _getCurrentItems();
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                if (currentItems.isEmpty)
                  _buildEmptyState()
                else
                  Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: currentItems.map((item) => 
                      SizedBox(
                        width: (screenWidth - 80.w) / 2,
                        child: _buildWishlistCard(item),
                      ),
                    ).toList(),
                  ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // ============ TABS ============
  Widget _buildTabs() {
    final tabs = [
      '${AppLocalizations.of(context)!.all_ucf} (${_wishlistItems.length})',
      '${AppLocalizations.of(context)!.live_ucf} (${_liveItems.length})',
      '${AppLocalizations.of(context)!.ending_soon_ucf} (${_endingSoonItems.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidItems.length})',
    ];
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.w : 16.w),
      margin: EdgeInsets.only(bottom: 16.h),
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
                margin: EdgeInsets.only(right: 4.w),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.w : 20.w,
                  vertical: isTablet ? 12.h : 10.h,
                ),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: isTablet ? 15.sp : 13.sp,
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
  
  // ============ WISHLIST CARD ============
  Widget _buildWishlistCard(WishlistItem item) {
    final timeLeft = _timeLeft[item.id] ?? AppLocalizations.of(context)!.loading;
    final isTimerEnded = timeLeft == AppLocalizations.of(context)!.ended_ucf;
    
    final int pointPerBid = item.pointPerBid ?? 10;
    
    // Use API data directly
    final bool isLive = item.isLive ?? false;
    final bool isEndingSoon = item.endingSoon ?? false;
    final bool isOutbid = item.outbid ?? false;
    final bool isWinning = item.isWinning ?? false;
    final bool isAuction = item.isAuction ?? false;
    
    // Determine status text and description
    String statusText;
    String descriptionText = '';
    Color statusColor = Colors.black;
    
    // Determine the primary status for display
    if (!isAuction) {
      // Non-auction product
      statusText = AppLocalizations.of(context)!.regular_product;
    } else if (!isLive) {
      // Auction has ended (not live)
      statusText = AppLocalizations.of(context)!.auction_has_ended;
    } else if (isOutbid && isLive) {
      // Live and outbid
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      descriptionText = AppLocalizations.of(context)!.someone_placed_higher_bid_on;
    } else if (isWinning && isLive) {
      // Live and winning
      statusText = AppLocalizations.of(context)!.currently_winning;
      descriptionText = AppLocalizations.of(context)!.your_bid_highest_on;
    } else {
      // Default
      statusText = AppLocalizations.of(context)!.place_your_bid_now;
    }
    
    // Show "Ending Soon" badge if applicable
    final bool showEndingSoonBadge = isAuction && isLive && isEndingSoon;
    
    final String productSlug = item.slug ?? '';
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final imageSize = isTablet ? 120.w : 100.w;
    final imageHeight = isTablet ? 140.h : 120.h;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(isTablet ? 14.w : 10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image - Clickable
          GestureDetector(
            onTap: () {
              if (productSlug.isNotEmpty) {
                _navigateToProductDetails(productSlug);
              } else {
                ToastComponent.showWarning(
                  AppLocalizations.of(context)!.product_details_not_available,
                  gravity: Toast.center,
                  duration: Toast.lengthShort,
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  width: imageSize,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: item.productImage != null && item.productImage!.isNotEmpty
                        ? Image.network(
                            item.productImage!,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageHeight,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFE2E8F0),
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 40.sp,
                                  color: const Color(0xFF94A3B8),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.inventory_2,
                              size: 40.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                ),
                // "Ending Soon" Badge
                if (showEndingSoonBadge)
                  Positioned(
                    top: 4.w,
                    left: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.ending_soon_ucf,
                        style: TextStyle(
                          fontSize: isTablet ? 8.sp : 7.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Remove from wishlist - FULL HEART (black)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(item.productId!),
                    child: Container(
                      width: isTablet ? 32.w : 28.w,
                      height: isTablet ? 32.w : 28.w,
                      margin: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: isTablet ? 16.sp : 14.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 14.w : 10.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name - Clickable
                GestureDetector(
                  onTap: () {
                    if (productSlug.isNotEmpty) {
                      _navigateToProductDetails(productSlug);
                    }
                  },
                  child: Text(
                    item.productName ?? AppLocalizations.of(context)!.unknown_product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 15.sp : 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                // Status Text - Black
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isTablet ? 12.sp : 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                // Description Text (if any)
                if (descriptionText.isNotEmpty && isAuction)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      descriptionText,
                      style: TextStyle(
                        fontSize: isTablet ? 10.sp : 9.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF80818B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(height: 6.h),
                // Bid Label
                Text(
                  isLive && isAuction 
                      ? AppLocalizations.of(context)!.current_bid
                      : AppLocalizations.of(context)!.final_bid,
                  style: TextStyle(
                    fontSize: isTablet ? 10.sp : 9.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2.h),
                // Bid Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _formatPrice(item.highestBid ?? item.productPrice ?? 0),
                        style: TextStyle(
                          fontSize: isTablet ? 18.sp : 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E7F5),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.bid_points(pointPerBid),
                        style: TextStyle(
                          fontSize: isTablet ? 10.sp : 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0092AC),
                        ),
                      ),
                    ),
                  ],
                ),
                // Show time remaining if live
                if (isAuction && isLive && item.auctionEndDate != null && item.auctionEndDate!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: isTablet ? 12.sp : 10.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${AppLocalizations.of(context)!.time_left}: ${_timeLeft[item.id] ?? AppLocalizations.of(context)!.loading}',
                          style: TextStyle(
                            fontSize: isTablet ? 10.sp : 9.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8.h),
                // Action Button - White with accent border and text
                GestureDetector(
                  onTap: () {
                    if (productSlug.isNotEmpty) {
                      _navigateToProductDetails(productSlug);
                    } else {
                      ToastComponent.showWarning(
                        AppLocalizations.of(context)!.product_details_not_available,
                        gravity: Toast.center,
                        duration: Toast.lengthShort,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 10.h : 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: MyTheme.accent_color, width: 1.w),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Text(
                      isAuction && isLive 
                          ? AppLocalizations.of(context)!.bid_now
                          : AppLocalizations.of(context)!.view_details,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 12.sp : 11.sp,
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
  
  // ============ EMPTY STATE ============
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
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isTablet ? 80.h : 60.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: isTablet ? 64.sp : 48.sp)),
          SizedBox(height: 16.h),
          Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 18.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            subtext,
            style: TextStyle(
              fontSize: isTablet ? 14.sp : 12.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}