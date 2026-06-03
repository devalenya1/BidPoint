import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/aiz_image.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/home_presenter.dart';
import 'package:active_ecommerce_flutter/screens/category_products.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/ui_elements/mini_product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:active_ecommerce_flutter/ui_elements/auction_products_carousel.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    Future.delayed(Duration.zero).then((value) {
      change();
    });
    // change();
    // TODO: implement initState
    super.initState();
  }

  change() {
    homeData.onRefresh();
    homeData.mainScrollListener();
    homeData.initPiratedAnimation(this);
  }

  @override
  void dispose() {
    homeData.pirated_logo_controller.dispose();
    //  ChangeNotifierProvider<HomePresenter>.value(value: value)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return WillPopScope(
      onWillPop: () async {
        //CommonFunctions(context).appExitDialog();
        print("Will scope home");
        return widget.go_back;
      },
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
              //key: homeData.scaffoldKey,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: buildAppBar(statusBarHeight, context),
              ),
              //drawer: MainDrawer(),
              body: ListenableBuilder(
                  listenable: homeData,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        RefreshIndicator(
                          color: MyTheme.accent_color,
                          backgroundColor: Colors.white,
                          onRefresh: homeData.onRefresh,
                          displacement: 0,
                          child: CustomScrollView(
                            controller: homeData.mainScrollController,
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            slivers: <Widget>[
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  // AppConfig.purchase_code == ""
                                  //     ? Padding(
                                  //         padding: const EdgeInsets.fromLTRB(
                                  //           9.0,
                                  //           16.0,
                                  //           9.0,
                                  //           0.0,
                                  //         ),
                                  //         child: Container(
                                  //           height: 140,
                                  //           color: Colors.black,
                                  //           child: Stack(
                                  //             children: [
                                  //               Positioned(
                                  //                   left: 20,
                                  //                   top: 0,
                                  //                   child: AnimatedBuilder(
                                  //                       animation: homeData
                                  //                           .pirated_logo_animation,
                                  //                       builder:
                                  //                           (context, child) {
                                  //                         return Image.asset(
                                  //                           "assets/pirated_square.png",
                                  //                           height: homeData
                                  //                               .pirated_logo_animation
                                  //                               .value,
                                  //                           color: Colors.white,
                                  //                         );
                                  //                       })),
                                  //               Center(
                                  //                 child: Padding(
                                  //                   padding:
                                  //                       const EdgeInsets.only(
                                  //                           top: 24.0,
                                  //                           left: 24,
                                  //                           right: 24),
                                  //                   child: Text(
                                  //                     "This is a pirated app. Do not use this. It may have security issues.",
                                  //                     style: TextStyle(
                                  //                         color: Colors.white,
                                  //                         fontSize: 18),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       )
                                  //     : Container(),
                                  buildHomeCarouselSlider(context, homeData),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      0.0,
                                      18.0,
                                      0.0,
                                    ),
                                  ),
                                  
                                ]),
                              ),
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      20.0,
                                      18.0,
                                      0.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .featured_categories_ucf,
                                          style: TextStyle(
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
                                  height: 154,
                                  child: buildHomeFeaturedCategories(
                                      context, homeData),
                                ),
                              ),
                              
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      18.0,
                                      20.0,
                                      0.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .all_products_ucf,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // SingleChildScrollView(
                                  //   child: Column(
                                  //     children: [
                                  //       buildHomeAllProducts2(
                                  //           context, homeData),
                                  //     ],
                                  //   ),
                                  // ),
                                  // Add this after your existing slivers
                                  SliverToBoxAdapter(
                                    child: buildHotAuctionsCarousel(context, homeData),
                                  ),
                                  Container(
                                    height: 80,
                                  )
                                ]),
                              ),


                              SliverList(
                                delegate: SliverChildListDelegate([
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      18.0,
                                      20.0,
                                      0.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .ending_soon_ucf,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        buildHomeEndingSoon(
                                            context, homeData),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 80,
                                  )
                                ]),
                              ),


                              SliverList(
                                delegate: SliverChildListDelegate([
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      18.0,
                                      20.0,
                                      0.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .upcoming_ucf,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        buildHomeUpcoming(
                                            context, homeData),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 80,
                                  )
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
                  })),
        ),
      ),
    );
  }

  Widget buildHomeAllProducts(context, HomePresenter homeData) {
    if (homeData.isAllProductInitial && homeData.allProductList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper().buildProductGridShimmer(
              scontroller: homeData.allProductScrollController));
    } else if (homeData.allProductList.length > 0) {
      //snapshot.hasData

      return GridView.builder(
        // 2
        //addAutomaticKeepAlives: true,
        itemCount: homeData.allProductList.length,
        controller: homeData.allProductScrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.618),
        padding: EdgeInsets.all(16.0),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // 3
          return ProductCard(
            id: homeData.allProductList[index].id,
            slug: homeData.allProductList[index].slug,
            image: homeData.allProductList[index].thumbnail_image,
            name: homeData.allProductList[index].name,
            main_price: homeData.allProductList[index].main_price,
            stroked_price: homeData.allProductList[index].stroked_price,
            has_discount: homeData.allProductList[index].has_discount,
            discount: homeData.allProductList[index].discount,
          );
        },
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_product_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  
  Widget buildHomeEndingSoon(context, HomePresenter homeData) {
    if (homeData.isAllProductInitial && homeData.allProductList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper().buildProductGridShimmer(
              scontroller: homeData.allProductScrollController));
    } else if (homeData.allProductList.length > 0) {
      //snapshot.hasData

      return GridView.builder(
        // 2
        //addAutomaticKeepAlives: true,
        itemCount: homeData.allProductList.length,
        controller: homeData.allProductScrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.618),
        padding: EdgeInsets.all(16.0),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // 3
          return ProductCard(
            id: homeData.allProductList[index].id,
            slug: homeData.allProductList[index].slug,
            image: homeData.allProductList[index].thumbnail_image,
            name: homeData.allProductList[index].name,
            main_price: homeData.allProductList[index].main_price,
            stroked_price: homeData.allProductList[index].stroked_price,
            has_discount: homeData.allProductList[index].has_discount,
            discount: homeData.allProductList[index].discount,
          );
        },
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_product_is_available));
    } else {
      return Container(); // should never be happening
    }
  }



  Widget buildHomeUpcoming(context, HomePresenter homeData) {
    if (homeData.isAllProductInitial && homeData.allProductList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper().buildProductGridShimmer(
              scontroller: homeData.allProductScrollController));
    } else if (homeData.allProductList.length > 0) {
      //snapshot.hasData

      return GridView.builder(
        // 2
        //addAutomaticKeepAlives: true,
        itemCount: homeData.allProductList.length,
        controller: homeData.allProductScrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.618),
        padding: EdgeInsets.all(16.0),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // 3
          return ProductCard(
            id: homeData.allProductList[index].id,
            slug: homeData.allProductList[index].slug,
            image: homeData.allProductList[index].thumbnail_image,
            name: homeData.allProductList[index].name,
            main_price: homeData.allProductList[index].main_price,
            stroked_price: homeData.allProductList[index].stroked_price,
            has_discount: homeData.allProductList[index].has_discount,
            discount: homeData.allProductList[index].discount,
          );
        },
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_product_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  // Widget buildHomeAllProducts2(context, HomePresenter homeData) {
  //   // if (homeData.isAllProductInitial && homeData.allProductList.length == 0) {
  //   if (homeData.isAllProductInitial) {
  //     return SingleChildScrollView(
  //         child: ShimmerHelper().buildProductGridShimmer(
  //             scontroller: homeData.allProductScrollController));
  //   } else if (homeData.allProductList.length > 0) {
  //     return MasonryGridView.count(
  //         crossAxisCount: 2,
  //         mainAxisSpacing: 14,
  //         crossAxisSpacing: 14,
  //         itemCount: homeData.allProductList.length,
  //         shrinkWrap: true,
  //         padding: EdgeInsets.only(top: 20.0, bottom: 10, left: 18, right: 18),
  //         physics: NeverScrollableScrollPhysics(),
  //         itemBuilder: (context, index) {
  //           return ProductCard(
  //             id: homeData.allProductList[index].id,
  //             slug: homeData.allProductList[index].slug,
  //             image: homeData.allProductList[index].thumbnail_image,
  //             name: homeData.allProductList[index].name,
  //             main_price: homeData.allProductList[index].main_price,
  //             stroked_price: homeData.allProductList[index].stroked_price,
  //             has_discount: homeData.allProductList[index].has_discount,
  //             discount: homeData.allProductList[index].discount,
  //             is_wholesale: homeData.allProductList[index].isWholesale,
  //           );
  //         });
  //   } else if (homeData.totalAllProductData == 0) {
  //     return Center(
  //         child: Text(AppLocalizations.of(context)!.no_product_is_available));
  //   } else {
  //     return Container(); // should never be happening
  //   }
  // }

  Widget buildHotAuctionsCarousel(BuildContext context, HomePresenter homeData) {
    // Check if auction products exist
    if (homeData.allProductList == null || homeData.allProductList!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AuctionProductsCarousel(
      products: homeData.allProductList!,
      title: AppLocalizations.of(context)!.hot_auctions_ucf,
      onViewAll: () {
        // Navigate to all auctions page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => AllAuctionsPage()));
      },
    );
  }

  Widget buildHomeFeaturedCategories(context, HomePresenter homeData) {
    if (homeData.isCategoryInitial && homeData.featuredCategoryList.length == 0) {
      return ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 0,
        item_count: 6,
        mainAxisExtent: 200.0, // Width of each shimmer card
        controller: homeData.featuredCategoryScrollController,
      );
    } else if (homeData.featuredCategoryList.length > 0) {
      return SizedBox(
        height: 60, // Fixed height for the horizontal row (44px card + padding)
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          scrollDirection: Axis.horizontal,
          controller: homeData.featuredCategoryScrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: homeData.featuredCategoryList.length,
          itemBuilder: (context, index) {
            final category = homeData.featuredCategoryList[index];
            
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CategoryProducts(
                    slug: category.slug,
                  );
                }));
              },
              child: Container(
                width: 200, // Fixed width matching HTML's 200px (12.5rem)
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // 0.625rem = 10px
                  border: Border.all(
                    color: const Color.fromRGBO(237, 242, 247, 1), // #edf2f7
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Square Image Section (Left) - 44px x 44px
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                        color: const Color.fromRGBO(245, 247, 250, 1), // #f5f7fa
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: category.banner,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color.fromRGBO(245, 247, 250, 1),
                              child: const Icon(
                                Icons.category,
                                size: 24,
                                color: Color.fromRGBO(107, 115, 119, 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Text Section (Right)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 13, // 0.8125rem
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(0, 0, 0, 1),
                            height: 1.2,
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
    } else if (!homeData.isCategoryInitial && homeData.featuredCategoryList.length == 0) {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_category_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 100);
    }
  }

  Widget buildHomeCarouselSlider(context, HomePresenter homeData) {
    if (homeData.isCarouselInitial && homeData.carouselImageList.length == 0) {
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
    } else if (homeData.carouselImageList.length > 0) {
      return CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 338 / 140,
          viewportFraction: 1,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 5),
          autoPlayAnimationDuration: Duration(milliseconds: 1000),
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
                          var url =
                              i.url?.split(AppConfig.DOMAIN_PATH).last ?? "";
                          print(url);
                          GoRouter.of(context).go(url);
                        },
                        child: AIZImage.radiusImage(i.photo, 6),
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
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: homeData.current_slider == index
                                  ? MyTheme.white
                                  : Color.fromRGBO(112, 112, 112, .3),
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
        homeData.carouselImageList.length == 0) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else {
      // should not be happening
      return Container(
        height: 100,
      );
    }
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      // Don't show the leading button
      backgroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      flexibleSpace: Padding(
        // padding:
        //     const EdgeInsets.only(top: 40.0, bottom: 22, left: 18, right: 18),
        padding:
            const EdgeInsets.only(top: 10.0, bottom: 10, left: 18, right: 18),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Filter();
            }));
          },
          child: buildHomeSearchBox(context),
        ),
      ),
    );
  }

  buildHomeSearchBox(BuildContext context) {
    return Container(
      height: 36,
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
            Image.asset(
              'assets/search.png',
              height: 16,
              //color: MyTheme.dark_grey,
              color: MyTheme.dark_grey,
            )
          ],
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
