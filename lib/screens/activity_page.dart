import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
 
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: All, 1: Outbid, 2: Winning, 3: Recently Ended
  
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;
  
  // Processed activity data
  List<AuctionBid> _allActivities = [];
  List<AuctionBid> _outbidActivities = [];
  List<AuctionBid> _winningActivities = [];
  List<AuctionBid> _endedActivities = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchActivityData();
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
  Future<void> _fetchActivityData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        _processActivityData();
        
        auction_bids_count.$ = _userInfo?.auctionBidsCount ?? 0;
        auction_bids_count.save();
        distinct_auction_bids_count.$ = _userInfo?.distinctAuctionBidsCount ?? 0;
        distinct_auction_bids_count.save();
      } else {
        setState(() {
          _allActivities = [];
          _outbidActivities = [];
          _winningActivities = [];
          _endedActivities = [];
        });
      }
    } catch (e) {
      print("Error loading activities: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_activities);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PROCESS ACTIVITY DATA ============
  void _processActivityData() {
    if (_userInfo == null) return;
    
    final auctionBids = _userInfo!.auctionBids ?? [];
    final distinctAuctionBids = _userInfo!.distinctAuctionBids ?? [];
    
    final Map<int, DistinctAuctionBid> productInfoMap = {};
    for (var product in distinctAuctionBids) {
      if (product.productId != null) {
        productInfoMap[product.productId!] = product;
      }
    }
    
    final Map<int, List<AuctionBid>> bidsByProduct = {};
    for (var bid in auctionBids) {
      if (bid.productId != null) {
        bidsByProduct.putIfAbsent(bid.productId!, () => []).add(bid);
      }
    }
    
    List<AuctionBid> allActivities = [];
    List<AuctionBid> outbid = [];
    List<AuctionBid> winning = [];
    List<AuctionBid> ended = [];
    
    for (var entry in bidsByProduct.entries) {
      final productId = entry.key;
      final userBids = entry.value;
      final productInfo = productInfoMap[productId];
      
      if (productInfo == null) continue;
      
      final userHighestBid = userBids.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
      final productHighestBid = productInfo.amount ?? 0.0;
      
      final isEnded = false;
      String status;
      
      if (isEnded) {
        status = 'ended';
      } else if (userHighestBid > 0 && userHighestBid < productHighestBid) {
        status = 'outbid';
      } else if (userHighestBid >= productHighestBid && userHighestBid > 0) {
        status = 'winning';
      } else {
        status = 'pending';
      }
      
      final latestBid = userBids.last;
      
      allActivities.add(latestBid);
      
      if (status == 'outbid' && !isEnded) {
        outbid.add(latestBid);
      } else if (status == 'winning' && !isEnded) {
        winning.add(latestBid);
      } else if (isEnded) {
        ended.add(latestBid);
      }
    }
    
    setState(() {
      _allActivities = allActivities;
      _outbidActivities = outbid;
      _winningActivities = winning;
      _endedActivities = ended;
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchActivityData();
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
  
  String _formatPrice(double price) {
    return FormatHelper.formatPrice(price);
  }
  
  // ============ PRODUCT DATA HELPERS ============
  DistinctAuctionBid? _getProductInfoForBid(AuctionBid bid) {
    if (_userInfo?.distinctAuctionBids == null || bid.productId == null) return null;
    
    try {
      final product = _userInfo!.distinctAuctionBids!.firstWhere(
        (p) => p.productId == bid.productId,
      );
      return product;
    } catch (e) {
      return null;
    }
  }

  String _getProductNameForBid(AuctionBid bid) {
    final product = _getProductInfoForBid(bid);
    if (product != null && product.productName != null && product.productName!.isNotEmpty) {
      return product.productName!;
    }
    if (bid.productName != null && bid.productName!.isNotEmpty) {
      return bid.productName!;
    }
    return AppLocalizations.of(context)!.unknown_product;
  }

  String? _getProductImageForBid(AuctionBid bid) {
    final product = _getProductInfoForBid(bid);
    if (product != null && product.productImage != null && product.productImage!.isNotEmpty) {
      return product.productImage;
    }
    if (bid.productImage != null && bid.productImage!.isNotEmpty) {
      return bid.productImage;
    }
    return null;
  }

  String _getProductSlugForBid(AuctionBid bid) {
    final product = _getProductInfoForBid(bid);
    if (product != null && product.productSlug != null && product.productSlug!.isNotEmpty) {
      return product.productSlug!;
    }
    return '';
  }

  double _getCurrentBidForProduct(int productId) {
    final product = _getProductInfoById(productId);
    if (product != null) {
      return product.amount ?? 0.0;
    }
    return 0.0;
  }

  double _getUserHighestBidForProduct(int productId) {
    if (_userInfo?.auctionBids == null) return 0.0;
    
    final userBids = _userInfo!.auctionBids!.where((b) => b.productId == productId).toList();
    if (userBids.isEmpty) return 0.0;
    
    return userBids.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
  }

  int _getPointPerBidForProduct(int productId) {
    if (_userInfo?.auctionBids == null) return 10;
    
    final userBids = _userInfo!.auctionBids!.where((b) => b.productId == productId).toList();
    if (userBids.isEmpty) return 10;
    
    return userBids.first.pointPerBid ?? 10;
  }

  DistinctAuctionBid? _getProductInfoById(int productId) {
    if (_userInfo?.distinctAuctionBids == null) return null;
    
    try {
      final product = _userInfo!.distinctAuctionBids!.firstWhere(
        (p) => p.productId == productId,
      );
      return product;
    } catch (e) {
      return null;
    }
  }

  double _getCurrentBidById(int productId) {
    final product = _getProductInfoById(productId);
    if (product != null) {
      return product.amount ?? 0.0;
    }
    return 0.0;
  }
  
  List<AuctionBid> _getCurrentActivities() {
    switch (_selectedTab) {
      case 1:
        return _outbidActivities;
      case 2:
        return _winningActivities;
      case 3:
        return _endedActivities;
      default:
        return _allActivities;
    }
  }
  
  // ============ NAVIGATION HELPERS ============
  void _navigateToProductDetails(String productSlug) {
    if (productSlug.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetails(slug: productSlug),
        ),
      );
    } else {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_details_not_available,
      );
    }
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.activity_ucf,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Main(initialIndex: 0),
                ),
              );
            }
          },
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : _buildBody(),
      ),
    );
  }
  
  Widget _buildShimmer() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          margin: EdgeInsets.only(bottom: 16.h),
          child: Row(
            children: List.generate(4, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 42.h,
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: List.generate(3, (index) => 
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
  
  Widget _buildBody() {
    final currentActivities = _getCurrentActivities();
    
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                if (currentActivities.isEmpty)
                  _buildEmptyState(_selectedTab)
                else
                  Column(
                    children: currentActivities.map((activity) => 
                      _buildActivityCard(activity)
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
  
  Widget _buildTabs() {
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.all_ucf} (${_allActivities.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidActivities.length})',
      '${AppLocalizations.of(context)!.winning_ucf} (${_winningActivities.length})',
      '${AppLocalizations.of(context)!.recently_ended_ucf} (${_endedActivities.length})'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabNames.length, (index) {
            final isActive = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 4.w), // ✅ Closer tabs
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), // ✅ Reduced padding
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabNames[index],
                  style: TextStyle(
                    fontSize: 13.sp, // ✅ Slightly smaller font
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
  
  Widget _buildEmptyState(int tabIndex) {
    String icon;
    String title;
    String subtitle;
    
    switch (tabIndex) {
      case 1:
        icon = "🎯";
        title = AppLocalizations.of(context)!.no_outbid_activities;
        subtitle = AppLocalizations.of(context)!.no_outbid_subtitle;
        break;
      case 2:
        icon = "🏆";
        title = AppLocalizations.of(context)!.no_winning_bids;
        subtitle = AppLocalizations.of(context)!.no_winning_subtitle;
        break;
      case 3:
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
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 48.sp)),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(AuctionBid activity) {
    final productId = activity.productId ?? 0;
    final productName = _getProductNameForBid(activity);
    final productImage = _getProductImageForBid(activity);
    final productSlug = _getProductSlugForBid(activity);
    final userHighestBid = _getUserHighestBidForProduct(productId);
    final currentBid = _getCurrentBidById(productId);
    final pointPerBid = _getPointPerBidForProduct(productId);
    
    final isOutbid = userHighestBid > 0 && userHighestBid < currentBid;
    final isWinning = userHighestBid >= currentBid && userHighestBid > 0;
    final isEnded = false;
    
    // ✅ All status text in BLACK (no colored text)
    String statusText;
    Color statusColor = Colors.black; // ✅ All black
    
    if (isOutbid && !isEnded) {
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      statusColor = Colors.black;
    } else if (isWinning && !isEnded) {
      statusText = AppLocalizations.of(context)!.currently_winning;
      statusColor = Colors.black;
    } else if (isEnded && isWinning) {
      statusText = AppLocalizations.of(context)!.you_won_auction;
      statusColor = Colors.black;
    } else {
      statusText = AppLocalizations.of(context)!.auction_ended;
      statusColor = Colors.black;
    }
    
    // ✅ Description text based on status (matches HTML)
    String descriptionText;
    if (isOutbid && !isEnded) {
      descriptionText = 'Someone placed a higher bid on $productName';
    } else if (isWinning && !isEnded) {
      descriptionText = 'Your bid is currently the highest on $productName';
    } else if (isEnded && isWinning) {
      descriptionText = 'Congratulations! You won $productName';
    } else if (isEnded && !isWinning) {
      descriptionText = 'You didn\'t win $productName';
    } else {
      descriptionText = productName;
    }
    
    final timeLeft = _timeLeft[productId] ?? AppLocalizations.of(context)!.loading;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
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
              }
            },
            child: Container(
              width: 100.w, // ✅ Smaller width
              height: 120.h, // ✅ Smaller height
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: productImage != null && productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        width: 100.w,
                        height: 120.h,
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
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Text - Black
                Text(
                  statusText, 
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black, // ✅ Always black
                  ),
                ),
                SizedBox(height: 4.h),
                
                // ✅ Description Text (matches HTML)
                Text(
                  descriptionText,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF80818B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                
                // Current Bid Label
                Text(
                  isEnded 
                      ? AppLocalizations.of(context)!.final_bid
                      : AppLocalizations.of(context)!.current_bid,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF80818B),
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Bid Amount and Points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _formatPrice(currentBid),
                        style: TextStyle(
                          fontSize: 16.sp, // ✅ Slightly smaller
                          fontWeight: FontWeight.w800,
                          color: MyTheme.dark_font_grey,
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
                        '1 Bid = $pointPerBid',
                        style: TextStyle(
                          fontSize: 9.sp, // ✅ Smaller font
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0092AC),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                
                // Action Button - All with accent color background and white text
                if (isOutbid && !isEnded)
                  _buildBidAgainButton(productSlug)
                else if (isWinning && !isEnded)
                  _buildViewDetailsButton(productSlug, isWinning: true)
                else if (isEnded && isWinning)
                  _buildViewDetailsButton(productSlug, isWinning: true)
                else if (isEnded && !isWinning)
                  Container() // No button for ended/outbid
                else
                  _buildViewDetailsButton(productSlug, isWinning: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBidAgainButton(String productSlug) {
    return GestureDetector(
      onTap: () {
        if (productSlug.isNotEmpty) {
          _navigateToProductDetails(productSlug);
        } else {
          ToastComponent.showDialog(
            AppLocalizations.of(context)!.product_details_not_available
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: MyTheme.accent_color, // ✅ Accent color background
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Text(
          AppLocalizations.of(context)!.bid_again,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white, // ✅ White text
          ),
        ),
      ),
    );
  }
  
  Widget _buildViewDetailsButton(String productSlug, {bool isWinning = false}) {
    return GestureDetector(
      onTap: () {
        if (productSlug.isNotEmpty) {
          _navigateToProductDetails(productSlug);
        } else {
          ToastComponent.showDialog(
            AppLocalizations.of(context)!.product_details_not_available
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: MyTheme.accent_color, // ✅ Accent color background
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Text(
          isWinning ? AppLocalizations.of(context)!.view_details : AppLocalizations.of(context)!.view_details,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white, // ✅ White text
          ),
        ),
      ),
    );
  }
}