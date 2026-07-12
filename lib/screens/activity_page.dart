import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
 
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  // ============ PARENT TABS ============
  int _selectedParentTab = 0; // 0: Bids, 1: Purchases, 2: Favorites
  
  // ============ CHILD TABS ============
  int _selectedBidTab = 0; // 0: All, 1: Outbid, 2: Winning, 3: Recently Ended
  int _selectedPurchaseTab = 0; // 0: In Progress, 1: Completed
  
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;
  
  // ============ PAGINATION STATE ============
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 20;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  // Processed activity data
  List<AuctionBid> _allActivities = [];
  List<AuctionBid> _outbidActivities = [];
  List<AuctionBid> _winningActivities = [];
  List<AuctionBid> _endedActivities = [];
  
  // ============ PURCHASE DATA ============
  List<AuctionBid> _inProgressActivities = [];
  List<AuctionBid> _completedActivities = [];
  
  // ============ WISHLIST DATA (Reused from Wishlist page) ============
  List<WishlistItem> _wishlistItems = [];
  List<WishlistItem> _liveItems = [];
  List<WishlistItem> _endingSoonItems = [];
  List<WishlistItem> _outbidWishlistItems = [];
  List<WishlistItem> _recentlyEndedWishlistItems = [];
  
  // Timer controllers
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  
  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchAllData();
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
  
  // ============ FETCH ALL DATA ============
  Future<void> _fetchAllData({bool loadMore = false}) async {
    try {
      if (loadMore) {
        if (_isLoadingMore || !_hasMore) return;
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _currentPage = 1;
          _hasMore = true;
          _allActivities.clear();
          _outbidActivities.clear();
          _winningActivities.clear();
          _endedActivities.clear();
          _inProgressActivities.clear();
          _completedActivities.clear();
          _wishlistItems.clear();
          _liveItems.clear();
          _endingSoonItems.clear();
          _outbidWishlistItems.clear();
          _recentlyEndedWishlistItems.clear();
        });
      }

      final page = loadMore ? _currentPage + 1 : 1;
      
      var response = await _profileRepository.getUserInfoResponse(
        notificationPage: 1,
        notificationPerPage: 10,
        pointPage: 1,
        pointPerPage: 10,
        cashPage: 1,
        cashPerPage: 10,
        withdrawPage: 1,
        withdrawPerPage: 10,
        auctionBidPage: page,
        auctionBidPerPage: _perPage,
        wishlistPage: page,
        wishlistPerPage: _perPage,
      );
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final newUserInfo = response.data![0];
        
        // Update pagination info
        final pagination = newUserInfo.auctionBidsPagination;
        if (pagination != null) {
          _currentPage = pagination.currentPage;
          _totalPages = pagination.totalPages;
          _totalItems = pagination.total;
          _perPage = pagination.perPage;
          _hasMore = pagination.hasNext;
        }
        
        setState(() {
          if (loadMore) {
            final newBids = newUserInfo.auctionBids ?? [];
            _allActivities.addAll(newBids);
            _wishlistItems.addAll(newUserInfo.wishlist ?? []);
          } else {
            _userInfo = newUserInfo;
            _allActivities = newUserInfo.auctionBids ?? [];
            _wishlistItems = newUserInfo.wishlist ?? [];
          }
        });
        
        _processActivityData();
        _processPurchaseData();
        _processWishlistData();
        
        auction_bids_count.$ = _userInfo?.auctionBidsCount ?? 0;
        auction_bids_count.save();
        distinct_auction_bids_count.$ = _userInfo?.distinctAuctionBidsCount ?? 0;
        distinct_auction_bids_count.save();
        wishlist_count.$ = _userInfo?.wishlistCount ?? 0;
        wishlist_count.save();
      } else {
        if (!loadMore) {
          setState(() {
            _allActivities = [];
            _outbidActivities = [];
            _winningActivities = [];
            _endedActivities = [];
            _inProgressActivities = [];
            _completedActivities = [];
            _wishlistItems = [];
            _liveItems = [];
            _endingSoonItems = [];
            _outbidWishlistItems = [];
            _recentlyEndedWishlistItems = [];
          });
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_activities);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
      });
    }
  }
  
  // ============ LOAD MORE ============
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await _fetchAllData(loadMore: true);
  }
  
  // ============ PROCESS ACTIVITY DATA ============
  void _processActivityData() {
    if (_userInfo == null) return;
    
    final Map<int, AuctionBid> latestBidsByProduct = {};
    for (var bid in _allActivities) {
      if (bid.productId != null) {
        final existing = latestBidsByProduct[bid.productId!];
        if (existing == null || (bid.createdAt != null && existing.createdAt != null && bid.createdAt!.isAfter(existing.createdAt!))) {
          latestBidsByProduct[bid.productId!] = bid;
        }
      }
    }
    
    List<AuctionBid> outbid = [];
    List<AuctionBid> winning = [];
    List<AuctionBid> ended = [];
    
    for (var entry in latestBidsByProduct.entries) {
      final latestBid = entry.value;
      final isEnded = latestBid.recentlyEnded ?? false;
      final isWinning = latestBid.isWinning ?? false;
      final isHighestBidder = latestBid.highestBidder ?? false;
      final hasBid = (latestBid.amount ?? 0) > 0;
      
      if (isEnded) {
        ended.add(latestBid);
      } else if (isWinning || isHighestBidder) {
        winning.add(latestBid);
      } else if (!isWinning && !isHighestBidder && hasBid) {
        outbid.add(latestBid);
      }
    }
    
    _allActivities.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    outbid.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    winning.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    ended.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _outbidActivities = outbid;
      _winningActivities = winning;
      _endedActivities = ended;
    });
  }
  
  // ============ PROCESS PURCHASE DATA ============
  void _processPurchaseData() {
    if (_userInfo == null) return;
    
    final allBids = _allActivities;
    
    List<AuctionBid> inProgress = [];
    List<AuctionBid> completed = [];
    
    for (var bid in allBids) {
      // Only show won auctions (isWinning == true)
      if (bid.isWinning == true) {
        final status = bid.activityStatus ?? 0;
        if (status == 0) {
          inProgress.add(bid);
        } else if (status == 1) {
          completed.add(bid);
        }
      }
    }
    
    inProgress.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    completed.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _inProgressActivities = inProgress;
      _completedActivities = completed;
    });
  }
  
  // ============ PROCESS WISHLIST DATA ============
  void _processWishlistData() {
    if (_userInfo == null) return;
    
    List<WishlistItem> live = [];
    List<WishlistItem> endingSoon = [];
    List<WishlistItem> outbid = [];
    List<WishlistItem> recentlyEnded = [];
    
    for (var item in _wishlistItems) {
      final isLive = item.isLive ?? false;
      final isEndingSoon = item.endingSoon ?? false;
      final isOutbid = item.outbid ?? false;
      final isAuction = item.isAuction ?? false;
      
      if (isAuction && !isLive) {
        recentlyEnded.add(item);
      } else if (isAuction && isLive) {
        live.add(item);
        if (isEndingSoon) endingSoon.add(item);
        if (isOutbid) outbid.add(item);
      }
    }
    
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
    
    recentlyEnded.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _liveItems = live;
      _endingSoonItems = endingSoon;
      _outbidWishlistItems = outbid;
      _recentlyEndedWishlistItems = recentlyEnded;
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchAllData(loadMore: false);
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
  
  // ============ GET CURRENT ITEMS ============
  List<AuctionBid> _getCurrentBidItems() {
    switch (_selectedBidTab) {
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
  
  List<AuctionBid> _getCurrentPurchaseItems() {
    switch (_selectedPurchaseTab) {
      case 1:
        return _completedActivities;
      default:
        return _inProgressActivities;
    }
  }
  
  List<WishlistItem> _getCurrentWishlistItems() {
    switch (_selectedBidTab) {
      case 1:
        return _liveItems;
      case 2:
        return _endingSoonItems;
      case 3:
        return _outbidWishlistItems;
      default:
        return _wishlistItems;
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
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.product_details_not_available,
      );
    }
  }
  
  void _openPayWebView(String payLink, String productName) {
    if (payLink.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommonWebviewScreen(
            url: payLink,
            page_name: '${AppLocalizations.of(context)!.pay_for} $productName',
          ),
        ),
      );
    } else {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.payment_link_not_available,
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
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoadingMore &&
                      _hasMore &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                    _loadMore();
                  }
                  return true;
                },
                child: _buildBody(),
              ),
      ),
    );
  }
  
  Widget _buildShimmer() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          margin: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: List.generate(3, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  height: 38.h,
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
    return Column(
      children: [
        _buildParentTabs(),
        Expanded(
          child: SingleChildScrollView(
            controller: ScrollController(),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                if (_selectedParentTab == 0)
                  _buildBidContent()
                else if (_selectedParentTab == 1)
                  _buildPurchaseContent()
                else
                  _buildFavoriteContent(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // ============ PARENT TABS ============
  Widget _buildParentTabs() {
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.bids_ucf} (${_allActivities.length})',
      '${AppLocalizations.of(context)!.purchases_ucf} (${_inProgressActivities.length + _completedActivities.length})',
      '${AppLocalizations.of(context)!.favorites_ucf} (${_wishlistItems.length})'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      margin: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: List.generate(tabNames.length, (index) {
          final isActive = _selectedParentTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedParentTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabNames[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
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
  
  // ============ BID CONTENT ============
  Widget _buildBidContent() {
    final currentActivities = _getCurrentBidItems();
    
    return Column(
      children: [
        _buildBidTabs(),
        if (currentActivities.isEmpty)
          _buildEmptyState(_selectedBidTab, 'bid')
        else
          Column(
            children: [
              ...currentActivities.map((activity) => 
                _buildActivityCard(activity, 'bid')
              ).toList(),
              if (_isLoadingMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Center(
                    child: SizedBox(
                      height: 24.w,
                      width: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ),
              if (!_hasMore && currentActivities.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 30.h),
                  child: Text(
                    AppLocalizations.of(context)!.no_more_activities,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildBidTabs() {
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.all_ucf} (${_allActivities.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidActivities.length})',
      '${AppLocalizations.of(context)!.winning_ucf} (${_winningActivities.length})',
      '${AppLocalizations.of(context)!.recently_ended_ucf} (${_endedActivities.length})'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      margin: EdgeInsets.only(bottom: 6.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabNames.length, (index) {
            final isActive = _selectedBidTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBidTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 3.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabNames[index],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
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
  
  // ============ PURCHASE CONTENT ============
  Widget _buildPurchaseContent() {
    final currentActivities = _getCurrentPurchaseItems();
    
    return Column(
      children: [
        _buildPurchaseTabs(),
        if (currentActivities.isEmpty)
          _buildEmptyState(_selectedPurchaseTab, 'purchase')
        else
          Column(
            children: [
              ...currentActivities.map((activity) => 
                _buildActivityCard(activity, 'purchase')
              ).toList(),
              if (_isLoadingMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Center(
                    child: SizedBox(
                      height: 24.w,
                      width: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ),
              if (!_hasMore && currentActivities.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 30.h),
                  child: Text(
                    AppLocalizations.of(context)!.no_more_activities,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildPurchaseTabs() {
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.in_progress_ucf} (${_inProgressActivities.length})',
      '${AppLocalizations.of(context)!.completed_ucf} (${_completedActivities.length})'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      margin: EdgeInsets.only(bottom: 6.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabNames.length, (index) {
            final isActive = _selectedPurchaseTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPurchaseTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 3.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabNames[index],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
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
  
  // ============ FAVORITE CONTENT ============
  Widget _buildFavoriteContent() {
    final currentItems = _getCurrentWishlistItems();
    
    return Column(
      children: [
        _buildFavoriteTabs(),
        if (currentItems.isEmpty)
          _buildEmptyState(_selectedBidTab, 'favorite')
        else
          Column(
            children: [
              ...currentItems.map((item) => 
                _buildWishlistCard(item)
              ).toList(),
              if (_isLoadingMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Center(
                    child: SizedBox(
                      height: 24.w,
                      width: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
                ),
              if (!_hasMore && currentItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 30.h),
                  child: Text(
                    AppLocalizations.of(context)!.no_more_items,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildFavoriteTabs() {
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.all_ucf} (${_wishlistItems.length})',
      '${AppLocalizations.of(context)!.live_ucf} (${_liveItems.length})',
      '${AppLocalizations.of(context)!.ending_soon_ucf} (${_endingSoonItems.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidWishlistItems.length})'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      margin: EdgeInsets.only(bottom: 6.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabNames.length, (index) {
            final isActive = _selectedBidTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBidTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 3.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabNames[index],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
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
  
  // ============ EMPTY STATE ============
  Widget _buildEmptyState(int tabIndex, String type) {
    String icon;
    String title;
    String subtitle;
    
    if (type == 'bid') {
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
    } else if (type == 'purchase') {
      if (tabIndex == 1) {
        icon = "✅";
        title = AppLocalizations.of(context)!.no_completed_purchases;
        subtitle = AppLocalizations.of(context)!.no_completed_purchases_subtitle;
      } else {
        icon = "🔄";
        title = AppLocalizations.of(context)!.no_in_progress_purchases;
        subtitle = AppLocalizations.of(context)!.no_in_progress_subtitle;
      }
    } else {
      switch (tabIndex) {
        case 1:
          icon = "🎯";
          title = AppLocalizations.of(context)!.no_live_auctions;
          subtitle = AppLocalizations.of(context)!.no_live_auctions_subtext;
          break;
        case 2:
          icon = "⏰";
          title = AppLocalizations.of(context)!.no_ending_soon_auctions;
          subtitle = AppLocalizations.of(context)!.no_ending_soon_auctions_subtext;
          break;
        case 3:
          icon = "🏆";
          title = AppLocalizations.of(context)!.no_outbid_items;
          subtitle = AppLocalizations.of(context)!.no_outbid_items_subtext;
          break;
        default:
          icon = "❤️";
          title = AppLocalizations.of(context)!.no_items_in_wishlist;
          subtitle = AppLocalizations.of(context)!.no_items_in_wishlist_subtext;
      }
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
  
  // ============ ACTIVITY CARD ============
  Widget _buildActivityCard(AuctionBid activity, String type) {
    final productId = activity.productId ?? 0;
    final productName = _getProductNameForBid(activity);
    final productImage = _getProductImageForBid(activity);
    final productSlug = _getProductSlugForBid(activity);
    final pointPerBid = _getPointPerBidForProduct(productId);
    final payLink = activity.payLink ?? '';
    
    final isEnded = activity.recentlyEnded ?? false;
    final isWinning = activity.isWinning ?? false;
    final isHighestBidder = activity.highestBidder ?? false;
    final currentBid = activity.highestBid ?? 0.0;
    final hasBid = (activity.amount ?? 0) > 0;
    
    final isWonStatus = isEnded && isWinning;
    final isLostStatus = isEnded && !isWinning;
    final isWinningStatus = !isEnded && isWinning;
    final isOutbidStatus = !isEnded && !isWinning;
    
    String statusText;
    String descriptionText;
    bool showWinLossIcon = false;
    String winLossIcon = '';
    String buttonText = '';
    VoidCallback? buttonAction;
    
    if (type == 'purchase') {
      // Purchase tab - only won auctions
      final status = activity.activityStatus ?? 0;
      if (status == 0) {
        statusText = AppLocalizations.of(context)!.in_progress_ucf;
        descriptionText = AppLocalizations.of(context)!.awaiting_payment;
        buttonText = AppLocalizations.of(context)!.pay_receive;
        buttonAction = () => _openPayWebView(payLink, productName);
      } else {
        statusText = AppLocalizations.of(context)!.completed_ucf;
        descriptionText = AppLocalizations.of(context)!.purchase_completed;
        buttonText = AppLocalizations.of(context)!.view_details;
        buttonAction = () => _navigateToProductDetails(productSlug);
      }
    } else {
      // Bid tab
      if (isWonStatus) {
        statusText = AppLocalizations.of(context)!.you_won_auction;
        descriptionText = AppLocalizations.of(context)!.congratulations_you_won;
        showWinLossIcon = true;
        winLossIcon = '🏆';
        buttonText = AppLocalizations.of(context)!.view_details;
        buttonAction = () => _navigateToProductDetails(productSlug);
      } else if (isLostStatus) {
        statusText = AppLocalizations.of(context)!.auction_ended;
        descriptionText = AppLocalizations.of(context)!.you_didnt_win;
        showWinLossIcon = true;
        winLossIcon = '❌';
        buttonText = AppLocalizations.of(context)!.view_details;
        buttonAction = () => _navigateToProductDetails(productSlug);
      } else if (isOutbidStatus) {
        statusText = AppLocalizations.of(context)!.you_were_outbid;
        descriptionText = AppLocalizations.of(context)!.someone_placed_higher_bid_on;
        buttonText = AppLocalizations.of(context)!.bid_again;
        buttonAction = () => _navigateToProductDetails(productSlug);
      } else if (isWinningStatus) {
        statusText = AppLocalizations.of(context)!.currently_winning;
        descriptionText = AppLocalizations.of(context)!.your_bid_highest_on;
        buttonText = AppLocalizations.of(context)!.view_product;
        buttonAction = () => _navigateToProductDetails(productSlug);
      } else {
        statusText = '';
        descriptionText = '';
        buttonText = AppLocalizations.of(context)!.view_details;
        buttonAction = () => _navigateToProductDetails(productSlug);
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.only(
        right: 12.w,
        left: 0.w,
        top: 0.w,
        bottom: 0.w,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          GestureDetector(
            onTap: () {
              if (productSlug.isNotEmpty) {
                _navigateToProductDetails(productSlug);
              }
            },
            child: Container(
              width: 120.w,
              height: 150.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                child: productImage != null && productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        width: 120.w,
                        height: 150.h,
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
            child: Padding(
              padding: EdgeInsets.only(
                left: 12.w,
                top: 10.h,
                bottom: 10.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Text
                  Text(
                    statusText, 
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  
                  // Description Text
                  if (descriptionText.isNotEmpty)
                    Text(
                      descriptionText,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  // Product Name
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  
                  // Current Bid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type == 'purchase' 
                                  ? AppLocalizations.of(context)!.final_bid
                                  : (isEnded 
                                      ? AppLocalizations.of(context)!.final_bid
                                      : AppLocalizations.of(context)!.current_bid),
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF80818B),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _formatPrice(currentBid),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: MyTheme.dark_font_grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (showWinLossIcon)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isWonStatus ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isWonStatus ? Colors.green.shade200 : Colors.red.shade200,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                winLossIcon,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                isWonStatus ? "WON" : "LOST",
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isWonStatus ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (type != 'purchase' && !isEnded)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB5E7F5),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            '${AppLocalizations.of(context)!.one_bid_equals} $pointPerBid',
                            style: TextStyle(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0092AC),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  
                  // Action Button
                  if (buttonAction != null)
                    GestureDetector(
                      onTap: buttonAction,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: MyTheme.accent_color,
                          borderRadius: BorderRadius.circular(7.r),
                        ),
                        child: Text(
                          buttonText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============ WISHLIST CARD ============
  Widget _buildWishlistCard(WishlistItem item) {
    final timeLeft = _timeLeft[item.id] ?? AppLocalizations.of(context)!.loading;
    final int pointPerBid = item.pointPerBid ?? 10;
    
    final bool isLive = item.isLive ?? false;
    final bool isEndingSoon = item.endingSoon ?? false;
    final bool isOutbid = item.outbid ?? false;
    final bool isWinning = item.isWinning ?? false;
    final bool isAuction = item.isAuction ?? false;
    
    final bool isWon = !isLive && isWinning;
    final bool isLost = !isLive && !isWinning && isAuction;
    final bool isRecentlyEnded = !isLive && isAuction;
    
    String statusText;
    String descriptionText = '';
    bool showWinLossIcon = false;
    String winLossIcon = '';
    String buttonText;
    VoidCallback buttonAction;
    
    if (isRecentlyEnded) {
      if (isWon) {
        statusText = AppLocalizations.of(context)!.you_won_auction;
        descriptionText = AppLocalizations.of(context)!.congratulations_you_won;
        showWinLossIcon = true;
        winLossIcon = '🏆';
      } else if (isLost) {
        statusText = AppLocalizations.of(context)!.auction_ended;
        descriptionText = AppLocalizations.of(context)!.you_didnt_win;
        showWinLossIcon = true;
        winLossIcon = '❌';
      } else {
        statusText = AppLocalizations.of(context)!.auction_has_ended;
      }
    } else if (!isAuction) {
      statusText = AppLocalizations.of(context)!.view_details;
    } else if (isOutbid && isLive) {
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      descriptionText = AppLocalizations.of(context)!.someone_placed_higher_bid_on;
    } else if (isWinning && isLive) {
      statusText = AppLocalizations.of(context)!.currently_winning;
      descriptionText = AppLocalizations.of(context)!.your_bid_highest;
    } else {
      statusText = AppLocalizations.of(context)!.place_your_bid_now;
    }
    
    final bool showEndingSoonBadge = isAuction && isLive && isEndingSoon;
    final String productSlug = item.slug ?? '';
    
    buttonText = AppLocalizations.of(context)!.view_details;
    buttonAction = () {
      if (productSlug.isNotEmpty) {
        _navigateToProductDetails(productSlug);
      }
    };
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.only(
        right: 12.w,
        left: 0.w,
        top: 0.w,
        bottom: 0.w,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          GestureDetector(
            onTap: () {
              if (productSlug.isNotEmpty) {
                _navigateToProductDetails(productSlug);
              }
            },
            child: Container(
              width: 120.w,
              height: 150.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                child: Stack(
                  children: [
                    item.productImage != null && item.productImage!.isNotEmpty
                        ? Image.network(
                            item.productImage!,
                            fit: BoxFit.cover,
                            width: 120.w,
                            height: 150.h,
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
                    if (showEndingSoonBadge)
                      Positioned(
                        top: 8.w,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.ending_soon_ucf,
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12.w,
                top: 10.h,
                bottom: 10.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name with Remove Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
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
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFromWishlist(item.productId!),
                        child: Container(
                          width: 28.w,
                          height: 28.w,
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
                          child: Center(
                            child: Icon(
                              Icons.favorite,
                              size: 14.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  
                  // Status Text
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  
                  // Description Text
                  if (descriptionText.isNotEmpty && isAuction)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descriptionText,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                      ],
                    ),
                  
                  // Current Bid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLive && isAuction 
                            ? AppLocalizations.of(context)!.current_bid
                            : AppLocalizations.of(context)!.final_bid,
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _formatPrice(item.highestBid ?? item.productPrice ?? 0),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showWinLossIcon)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isWon ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isWon ? Colors.green.shade200 : Colors.red.shade200,
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    winLossIcon,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    isWon ? "WON" : "LOST",
                                    style: TextStyle(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isWon ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isAuction && isLive)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB5E7F5),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.bid_points(pointPerBid),
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0092AC),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  
                  // Action Button
                  GestureDetector(
                    onTap: buttonAction,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Text(
                        buttonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            _outbidWishlistItems.removeWhere((item) => item.productId == productId);
            _recentlyEndedWishlistItems.removeWhere((item) => item.productId == productId);
          });
          
          wishlist_count.$ = _wishlistItems.length;
          wishlist_count.save();
          
          ToastComponent.showSuccess(
            response['message'] ?? AppLocalizations.of(context)!.removed_from_wishlist,
          );
        } else {
          ToastComponent.showError(
            response['message'] ?? AppLocalizations.of(context)!.failed_to_remove_from_wishlist,
          );
        }
      } catch (e) {
        print("Error removing from wishlist: $e");
        ToastComponent.showError(AppLocalizations.of(context)!.failed_to_remove_from_wishlist);
      }
    }
  }
}