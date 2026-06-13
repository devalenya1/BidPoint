import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'dart:async';

// Import the data model
import '../data_model/user_info_response.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: All, 1: Outbid, 2: Winning, 3: Recently Ended
  
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;  // Store the complete user info response
  
  // Processed activity data (derived from _userInfo)
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
      _fetchActivityData();  // Fetch fresh data from API
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
  Future<void> _fetchActivityData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally like _productDetails
        });
        
        // Process activity data from the stored user info
        _processActivityData();
        
        // Optional: Update global SharedValues for counts
        auction_bids_count.$ = _userInfo?.auctionBidsCount ?? 0;
        auction_bids_count.save();
        distinct_auction_bids_count.$ = _userInfo?.distinctAuctionBidsCount ?? 0;
        distinct_auction_bids_count.save();
      } else {
        // Handle empty response
        setState(() {
          _allActivities = [];
          _outbidActivities = [];
          _winningActivities = [];
          _endedActivities = [];
        });
      }
    } catch (e) {
      print("Error loading activities: $e");
      ToastComponent.showDialog('Failed to load activities');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PROCESS ACTIVITY DATA (Extract from stored user info) ============
  void _processActivityData() {
    if (_userInfo == null) return;
    
    final auctionBids = _userInfo!.auctionBids ?? [];
    final distinctAuctionBids = _userInfo!.distinctAuctionBids ?? [];
    
    // Create a map of product info from distinct auction bids
    final Map<int, DistinctAuctionBid> productInfoMap = {};
    for (var product in distinctAuctionBids) {
      if (product.productId != null) {
        productInfoMap[product.productId!] = product;
      }
    }
    
    // Group bids by product
    final Map<int, List<AuctionBid>> bidsByProduct = {};
    for (var bid in auctionBids) {
      if (bid.productId != null) {
        bidsByProduct.putIfAbsent(bid.productId!, () => []).add(bid);
      }
    }
    
    // Process each product the user has bid on
    List<AuctionBid> allActivities = [];
    List<AuctionBid> outbid = [];
    List<AuctionBid> winning = [];
    List<AuctionBid> ended = [];
    
    for (var entry in bidsByProduct.entries) {
      final productId = entry.key;
      final userBids = entry.value;
      final productInfo = productInfoMap[productId];
      
      if (productInfo == null) continue;
      
      // Get user's highest bid
      final userHighestBid = userBids.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
      
      // Get highest bid overall for this product
      final productHighestBid = productInfo.amount ?? 0.0;
      
      // Determine status (would need auction end date from API)
      final isEnded = false; // TODO: Get from product API
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
      
      // Create a wrapped activity object
      // Since we don't have a direct model, we'll use the bid with additional info
      final latestBid = userBids.last;
      
      allActivities.add(latestBid);
      
      if (status == 'outbid' && !isEnded) {
        outbid.add(latestBid);
      } else if (status == 'winning' && !isEnded) {
        winning.add(latestBid);
      } else if (isEnded) {
        ended.add(latestBid);
      }
      
      // Start timer if needed (would need end date)
      // if (productInfo.auctionEndDate != null && !isEnded) {
      //   _startTimer(productId, productInfo.auctionEndDate!);
      // }
    }
    
    setState(() {
      _allActivities = allActivities;
      _outbidActivities = outbid;
      _winningActivities = winning;
      _endedActivities = ended;
    });
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
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
  
  // Helper to get product name for a bid
  String _getProductNameForBid(AuctionBid bid) {
    if (_userInfo?.distinctAuctionBids == null) return 'Unknown Product';
    
    final product = _userInfo!.distinctAuctionBids!.firstWhere(
      (p) => p.productId == bid.productId,
      orElse: () => DistinctAuctionBid(),
    );
    return product.productName ?? 'Unknown Product';
  }
  
  // Helper to get product image for a bid
  String? _getProductImageForBid(AuctionBid bid) {
    if (_userInfo?.distinctAuctionBids == null) return null;
    
    final product = _userInfo!.distinctAuctionBids!.firstWhere(
      (p) => p.productId == bid.productId,
      orElse: () => DistinctAuctionBid(),
    );
    return product.productImage;
  }
  
  // Helper to get current bid for a product
  double _getCurrentBidForProduct(int productId) {
    if (_userInfo?.distinctAuctionBids == null) return 0.0;
    
    final product = _userInfo!.distinctAuctionBids!.firstWhere(
      (p) => p.productId == productId,
      orElse: () => DistinctAuctionBid(),
    );
    return product.amount ?? 0.0;
  }
  
  // Helper to get user's highest bid for a product
  double _getUserHighestBidForProduct(int productId) {
    if (_userInfo?.auctionBids == null) return 0.0;
    
    final userBids = _userInfo!.auctionBids!.where((b) => b.productId == productId).toList();
    if (userBids.isEmpty) return 0.0;
    
    return userBids.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
  }
  
  // Helper to get product slug for navigation
  String? _getProductSlugForBid(AuctionBid bid) {
    if (_userInfo?.distinctAuctionBids == null) return null;
    
    final product = _userInfo!.distinctAuctionBids!.firstWhere(
      (p) => p.productId == bid.productId,
      orElse: () => DistinctAuctionBid(),
    );
    return null; // Would need slug from API
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
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
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
          child: Row(
            children: List.generate(4, (index) => 
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
    final currentActivities = _getCurrentActivities();
    
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (currentActivities.isEmpty)
                  _buildEmptyState(_selectedTab)
                else
                  Column(
                    children: currentActivities.map((activity) => 
                      _buildActivityCard(activity)
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
    final List<String> tabNames = [
      '${AppLocalizations.of(context)!.all_ucf} (${_allActivities.length})',
      '${AppLocalizations.of(context)!.outbid_ucf} (${_outbidActivities.length})',
      '${AppLocalizations.of(context)!.winning_ucf} (${_winningActivities.length})',
      '${AppLocalizations.of(context)!.recently_ended_ucf} (${_endedActivities.length})'
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
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
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  tabNames[index],
                  style: TextStyle(
                    fontSize: 14,
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
  
  Widget _buildActivityCard(AuctionBid activity) {
    final productId = activity.productId ?? 0;
    final productName = _getProductNameForBid(activity);
    final productImage = _getProductImageForBid(activity);
    final productSlug = _getProductSlugForBid(activity);
    final userHighestBid = _getUserHighestBidForProduct(productId);
    final currentBid = _getCurrentBidForProduct(productId);
    
    // Determine status
    final isOutbid = userHighestBid > 0 && userHighestBid < currentBid;
    final isWinning = userHighestBid >= currentBid && userHighestBid > 0;
    final isEnded = false; // TODO: Get from API
    
    String statusText;
    Color statusColor = MyTheme.dark_font_grey;
    
    if (isOutbid && !isEnded) {
      statusText = AppLocalizations.of(context)!.you_were_outbid;
      statusColor = const Color(0xFFDC2626);
    } else if (isWinning && !isEnded) {
      statusText = AppLocalizations.of(context)!.currently_winning;
      statusColor = const Color(0xFF10B981);
    } else if (isEnded && isWinning) {
      statusText = AppLocalizations.of(context)!.you_won_auction;
      statusColor = const Color(0xFF10B981);
    } else {
      statusText = AppLocalizations.of(context)!.auction_ended;
      statusColor = const Color(0xFF64748B);
    }
    
    final timeLeft = _timeLeft[productId] ?? AppLocalizations.of(context)!.loading;
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
                  child: productImage != null && productImage.isNotEmpty
                      ? Image.network(
                          productImage,
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
                // Timer Badge (would need end date)
                // Remove from wishlist button is not needed here
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
                  isOutbid && !isEnded
                      ? 'Someone placed a higher bid on $productName'
                      : isWinning && !isEnded
                          ? 'You are currently winning $productName'
                          : isEnded && isWinning
                              ? 'Congratulations! You won $productName'
                              : 'Auction ended for $productName',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF80818B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Bid Label
                Text(
                  isEnded 
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
                      _formatPrice(currentBid),
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
                            '1 Bid = 10',
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
                if (isOutbid && !isEnded)
                  _buildBidAgainButton(productSlug, productName)
                else if (isWinning || (isEnded && isWinning))
                  _buildViewDetailsButton(productSlug),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBidAgainButton(String? productSlug, String productName) {
    return GestureDetector(
      onTap: () {
        if (productSlug != null && productSlug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetails(slug: productSlug),
            ),
          );
        } else {
          ToastComponent.showDialog('Product details not available');
        }
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
  
  Widget _buildViewDetailsButton(String? productSlug) {
    return GestureDetector(
      onTap: () {
        if (productSlug != null && productSlug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetails(slug: productSlug),
            ),
          );
        } else {
          ToastComponent.showDialog('Product details not available');
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