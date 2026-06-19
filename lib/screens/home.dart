import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/aiz_image.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
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
// import 'package:active_ecommerce_flutter/ui_elements/auction_product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/hot_auction_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/ending_soon_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/upcoming_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:go_router/go_router.dart';

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
  
  // Display counts
  int get _unreadNotificationCount {
    if (is_logged_in.$ != true) return 0;
    if (_userInfo == null) return 1;
    return _userInfo!.unreadNotificationsCount ?? 0;
  }
  
  int get _unreadMessageCount {
    if (is_logged_in.$ != true) return 0;
    if (_userInfo == null) return 1;
    return _userInfo!.unreadMessagesCount ?? 0;
  }
  
  bool get _showNotificationBadge => is_logged_in.$ && _unreadNotificationCount > 0;
  bool get _showMessageBadge => is_logged_in.$ && _unreadMessageCount > 0;
  
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
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
              preferredSize: Size.fromHeight(50),
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
                          const SizedBox(height: 8),
                        ]),
                      ),
                      
                      // Featured Categories
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.featured_categories_ucf,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: buildHomeFeaturedCategories(),
                        ),
                      ),
                      
                      // Hot Auctions Section
                      SliverToBoxAdapter(
                        child: _buildHotAuctionSection(),
                      ),
                      
                      // // Ending Soon Section
                      // SliverToBoxAdapter(
                      //   child: _buildEndingSoonSection(),
                      // ),


                      // Upcoming Section
                      SliverToBoxAdapter(
                        child: _buildUpcomingSection(),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
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
    print('Hot Auctions count: ${homeData.hotAuctionProductList.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.hot_auctions_ucf,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                // onTap: () {
                //   GoRouter.of(context).go('/hot-auctions');
                // },
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'hot-auctions');
                  }));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF80818B))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth;
            if (constraints.maxWidth >= 1024) {
              cardWidth = (constraints.maxWidth - 16 * 7) / 6;
            } else if (constraints.maxWidth >= 768) {
              cardWidth = (constraints.maxWidth - 16 * 5) / 4;
            } else {
              cardWidth = (constraints.maxWidth - 16 * 3) / 2;
            }
            
            cardWidth = cardWidth.clamp(120.0, double.infinity);
            
            if (homeData.hotAuctionProductList.isEmpty) {
              return Container(
                height: 50,
                child: Center(
                  child: Text('No hot auctions available'),
                ),
              );
            }
            
            return SizedBox(
              height: 350,
              child: ListView.builder(
                // shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // ← Prevents scrolling
                // scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: homeData.hotAuctionProductList.length,
                itemBuilder: (context, index) {
                  final product = homeData.hotAuctionProductList[index];
                  bool isActive = false;
                  if (product.auctionEndDate != null && product.auctionEndDate is int) {
                    isActive = product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
                  }
                  return Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: HotAuctionCard(
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
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============ ENDING SOON SECTION ============
  Widget _buildEndingSoonSection() {
    print('Ending Soon count: ${homeData.endingSoonProductList.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.ending_soon_ucf,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                // onTap: () {
                //   GoRouter.of(context).go('/ending-soon');
                // },
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'ending-soon');
                  }));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF80818B))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (homeData.endingSoonProductList.isEmpty)
          Container(
            height: 50,
            child: Center(
              child: Text('No ending soon auctions'),
            ),
          )
        else
          _buildEndingSoonGrid(),
        const SizedBox(height: 20),
      ],
    );
  }


  Widget _buildEndingSoonGrid() {
    final products = homeData.endingSoonProductList;
    if (products.isEmpty) return const SizedBox.shrink();

    List<List<dynamic>> grids = [];
    for (int i = 0; i < products.length; i += 3) {
      int end = (i + 3 < products.length) ? i + 3 : products.length;
      grids.add(products.sublist(i, end));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          int gridsToShow = grids.length > 2 ? 2 : grids.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        } else {
          final grid = grids.isNotEmpty ? grids[0] : [];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEndingSoonGridItem(grid),
          );
        }
      },
    );
  }

  Widget _buildEndingSoonGridItem(List<dynamic> grid) {
    final leftProducts = grid.length >= 2 ? grid.sublist(0, 2) : grid;
    final rightProduct = grid.length >= 3 ? grid[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: leftProducts.map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EndingSoonCard(
                  id: product.id ?? 0,
                  slug: product.slug ?? '',
                  image: product.thumbnailImage,
                  name: product.name,
                  description: product.description,
                  pointPerBid: product.pointPerBid ?? 0,
                  auctionEndDate: product.auctionEndDate,
                  currentBid: product.highestBid,
                  startingBid: product.startingBid,
                  isAuctionActive: product.auctionEndDate != null && 
                      product.auctionEndDate is int && 
                      product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  cardType: 'left',
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        if (rightProduct != null)
          Expanded(
            flex: 1,
            child: EndingSoonCard(
              id: rightProduct.id ?? 0,
              slug: rightProduct.slug ?? '',
              image: rightProduct.thumbnailImage,
              name: rightProduct.name,
              description: rightProduct.description,
              pointPerBid: rightProduct.pointPerBid ?? 0,
              auctionEndDate: rightProduct.auctionEndDate,
              currentBid: rightProduct.highestBid,
              startingBid: rightProduct.startingBid,
              isAuctionActive: rightProduct.auctionEndDate != null && 
                  rightProduct.auctionEndDate is int && 
                  rightProduct.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
              cardType: 'right',
            ),
          ),
      ],
    );
  }

  // ============ UPCOMING SECTION ============
  Widget _buildUpcomingSection() {
    print('Upcoming count: ${homeData.upcomingProductList.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.upcoming_auctions_ucf,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                // onTap: () {
                //   GoRouter.of(context).go('/upcoming-auctions');
                // },
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryProducts(slug: 'upcoming-auctions');
                  }));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF80818B))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth;
            if (constraints.maxWidth >= 1024) {
              cardWidth = (constraints.maxWidth - 16 * 7) / 6;
            } else if (constraints.maxWidth >= 768) {
              cardWidth = (constraints.maxWidth - 16 * 5) / 4;
            } else {
              cardWidth = (constraints.maxWidth - 16 * 3) / 2;
            }
            
            cardWidth = cardWidth.clamp(120.0, double.infinity);
            
            if (homeData.upcomingProductList.isEmpty) {
              return Container(
                height: 50,
                child: Center(
                  child: Text('No upcoming auctions'),
                ),
              );
            }
            
            return SizedBox(
              height: 350,
              child: ListView.builder(
                // shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // ← Prevents scrolling
                // scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: homeData.upcomingProductList.length,
                itemBuilder: (context, index) {
                  final product = homeData.upcomingProductList[index];
                  
                  int? auctionStartTimestamp;
                  if (product.auctionStartDate != null) {
                    if (product.auctionStartDate is int) {
                      auctionStartTimestamp = product.auctionStartDate;
                    } else if (product.auctionStartDate is String) {
                      auctionStartTimestamp = int.tryParse(product.auctionStartDate) ?? 0;
                    }
                  }
                  
                  return Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: UpcomingCard(
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
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildHomeFeaturedCategories() {
    if (homeData.isCategoryInitial && homeData.featuredCategoryList.isEmpty) {
      return ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 0,
        item_count: 6,
        mainAxisExtent: 160.0,
        controller: homeData.featuredCategoryScrollController,
      );
    } else if (homeData.featuredCategoryList.isNotEmpty) {
      return SizedBox(
        height: 50,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16),
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
                width: 160,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromRGBO(237, 242, 247, 1), width: 1),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: category.banner ?? '',
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: const Color.fromRGBO(245, 247, 250, 1),
                            child: const Icon(Icons.category, size: 25, color: Color.fromRGBO(107, 115, 119, 1)),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color.fromRGBO(0, 0, 0, 1)),
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
        height: 60,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_category_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 60);
    }
  }

  Widget buildHomeCarouselSlider() {
    if (homeData.isCarouselInitial && homeData.carouselImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 0, bottom: 20),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    } else if (homeData.carouselImageList.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 338 / 140,
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
                padding: const EdgeInsets.only(left: 18, right: 18, top: 0, bottom: 20),
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 140,
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
                            ? AIZImage.radiusImage(i.photo!, 6)
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image, size: 50)),
                              ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: homeData.carouselImageList.map((url) {
                          int index = homeData.carouselImageList.indexOf(url);
                          return Container(
                            width: 7.0,
                            height: 7.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: homeData.current_slider == index ? MyTheme.white : const Color.fromRGBO(112, 112, 112, .3),
                            ),
                          );
                        }).toList(),
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
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 100);
    }
  }

  AppBar buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          children: [
            Expanded(child: buildHomeSearchBox()),
            // Notification Icon
            Padding(
              padding: const EdgeInsets.only(left: 12),
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
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/notification.png',
                          height: 22,
                          width: 22,
                          color: MyTheme.dark_grey,
                        ),
                      ),
                      if (_showNotificationBadge)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: MyTheme.accent_color, borderRadius: BorderRadius.circular(10)),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Chat Icon
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessengerList()));
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Stack(
                    children: [
                      Center(child: Image.asset('assets/message.png', height: 22, width: 22)),
                      if (_showMessageBadge)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: MyTheme.accent_color, borderRadius: BorderRadius.circular(10)),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Affiliate Icon
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AffiliatePage()));
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Image.asset('assets/affiliate.png', height: 22, width: 22, color: MyTheme.dark_grey),
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
        height: 40,
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.search_anything,
                style: TextStyle(fontSize: 13.0, color: MyTheme.textfield_grey),
              ),
              Image.asset('assets/search.png', height: 16, color: MyTheme.dark_grey),
            ],
          ),
        ),
      ),
    );
  }
}