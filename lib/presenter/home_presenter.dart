import 'dart:async';

import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/data_model/slider_response.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/flash_deal_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/sliders_repository.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class HomePresenter extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  int current_slider = 0;
  ScrollController? allProductScrollController;
  ScrollController? featuredCategoryScrollController;
  ScrollController? endingSoonScrollController;
  ScrollController? upcomingScrollController;
  ScrollController? hotAuctionScrollController;
  ScrollController? allAuctionsScrollController;
  ScrollController mainScrollController = ScrollController();

  late AnimationController pirated_logo_controller;
  late Animation pirated_logo_animation;

  List<AIZSlider> carouselImageList = [];
  List<AIZSlider> bannerOneImageList = [];
  var bannerTwoImageList = [];
  var featuredCategoryList = [];

  bool isCategoryInitial = true;

  bool isCarouselInitial = true;
  bool isBannerOneInitial = true;
  bool isBannerTwoInitial = true;

  var featuredProductList = [];
  bool isFeaturedProductInitial = true;
  int? totalFeaturedProductData = 0;
  int featuredProductPage = 1;
  bool showFeaturedLoadingContainer = false;

  // Hot Auctions Products
  var hotAuctionProductList = [];
  bool isHotAuctionInitial = true;
  int? totalHotAuctionData = 0;
  int hotAuctionPage = 1;
  bool showHotAuctionLoadingContainer = false;

  // Ending Soon Products
  var endingSoonProductList = [];
  bool isEndingSoonInitial = true;
  int? totalEndingSoonData = 0;
  int endingSoonPage = 1;
  bool showEndingSoonLoadingContainer = false;

  // Upcoming Products
  var upcomingProductList = [];
  bool isUpcomingInitial = true;
  int? totalUpcomingData = 0;
  int upcomingPage = 1;
  bool showUpcomingLoadingContainer = false;

  // ============================================================
  // ✅ ADDED: Ended Auctions Products
  // ============================================================
  var endedProductList = [];
  bool isEndedInitial = true;
  int? totalEndedData = 0;
  int endedPage = 1;
  bool showEndedLoadingContainer = false;

  bool isTodayDeal = false;
  bool isFlashDeal = false;

  var allProductList = [];
  bool isAllProductInitial = true;
  int? totalAllProductData = 0;
  int allProductPage = 1;
  bool showAllLoadingContainer = false;

  
  // ============================================================
  // ✅ ADDED: All Auctions Products (using getAllProducts)
  // ============================================================
  var allAuctionsList = [];
  bool isAllAuctionsInitial = true;
  int? totalAllAuctionsData = 0;
  int allAuctionsPage = 1;
  bool showAllAuctionsLoadingContainer = false;

  int cartCount = 0;
  
  final ProductRepository _productRepository = ProductRepository();

  fetchAll() {
    fetchCarouselImages();
    fetchBannerOneImages();
    fetchBannerTwoImages();
    fetchFeaturedCategories();
    fetchFeaturedProducts();
    fetchAllProducts();
    fetchHotAuctionProducts();
    fetchEndingSoonProducts();
    fetchUpcomingProducts();
    fetchEndedProducts(); // ✅ ADDED
    fetchAllAuctions();
    fetchTodayDealData();
    fetchFlashDealData();
  }

  fetchTodayDealData() async {
    var deal = await _productRepository.getTodaysDealProducts();
    print(deal.products!.length);
    if (deal.success! && deal.products!.isNotEmpty) {
      isTodayDeal = true;
      notifyListeners();
    }
  }

  fetchFlashDealData() async {
    var deal = await FlashDealRepository().getFlashDeals();

    if (deal.success! && deal.flashDeals!.isNotEmpty) {
      isFlashDeal = true;
      notifyListeners();
    }
  }

  fetchCarouselImages() async {
    var carouselResponse = await SlidersRepository().getSliders();
    carouselResponse.sliders!.forEach((slider) {
      carouselImageList.add(slider);
    });
    isCarouselInitial = false;
    notifyListeners();
  }

  fetchBannerOneImages() async {
    var bannerOneResponse = await SlidersRepository().getBannerOneImages();
    bannerOneResponse.sliders!.forEach((slider) {
      bannerOneImageList.add(slider);
    });
    isBannerOneInitial = false;
    notifyListeners();
  }

  fetchBannerTwoImages() async {
    var bannerTwoResponse = await SlidersRepository().getBannerTwoImages();
    bannerTwoResponse.sliders!.forEach((slider) {
      bannerTwoImageList.add(slider);
    });
    isBannerTwoInitial = false;
    notifyListeners();
  }

  fetchFeaturedCategories() async {
    var categoryResponse = await CategoryRepository().getFeturedCategories();
    featuredCategoryList.addAll(categoryResponse.categories!);
    isCategoryInitial = false;
    notifyListeners();
  }

  fetchFeaturedProducts() async {
    var productResponse = await _productRepository.getFeaturedProducts(
      page: featuredProductPage,
    );
    featuredProductPage++;
    featuredProductList.addAll(productResponse.products!);
    isFeaturedProductInitial = false;
    totalFeaturedProductData = productResponse.meta!.total;
    showFeaturedLoadingContainer = false;
    notifyListeners();
  }

  // Fetch Hot Auction Products
  fetchHotAuctionProducts() async {
    try {
      var productResponse = await _productRepository.getHotAuctions(
        page: hotAuctionPage,
      );
      hotAuctionPage++;
      hotAuctionProductList.addAll(productResponse.products!);
      isHotAuctionInitial = false;
      totalHotAuctionData = productResponse.meta?.total ?? 0;
      showHotAuctionLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching hot auction products: $e");
      isHotAuctionInitial = false;
      totalHotAuctionData = 0;
      notifyListeners();
    }
  }

  // Fetch Ending Soon Products
  fetchEndingSoonProducts() async {
    try {
      var productResponse = await _productRepository.getEndingSoonProducts(
        page: endingSoonPage,
      );
      endingSoonPage++;
      endingSoonProductList.addAll(productResponse.products!);
      isEndingSoonInitial = false;
      totalEndingSoonData = productResponse.meta?.total ?? 0;
      showEndingSoonLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching ending soon products: $e");
      isEndingSoonInitial = false;
      totalEndingSoonData = 0;
      notifyListeners();
    }
  }

  // Fetch Upcoming Products
  fetchUpcomingProducts() async {
    try {
      var productResponse = await _productRepository.getUpcomingProducts(
        page: upcomingPage,
      );
      upcomingPage++;
      upcomingProductList.addAll(productResponse.products!);
      isUpcomingInitial = false;
      totalUpcomingData = productResponse.meta?.total ?? 0;
      showUpcomingLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching upcoming products: $e");
      isUpcomingInitial = false;
      totalUpcomingData = 0;
      notifyListeners();
    }
  }

  // ============================================================
  // ✅ ADDED: Fetch Ended Products
  // ============================================================
  fetchEndedProducts() async {
    try {
      var productResponse = await _productRepository.getEndedProducts(
        page: endedPage,
      );
      endedPage++;
      endedProductList.addAll(productResponse.products!);
      isEndedInitial = false;
      totalEndedData = productResponse.meta?.total ?? 0;
      showEndedLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching ended products: $e");
      isEndedInitial = false;
      totalEndedData = 0;
      notifyListeners();
    }
  }

  fetchAllProducts() async {
    var productResponse = await _productRepository.getFilteredProducts(page: allProductPage);
    
    allProductList.addAll(productResponse.products!);
    isAllProductInitial = false;
    totalAllProductData = productResponse.meta!.total;
    showAllLoadingContainer = false;
    notifyListeners();
  }

  // ============================================================
  // ✅ ADDED: Fetch All Auctions (using getAllProducts)
  // ============================================================
  fetchAllAuctions() async {
    try {
      var productResponse = await _productRepository.getAllProducts(
        page: allAuctionsPage,
      );
      allAuctionsPage++;
      allAuctionsList.addAll(productResponse.products!);
      isAllAuctionsInitial = false;
      totalAllAuctionsData = productResponse.meta?.total ?? 0;
      showAllAuctionsLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching all auctions: $e");
      isAllAuctionsInitial = false;
      totalAllAuctionsData = 0;
      notifyListeners();
    }
  }

  reset() {
    carouselImageList.clear();
    bannerOneImageList.clear();
    bannerTwoImageList.clear();
    featuredCategoryList.clear();

    isCarouselInitial = true;
    isBannerOneInitial = true;
    isBannerTwoInitial = true;
    isCategoryInitial = true;
    cartCount = 0;

    resetFeaturedProductList();
    resetAllProductList();
    resetHotAuctionProductList();
    resetEndingSoonProductList();
    resetUpcomingProductList();
    resetEndedProductList();
    resetAllAuctionsList(); // ✅ ADDED
  }

  Future<void> onRefresh() async {
    reset();
    fetchAll();
  }

  resetFeaturedProductList() {
    featuredProductList.clear();
    isFeaturedProductInitial = true;
    totalFeaturedProductData = 0;
    featuredProductPage = 1;
    showFeaturedLoadingContainer = false;
    notifyListeners();
  }

  resetAllProductList() {
    allProductList.clear();
    isAllProductInitial = true;
    totalAllProductData = 0;
    allProductPage = 1;
    showAllLoadingContainer = false;
    notifyListeners();
  }

  resetHotAuctionProductList() {
    hotAuctionProductList.clear();
    isHotAuctionInitial = true;
    totalHotAuctionData = 0;
    hotAuctionPage = 1;
    showHotAuctionLoadingContainer = false;
    notifyListeners();
  }

  resetEndingSoonProductList() {
    endingSoonProductList.clear();
    isEndingSoonInitial = true;
    totalEndingSoonData = 0;
    endingSoonPage = 1;
    showEndingSoonLoadingContainer = false;
    notifyListeners();
  }

  resetUpcomingProductList() {
    upcomingProductList.clear();
    isUpcomingInitial = true;
    totalUpcomingData = 0;
    upcomingPage = 1;
    showUpcomingLoadingContainer = false;
    notifyListeners();
  }

  // ============================================================
  // ✅ ADDED: Reset Ended Products
  // ============================================================
  resetEndedProductList() {
    endedProductList.clear();
    isEndedInitial = true;
    totalEndedData = 0;
    endedPage = 1;
    showEndedLoadingContainer = false;
    notifyListeners();
  }

  // ============================================================
  // ✅ ADDED: Reset All Auctions
  // ============================================================
  resetAllAuctionsList() {
    allAuctionsList.clear();
    isAllAuctionsInitial = true;
    totalAllAuctionsData = 0;
    allAuctionsPage = 1;
    showAllAuctionsLoadingContainer = false;
    notifyListeners();
  }


  mainScrollListener() {
    mainScrollController.addListener(() {
      if (mainScrollController.position.pixels ==
          mainScrollController.position.maxScrollExtent) {
        allProductPage++;
        showAllLoadingContainer = true;
        fetchAllProducts();
      }
    });
  }

  hotAuctionScrollListener() {
    if (hotAuctionScrollController != null) {
      hotAuctionScrollController!.addListener(() {
        if (hotAuctionScrollController!.position.pixels ==
            hotAuctionScrollController!.position.maxScrollExtent) {
          if (hotAuctionProductList.length < (totalHotAuctionData ?? 0)) {
            hotAuctionPage++;
            showHotAuctionLoadingContainer = true;
            fetchHotAuctionProducts();
          }
        }
      });
    }
  }

  endingSoonScrollListener() {
    if (endingSoonScrollController != null) {
      endingSoonScrollController!.addListener(() {
        if (endingSoonScrollController!.position.pixels ==
            endingSoonScrollController!.position.maxScrollExtent) {
          if (endingSoonProductList.length < (totalEndingSoonData ?? 0)) {
            endingSoonPage++;
            showEndingSoonLoadingContainer = true;
            fetchEndingSoonProducts();
          }
        }
      });
    }
  }

  upcomingScrollListener() {
    if (upcomingScrollController != null) {
      upcomingScrollController!.addListener(() {
        if (upcomingScrollController!.position.pixels ==
            upcomingScrollController!.position.maxScrollExtent) {
          if (upcomingProductList.length < (totalUpcomingData ?? 0)) {
            upcomingPage++;
            showUpcomingLoadingContainer = true;
            fetchUpcomingProducts();
          }
        }
      });
    }
  }


  // ============================================================
  // ✅ ADDED: All Auctions Scroll Listener
  // ============================================================
  allAuctionsScrollListener() {
    if (allAuctionsScrollController != null) {
      allAuctionsScrollController!.addListener(() {
        if (allAuctionsScrollController!.position.pixels ==
            allAuctionsScrollController!.position.maxScrollExtent) {
          if (allAuctionsList.length < (totalAllAuctionsData ?? 0)) {
            allAuctionsPage++;
            showAllAuctionsLoadingContainer = true;
            fetchAllAuctions();
          }
        }
      });
    }
  }

  // ============================================================
  // ✅ ADDED: Ended Products Scroll Listener
  // ============================================================
  endedScrollListener() {
    // You can add a scroll controller for ended products if needed
    // For now, it's optional since we only show a few in the home page
  }

  void initScrollControllers() {
    hotAuctionScrollController = ScrollController();
    endingSoonScrollController = ScrollController();
    upcomingScrollController = ScrollController();
    allProductScrollController = ScrollController();
    featuredCategoryScrollController = ScrollController();
    allAuctionsScrollController = ScrollController();
    
    hotAuctionScrollListener();
    endingSoonScrollListener();
    upcomingScrollListener();
    allAuctionsScrollListener();
  }

  initPiratedAnimation(vnc) {
    pirated_logo_controller =
        AnimationController(vsync: vnc, duration: Duration(milliseconds: 2000));
    pirated_logo_animation = Tween(begin: 40.0, end: 60.0).animate(
        CurvedAnimation(
            curve: Curves.bounceOut, parent: pirated_logo_controller));

    pirated_logo_controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        pirated_logo_controller.repeat();
      }
    });

    pirated_logo_controller.forward();
  }

  incrementCurrentSlider(index) {
    current_slider = index;
    notifyListeners();
  }

  @override
  void dispose() {
    pirated_logo_controller.dispose();
    hotAuctionScrollController?.dispose();
    endingSoonScrollController?.dispose();
    upcomingScrollController?.dispose();
    allProductScrollController?.dispose();
    featuredCategoryScrollController?.dispose();
    allAuctionsScrollController?.dispose();
    notifyListeners();
    super.dispose();
  }
}