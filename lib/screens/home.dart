import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/aiz_image.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/home_presenter.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/category_products.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:active_ecommerce_flutter/screens/notifications_page.dart';
import 'package:active_ecommerce_flutter/screens/affiliate_page.dart';
import 'package:active_ecommerce_flutter/ui_elements/hot_auction_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/ending_soon_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/upcoming_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart'; // ADDED for Ended Auctions
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class Home extends StatefulWidget {
  Home({
    Key? key,
    this.title,
    this.show_back_button = false,
    go_back = true,
  }) : super(key: key);

  final String? title;
  bool show_back_button;
  late bool go_back;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  HomePresenter homeData = HomePresenter();
  
  // ============ LOCAL STATE ============
  bool _isLoadingCounts = true;
  bool _isRefreshingCounts = false;
  UserInformation? _userInfo;
  
  // ============================================================
  // UPDATED COUNT LOGIC:
  // - Show NOTHING (no badge) when isLoadingCounts == true
  // - Show count only when isLoadingCounts == false
  // - If count is 0, show 0
  // ============================================================
  int get _unreadNotificationCount {
    if (is_logged_in.$ != true) return 0;
    return _userInfo?.unreadNotificationsCount ?? 0;
  }
  
  int get _unreadMessageCount {
    if (is_logged_in.$ != true) return 0;
    return _userInfo?.unreadMessagesCount ?? 0;
  }
  
  // Badge visibility:
  // - Show ONLY when NOT loading AND logged in AND count > 0
  bool get _shouldShowNotificationBadge {
    if (!is_logged_in.$) return false;
    if (_isLoadingCounts) return false;  // Don't show while loading
    return _unreadNotificationCount > 0;
  }
  
  bool get _shouldShowMessageBadge {
    if (!is_logged_in.$) return false;
    if (_isLoadingCounts) return false;  // Don't show while loading
    return _unreadMessageCount > 0;
  }
  
  // Display text for badge:
  // - Show count only when NOT loading
  // - If count is 0, show "0"
  String get _notificationBadgeText {
    if (_isLoadingCounts) return '';  // Don't show anything while loading
    if (_unreadNotificationCount > 99) return '99+';
    return '$_unreadNotificationCount';
  }
  
  String get _messageBadgeText {
    if (_isLoadingCounts) return '';  // Don't show anything while loading
    if (_unreadMessageCount > 99) return '99+';
    return '$_unreadMessageCount';
  }
  
  @override
  void initState() {
    super.initState();
    _fetchCounts();
    
    Future.delayed(Duration.zero).then((value) {
      change();
    });
  }
  
  Future<void> _fetchCounts() async {
    if (is_logged_in.$ != true) {
      setState(() => _isLoadingCounts = false);
      return;
    }
    
    try {
      setState(() => _isLoadingCounts = true);
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() => _userInfo = response.data![0]);
        unread_notifications_count.$ = _userInfo!.unreadNotificationsCount ?? 0;
        unread_notifications_count.save();
      }
    } catch (e) {
      print("Error loading notification counts: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_notifications);
    } finally {
      setState(() => _isLoadingCounts = false);
    }
  }
  
  Future<void> _refreshCounts() async {
    setState(() => _isRefreshingCounts = true);
    await _fetchCounts();
    setState(() => _isRefreshingCounts = false);
  }

  change() {
    homeData.onRefresh();
  }

  @override
  void dispose() {
    homeData.pirated_logo_controller.dispose();
    super.dispose();
  }

  void _redirectToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Directionality(
        textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60.h),
              child: buildAppBar(),
            ),
            body: ListenableBuilder(
              listenable: homeData,
              builder: (context, child) {
                return RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await homeData.onRefresh();
                    await _refreshCounts();
                  },
                  displacement: 0,
                  child: CustomScrollView(
                    controller: homeData.mainScrollController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: <Widget>[
                      // Carousel Slider
                      SliverList(
                        delegate: SliverChildListDelegate([
                          buildHomeCarouselSlider(),
                          SizedBox(height: 8.h),
                        ]),
                      ),
                      
                      // Featured Categories
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.featured_categories_ucf,
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50.h,
                          child: buildHomeFeaturedCategories(),
                        ),
                      ),
                      
                      // Extra space between Featured Categories and Hot Auction
                      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                      
                      // Hot Auctions Section
                      SliverToBoxAdapter(
                        child: _buildHotAuctionSection(),
                      ),
                      
                      // Ending Soon Section
                      SliverToBoxAdapter(
                        child: _buildEndingSoonSection(),
                      ),

                      // Upcoming Section
                      SliverToBoxAdapter(
                        child: _buildUpcomingSection(),
                      ),

                      // ============================================================
                      // NEW: Ended Auctions Section (using ProductCard)
                      // ============================================================
                      SliverToBoxAdapter(
                        child: _buildEndedAuctionsSection(),
                      ),
                      
                      SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============ HOT AUCTION SECTION ============
  Widget _buildHotAuctionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.hot_auctions_ucf,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'hot-auctions');
                  }));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3), width: 1.w),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.view_all,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF80818B)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (homeData.hotAuctionProductList.isEmpty)
          Container(
            height: 50.h,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_hot_auctions_available,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          )
        else
          _buildStaticHorizontalGrid(
            products: homeData.hotAuctionProductList,
            cardBuilder: (context, product) {
              bool isActive = false;
              if (product.auctionEndDate != null && product.auctionEndDate is int) {
                isActive = product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
              }
              return HotAuctionCard(
                id: product.id ?? 0,
                slug: product.slug ?? '',
                image: product.thumbnailImage,
                name: product.name,
                description: product.description,
                pointPerBid: product.pointPerBid ?? 0,
                auctionEndDate: product.auctionEndDate,
                currentBid: product.highestBid,
                startingBid: product.startingBid,
                isAuctionActive: isActive,
              );
            },
          ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ============ UPCOMING SECTION ============
  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.upcoming_auctions_ucf,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'upcoming-auctions');
                  }));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3), width: 1.w),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.view_all,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF80818B)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (homeData.upcomingProductList.isEmpty)
          Container(
            height: 50.h,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_upcoming_auctions,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          )
        else
          _buildStaticHorizontalGrid(
            products: homeData.upcomingProductList,
            cardBuilder: (context, product) {
              int? auctionStartTimestamp;
              if (product.auctionStartDate != null) {
                if (product.auctionStartDate is int) {
                  auctionStartTimestamp = product.auctionStartDate;
                } else if (product.auctionStartDate is String) {
                  auctionStartTimestamp = int.tryParse(product.auctionStartDate) ?? 0;
                }
              }
              
              return UpcomingCard(
                id: product.id ?? 0,
                slug: product.slug ?? '',
                image: product.thumbnailImage,
                name: product.name,
                description: product.description,
                pointPerBid: product.pointPerBid ?? 0,
                auctionEndDate: auctionStartTimestamp ?? product.auctionStartDate,
                currentBid: product.startingBid,
                startingBid: product.startingBid,
                isAuctionActive: false,
              );
            },
          ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ============ ENDED AUCTIONS SECTION (NEW) ============
  Widget _buildEndedAuctionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.ended_auctions_ucf,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'ended-auctions');
                  }));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3), width: 1.w),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.view_all,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF80818B)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (homeData.endedProductList.isEmpty)
          Container(
            height: 50.h,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_ended_auctions,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          )
        else
          _buildStaticHorizontalGrid(
            products: homeData.endedProductList,
            cardBuilder: (context, product) {
              // Use ProductCard for ended auctions
              return ProductCard(
                id: product.id ?? 0,
                slug: product.slug ?? '',
                image: product.thumbnailImage,
                name: product.name,
                description: product.description,
                pointPerBid: product.pointPerBid ?? 0,
                auctionEndDate: 'Ended', // Mark as ended
                currentBid: product.highestBid,
                startingBid: product.startingBid,
                isAuctionActive: false,
              );
            },
          ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ============ REUSABLE STATIC HORIZONTAL GRID (NO SCROLL) ============
  Widget _buildStaticHorizontalGrid({
    required List products,
    required Widget Function(BuildContext, dynamic) cardBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many items to show based on screen width
        int itemsToShow;
        double cardWidth;
        
        if (constraints.maxWidth >= 1024) {
          // Desktop: Show 6 items
          itemsToShow = 6;
          cardWidth = (constraints.maxWidth - 16.w * 7) / 6;
        } else if (constraints.maxWidth >= 768) {
          // Tablet: Show 4 items
          itemsToShow = 4;
          cardWidth = (constraints.maxWidth - 16.w * 5) / 4;
        } else {
          // Mobile: Show 2 items
          itemsToShow = 2;
          cardWidth = (constraints.maxWidth - 16.w * 3) / 2;
        }
        
        cardWidth = cardWidth.clamp(120.w, double.infinity);
        
        // Show only up to itemsToShow products
        final displayProducts = products.take(itemsToShow).toList();
        
        // Use IntrinsicHeight to let cards determine their own height
        return IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: displayProducts.asMap().entries.map((entry) {
                int index = entry.key;
                var product = entry.value;
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: index < displayProducts.length - 1 ? 12.w : 0),
                  child: cardBuilder(context, product),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
  
  // ============ ENDING SOON SECTION ============
  Widget _buildEndingSoonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.ending_soon_ucf,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'ending-soon');
                  }));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3), width: 1.w),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.view_all,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF80818B)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (homeData.endingSoonProductList.isEmpty)
          Container(
            height: 50.h,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_ending_soon_auctions,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          )
        else
          _buildEndingSoonGrid(),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildEndingSoonGrid() {
    final products = homeData.endingSoonProductList;
    if (products.isEmpty) return const SizedBox.shrink();

    // Group products in sets of 3
    List<List<dynamic>> grids = [];
    for (int i = 0; i < products.length; i += 3) {
      int end = (i + 3 < products.length) ? i + 3 : products.length;
      List<dynamic> grid = products.sublist(i, end);
      grids.add(grid);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int gridsToShow;
        
        // Mobile: Show 1 grid
        // Tablet: Show 2 grids
        // Desktop: Show 3 grids
        if (constraints.maxWidth >= 1024) {
          gridsToShow = grids.length > 3 ? 3 : grids.length;
        } else if (constraints.maxWidth >= 768) {
          gridsToShow = grids.length > 2 ? 2 : grids.length;
        } else {
          gridsToShow = 1;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(gridsToShow, (gridIndex) {
              final grid = grids[gridIndex];
              return Expanded(
                child: _buildEndingSoonGridItem(grid),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildEndingSoonGridItem(List<dynamic> grid) {
    if (grid.isEmpty) return const SizedBox.shrink();

    final product1 = grid.length >= 1 ? grid[0] : null;
    final product2 = grid.length >= 2 ? grid[1] : null;
    final product3 = grid.length >= 3 ? grid[2] : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side - 2/3 width
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (product1 != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: EndingSoonCard(
                      id: product1.id ?? 0,
                      slug: product1.slug ?? '',
                      image: product1.thumbnailImage,
                      name: product1.name,
                      description: product1.description,
                      pointPerBid: product1.pointPerBid ?? 0,
                      auctionEndDate: product1.auctionEndDate,
                      currentBid: product1.highestBid,
                      startingBid: product1.startingBid,
                      isAuctionActive: product1.auctionEndDate != null && 
                          product1.auctionEndDate is int && 
                          product1.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      cardType: 'left',
                    ),
                  ),
                if (product2 != null)
                  EndingSoonCard(
                    id: product2.id ?? 0,
                    slug: product2.slug ?? '',
                    image: product2.thumbnailImage,
                    name: product2.name,
                    description: product2.description,
                    pointPerBid: product2.pointPerBid ?? 0,
                    auctionEndDate: product2.auctionEndDate,
                    currentBid: product2.highestBid,
                    startingBid: product2.startingBid,
                    isAuctionActive: product2.auctionEndDate != null && 
                        product2.auctionEndDate is int && 
                        product2.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    cardType: 'left',
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Right side - 1/3 width
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (product3 != null)
                  Expanded(
                    child: EndingSoonCard(
                      id: product3.id ?? 0,
                      slug: product3.slug ?? '',
                      image: product3.thumbnailImage,
                      name: product3.name,
                      description: product3.description,
                      pointPerBid: product3.pointPerBid ?? 0,
                      auctionEndDate: product3.auctionEndDate,
                      currentBid: product3.highestBid,
                      startingBid: product3.startingBid,
                      isAuctionActive: product3.auctionEndDate != null && 
                          product3.auctionEndDate is int && 
                          product3.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      cardType: 'right',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomeFeaturedCategories() {
    if (homeData.isCategoryInitial && homeData.featuredCategoryList.isEmpty) {
      return ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 0,
        item_count: 6,
        mainAxisExtent: 160.w,
        controller: homeData.featuredCategoryScrollController,
      );
    } else if (homeData.featuredCategoryList.isNotEmpty) {
      return SizedBox(
        height: 35.h,
        child: ListView.builder(
          padding: EdgeInsets.only(left: 16.w, right: 16.w),
          scrollDirection: Axis.horizontal,
          controller: homeData.featuredCategoryScrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: homeData.featuredCategoryList.length,
          itemBuilder: (context, index) {
            final category = homeData.featuredCategoryList[index];
            
            return GestureDetector(
              onTap: () {
                if (category.slug != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: category.slug!);
                  }));
                }
              },
              child: Container(
                width: 160.w,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: const Color.fromRGBO(237, 242, 247, 1), width: 1.w),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: category.banner ?? '',
                        fit: BoxFit.cover,
                        width: 35.w,
                        height: 35.h,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 35.w,
                            height: 35.h,
                            color: const Color.fromRGBO(245, 247, 250, 1),
                            child: Icon(Icons.category, size: 25.sp, color: const Color.fromRGBO(107, 115, 119, 1)),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          category.name ?? '',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color.fromRGBO(0, 0, 0, 1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else if (!homeData.isCategoryInitial && homeData.featuredCategoryList.isEmpty) {
      return Container(
        height: 60.h,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_category_found,
            style: TextStyle(fontSize: 14.sp, color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return SizedBox(height: 60.h);
    }
  }
    
  Widget buildHomeCarouselSlider() {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use the actual banner dimensions 350x167
    final double carouselHeight = screenWidth * (167 / 350);
    
    if (homeData.isCarouselInitial && homeData.carouselImageList.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 18.w, right: 18.w, top: 0, bottom: 20.h),
        child: ShimmerHelper().buildBasicShimmer(height: carouselHeight),
      );
    } else if (homeData.carouselImageList.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: carouselHeight,
          viewportFraction: 1,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
          autoPlayCurve: Curves.easeInExpo,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) {
            homeData.incrementCurrentSlider(index);
          },
        ),
        items: homeData.carouselImageList.map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: carouselHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: () {
                            if (i.url != null) {
                              var url = i.url!.split(AppConfig.DOMAIN_PATH).last ?? "";
                              if (url.isNotEmpty) {
                                GoRouter.of(context).go(url);
                              }
                            }
                          },
                          child: i.photo != null
                              ? Image.network(
                                  i.photo!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: carouselHeight,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 50.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Gradient overlay for better visibility of dots
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12.r),
                            bottomRight: Radius.circular(12.r),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Dot indicators
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: homeData.carouselImageList.map((url) {
                            int index = homeData.carouselImageList.indexOf(url);
                            return Container(
                              width: 8.w,
                              height: 8.w,
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: homeData.current_slider == index 
                                    ? MyTheme.white 
                                    : Colors.white.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      );
    } else if (!homeData.isCarouselInitial && homeData.carouselImageList.isEmpty) {
      return Container(
        height: carouselHeight,
        margin: EdgeInsets.symmetric(horizontal: 18.w),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(fontSize: 14.sp, color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: carouselHeight,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 18.w),
          color: Colors.grey[200],
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.no_images_available,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }
  }

  AppBar buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 60.h,
      titleSpacing: 0,
      title: Container(
        padding: EdgeInsets.only(left: 16.w, right: 16.w),
        child: Row(
          children: [
            Expanded(child: buildHomeSearchBox()),
            // Notification Icon
            Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsPage()),
                    ).then((_) => _refreshCounts());
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35.w,
                  height: 35.w,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8.r)),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/notification.png',
                          height: 22.w,
                          width: 22.w,
                          color: MyTheme.dark_grey,
                        ),
                      ),
                      // ==========================================================
                      // UPDATED BADGE LOGIC:
                      // - Show only when NOT loading AND logged in AND count > 0
                      // - Count is only shown after data is fetched from server
                      // - If count is 0, show 0
                      // ==========================================================
                      if (_shouldShowNotificationBadge)
                        Positioned(
                          top: 2.h,
                          right: 2.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                            child: Text(
                              _notificationBadgeText,
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      // When loading, show nothing (no badge)
                    ],
                  ),
                ),
              ),
            ),
            // Chat Icon
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessengerList()));
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35.w,
                  height: 35.w,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8.r)),
                  child: Stack(
                    children: [
                      Center(child: Image.asset('assets/message.png', height: 22.w, width: 22.w)),
                      // ==========================================================
                      // UPDATED BADGE LOGIC:
                      // - Show only when NOT loading AND logged in AND count > 0
                      // - Count is only shown after data is fetched from server
                      // - If count is 0, show 0
                      // ==========================================================
                      if (_shouldShowMessageBadge)
                        Positioned(
                          top: 2.h,
                          right: 2.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                            child: Text(
                              _messageBadgeText,
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      // When loading, show nothing (no badge)
                    ],
                  ),
                ),
              ),
            ),
            // Affiliate Icon
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AffiliatePage()));
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35.w,
                  height: 35.w,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8.r)),
                  child: Center(
                    child: Image.asset('assets/affiliate.png', height: 22.w, width: 22.w, color: MyTheme.dark_grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomeSearchBox() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Filter()));
      },
      child: Container(
        height: 40.h,
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.search_anything,
                style: TextStyle(fontSize: 11.sp, color: MyTheme.textfield_grey),
              ),
              Image.asset('assets/search.png', height: 16.w, color: MyTheme.dark_grey),
            ],
          ),
        ),
      ),
    );
  }
}