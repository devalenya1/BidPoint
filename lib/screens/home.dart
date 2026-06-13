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
import 'package:active_ecommerce_flutter/ui_elements/mini_product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_horizontal_carousel.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
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
  
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoadingCounts = true;
  bool _isRefreshingCounts = false;
  UserInformation? _userInfo;  // Store user info for counts
  
  // Display counts (derived from _userInfo or fallback)
  int get _unreadNotificationCount {
    // Not logged in → 0
    if (is_logged_in.$ != true) return 0;
    
    // Logged in but no user info yet → 1 (shimmer/placeholder)
    if (_userInfo == null) return 1;
    
    // Logged in with user info → actual count from API
    return _userInfo!.unreadNotificationsCount ?? 0;
  }
  
  int get _unreadMessageCount {
    // Not logged in → 0
    if (is_logged_in.$ != true) return 0;
    
    // Logged in but no user info yet → 1 (shimmer/placeholder)
    if (_userInfo == null) return 1;
    
    // TODO: Get message count from chat repository when available
    // For now, return 0 (actual count would come from chat API)
    return 0;
  }
  
  // Whether to show count badge
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
  
  // ============ FETCH COUNTS FROM API ============
  Future<void> _fetchCounts() async {
    // If not logged in, don't fetch
    if (is_logged_in.$ != true) {
      setState(() {
        _isLoadingCounts = false;
      });
      return;
    }
    
    try {
      setState(() {
        _isLoadingCounts = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally
        });
        
        // Update SharedValue for quick access elsewhere
        unread_notifications_count.$ = _userInfo!.unreadNotificationsCount ?? 0;
        unread_notifications_count.save();
      }
    } catch (e) {
      print("Error loading notification counts: $e");
      // On error, user info remains null, so getters will return 1 as fallback
    } finally {
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH COUNTS ============
  Future<void> _refreshCounts() async {
    setState(() {
      _isRefreshingCounts = true;
    });
    await _fetchCounts();
    setState(() {
      _isRefreshingCounts = false;
    });
  }

  change() {
    homeData.onRefresh();
    homeData.mainScrollListener();
    homeData.initPiratedAnimation(this);
  }

  @override
  void dispose() {
    homeData.pirated_logo_controller.dispose();
    super.dispose();
  }

  void _redirectToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return WillPopScope(
      onWillPop: () async {
        print("Will scope home");
        return widget.go_back;
      },
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: buildAppBar(statusBarHeight, context),
            ),
            body: ListenableBuilder(
              listenable: homeData,
              builder: (context, child) {
                return Stack(
                  children: [
                    RefreshIndicator(
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
                          SliverList(
                            delegate: SliverChildListDelegate([
                              buildHomeCarouselSlider(context, homeData),
                              const SizedBox(height: 8),
                            ]),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .featured_categories_ucf,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 50,
                              child: buildHomeFeaturedCategories(
                                  context, homeData),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18.0, 16.0, 20.0, 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .all_products_ucf,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              buildHomeAllProducts2(context, homeData),
                              const SizedBox(height: 16),
                            ]),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18.0, 8.0, 20.0, 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .ending_soon_ucf,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              buildHomeEndingSoon(context, homeData),
                              const SizedBox(height: 16),
                            ]),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18.0, 8.0, 20.0, 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .upcoming_ucf,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              buildHomeUpcoming(context, homeData),
                              const SizedBox(height: 30),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    Align(
                        alignment: Alignment.center,
                        child: buildProductLoadingContainer(homeData))
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHomeAllProducts2(context, HomePresenter homeData) {
    if (homeData.isAllProductInitial) {
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: ShimmerHelper().buildBasicShimmer(height: 260),
            );
          },
        ),
      );
    } else if (homeData.allProductList.isNotEmpty) {
      return ProductHorizontalCarousel(
        products: homeData.allProductList,
        scrollController: homeData.allProductScrollController,
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container();
    }
  }

  Widget buildHomeEndingSoon(context, HomePresenter homeData) {
    if (homeData.isEndingSoonInitial) {
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: ShimmerHelper().buildBasicShimmer(height: 260),
            );
          },
        ),
      );
    } else if (homeData.endingSoonProductList.isNotEmpty) {
      return ProductHorizontalCarousel(
        products: homeData.endingSoonProductList,
        scrollController: homeData.endingSoonScrollController,
      );
    } else if (homeData.totalEndingSoonData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container();
    }
  }

  Widget buildHomeUpcoming(context, HomePresenter homeData) {
    if (homeData.isUpcomingInitial) {
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: ShimmerHelper().buildBasicShimmer(height: 260),
            );
          },
        ),
      );
    } else if (homeData.upcomingProductList.isNotEmpty) {
      return ProductHorizontalCarousel(
        products: homeData.upcomingProductList,
        scrollController: homeData.upcomingScrollController,
      );
    } else if (homeData.totalUpcomingData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container();
    }
  }

  Widget buildHomeFeaturedCategories(context, HomePresenter homeData) {
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
                    return CategoryProducts(
                      slug: category.slug!,
                    );
                  }));
                }
              },
              child: Container(
                width: 160,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromRGBO(237, 242, 247, 1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
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
                            child: const Icon(
                              Icons.category,
                              size: 25,
                              color: Color.fromRGBO(107, 115, 119, 1),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(0, 0, 0, 1),
                          ),
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

  Widget buildHomeCarouselSlider(context, HomePresenter homeData) {
    if (homeData.isCarouselInitial && homeData.carouselImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 18,
          right: 18,
          top: 0,
          bottom: 20,
        ),
        child: ShimmerHelper().buildBasicShimmer(
          height: 120,
        ),
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
                padding: const EdgeInsets.only(
                    left: 18, right: 18, top: 0, bottom: 20),
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 140,
                      child: InkWell(
                        onTap: () {
                          if (i.url != null) {
                            var url = i.url!.split(AppConfig.DOMAIN_PATH).last ?? "";
                            print(url);
                            if (url.isNotEmpty) {
                              GoRouter.of(context).go(url);
                            }
                          }
                        },
                        child: i.photo != null
                            ? AIZImage.radiusImage(i.photo!, 6)
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image, size: 50),
                                ),
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
                            margin: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: homeData.current_slider == index
                                  ? MyTheme.white
                                  : const Color.fromRGBO(112, 112, 112, .3),
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
    } else if (!homeData.isCarouselInitial &&
        homeData.carouselImageList.isEmpty) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else {
      return Container(
        height: 100,
      );
    }
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
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
            // Search Box - Takes remaining space
            Expanded(
              child: buildHomeSearchBox(context),
            ),
            // Notification Icon
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    ).then((_) => _refreshCounts()); // Refresh counts after returning
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                      // Notification counter badge
                      if (_showNotificationBadge)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99 
                                  ? '99+' 
                                  : '$_unreadNotificationCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessengerList(),
                      ),
                    );
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/message.png',
                          height: 22,
                          width: 22,
                        ),
                      ),
                      // Chat counter badge
                      if (_showMessageBadge)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadMessageCount > 99 
                                  ? '99+' 
                                  : '$_unreadMessageCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AffiliatePage(),
                      ),
                    );
                  } else {
                    _redirectToLogin();
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/affiliate.png',
                      height: 22,
                      width: 22,
                      color: MyTheme.dark_grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomeSearchBox(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Filter(),
          ),
        );
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
                style: TextStyle(
                  fontSize: 13.0,
                  color: MyTheme.textfield_grey,
                ),
              ),
              Image.asset(
                'assets/search.png',
                height: 16,
                color: MyTheme.dark_grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildProductLoadingContainer(HomePresenter homeData) {
    return Container(
      height: homeData.showAllLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
            homeData.totalAllProductData == homeData.allProductList.length
                ? AppLocalizations.of(context)!.no_more_products_ucf
                : AppLocalizations.of(context)!.loading_more_products_ucf),
      ),
    );
  }
}