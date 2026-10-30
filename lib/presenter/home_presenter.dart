
import 'dart:async';

import 'package:active_ecommerce_flutter/data_model/slider_response.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/flash_deal_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/sliders_repository.dart';
import 'package:flutter/material.dart';

class AuctionStatusCategoryItem {
  final int id;
  final String name;
  final IconData icon;

  const AuctionStatusCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class HomePresenter extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

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

  final ProductRepository _productRepository = ProductRepository();

  // ============================================================
  // CAROUSEL AND BANNERS
  // ============================================================

  List<AIZSlider> carouselImageList = [];
  List<AIZSlider> bannerOneImageList = [];
  List bannerTwoImageList = [];

  bool isCarouselInitial = true;
  bool isBannerOneInitial = true;
  bool isBannerTwoInitial = true;

  // ============================================================
  // FEATURED CATEGORIES
  // ============================================================

  List featuredCategoryList = [];
  bool isCategoryInitial = true;

  // ============================================================
  // FEATURED PRODUCTS
  // ============================================================

  List featuredProductList = [];
  bool isFeaturedProductInitial = true;
  int? totalFeaturedProductData = 0;
  int featuredProductPage = 1;
  bool showFeaturedLoadingContainer = false;

  // ============================================================
  // HOT AUCTIONS
  // ============================================================

  List hotAuctionProductList = [];
  bool isHotAuctionInitial = true;
  int? totalHotAuctionData = 0;
  int hotAuctionPage = 1;
  bool showHotAuctionLoadingContainer = false;

  // ============================================================
  // ENDING SOON
  // ============================================================

  List endingSoonProductList = [];
  bool isEndingSoonInitial = true;
  int? totalEndingSoonData = 0;
  int endingSoonPage = 1;
  bool showEndingSoonLoadingContainer = false;

  // ============================================================
  // UPCOMING
  // ============================================================

  List upcomingProductList = [];
  bool isUpcomingInitial = true;
  int? totalUpcomingData = 0;
  int upcomingPage = 1;
  bool showUpcomingLoadingContainer = false;

  // ============================================================
  // ENDED AUCTIONS
  // ============================================================

  List endedProductList = [];
  bool isEndedInitial = true;
  int? totalEndedData = 0;
  int endedPage = 1;
  bool showEndedLoadingContainer = false;

  // ============================================================
  // ALL AUCTIONS
  // ============================================================

  List allAuctionsList = [];
  bool isAllAuctionsInitial = true;
  int? totalAllAuctionsData = 0;
  int allAuctionsPage = 1;
  bool showAllAuctionsLoadingContainer = false;

  // ============================================================
  // REGULAR PRODUCTS
  // ============================================================

  List allProductList = [];
  bool isAllProductInitial = true;
  int? totalAllProductData = 0;
  int allProductPage = 1;
  bool showAllLoadingContainer = false;

  // ============================================================
  // DEALS AND CART
  // ============================================================

  bool isTodayDeal = false;
  bool isFlashDeal = false;

  int cartCount = 0;

  // ============================================================
  // INDEPENDENT HOMEPAGE CATEGORY SECTION
  //
  // This section has its own state and pagination.
  // It does not modify the Hot, Ending Soon, Upcoming,
  // Ended or All Auctions lists.
  // ============================================================

  final List<AuctionStatusCategoryItem> auctionStatusCategoryList = [
    AuctionStatusCategoryItem(
      id: 37,
      name: 'Hot Auctions',
      icon: Icons.local_fire_department_rounded,
    ),
    AuctionStatusCategoryItem(
      id: 26,
      name: 'Ending Soon',
      icon: Icons.timer_rounded,
    ),
    AuctionStatusCategoryItem(
      id: 27,
      name: 'Upcoming',
      icon: Icons.calendar_month_rounded,
    ),
  ];

  List categorySectionProductList = [];

  bool isCategorySectionInitial = true;
  bool showCategorySectionLoading = false;

  int? totalCategorySectionProducts = 0;

  int categorySectionPage = 1;

  // Number of products currently displayed in the preview.
  int categorySectionVisibleCount = 6;

  int? selectedCategorySectionId;
  String selectedCategorySectionType = 'all';

  // Prevents an old request from replacing a newer selection.
  int _categorySectionRequestId = 0;

  bool get hasMoreCategorySectionProducts {
    final total = totalCategorySectionProducts ??
        categorySectionProductList.length;

    return categorySectionVisibleCount < total;
  }

  // ============================================================
  // FETCH ALL HOMEPAGE DATA
  // ============================================================

  void fetchAll() {
    fetchCarouselImages();
    fetchBannerOneImages();
    fetchBannerTwoImages();
    fetchFeaturedCategories();

    // Independent category section.
    fetchCategorySectionProducts(
      categoryId: null,
      type: 'all',
      resetList: true,
    );

    // Existing homepage sections remain independent.
    fetchFeaturedProducts();
    fetchAllProducts();
    fetchHotAuctionProducts();
    fetchEndingSoonProducts();
    fetchUpcomingProducts();
    fetchEndedProducts();
    fetchAllAuctions();
    fetchTodayDealData();
    fetchFlashDealData();
  }

  // ============================================================
  // FETCH CATEGORY SECTION PRODUCTS
  //
  // type = all       -> regular products endpoint
  // type = category  -> selected featured category
  // type = status    -> Hot / Ending Soon / Upcoming endpoint
  // ============================================================

  Future<void> fetchCategorySectionProducts({
    int? categoryId,
    String type = 'all',
    bool resetList = true,
    int? visibleCountAfterFetch,
  }) async {
    if (!resetList && showCategorySectionLoading) {
      return;
    }

    if (resetList) {
      selectedCategorySectionId = categoryId;
      selectedCategorySectionType = type;

      categorySectionProductList.clear();
      categorySectionPage = 1;
      categorySectionVisibleCount = 6;
      totalCategorySectionProducts = 0;

      isCategorySectionInitial = true;
    }

    final int requestId = ++_categorySectionRequestId;
    final int requestPage =
        resetList ? 1 : categorySectionPage;

    showCategorySectionLoading = true;
    notifyListeners();

    try {
      final response = await _getCategorySectionResponse(
        categoryId: categoryId,
        type: type,
        page: requestPage,
      );

      // Ignore outdated responses.
      if (requestId != _categorySectionRequestId) {
        return;
      }

      final incomingProducts = response.products ?? [];

      categorySectionProductList.addAll(incomingProducts);

      totalCategorySectionProducts =
          response.meta?.total ??
          categorySectionProductList.length;

      if (incomingProducts.isNotEmpty) {
        categorySectionPage = requestPage + 1;
      }

      if (visibleCountAfterFetch != null) {
        final total = totalCategorySectionProducts ??
            categorySectionProductList.length;

        categorySectionVisibleCount =
            visibleCountAfterFetch > total
                ? total
                : visibleCountAfterFetch;
      }

      isCategorySectionInitial = false;
      showCategorySectionLoading = false;

      notifyListeners();
    } catch (e) {
      if (requestId != _categorySectionRequestId) {
        return;
      }

      debugPrint('Category section error: $e');

      isCategorySectionInitial = false;
      showCategorySectionLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CATEGORY SECTION API ROUTING
  // ============================================================

  Future<dynamic> _getCategorySectionResponse({
    required int? categoryId,
    required String type,
    required int page,
  }) async {
    // ALL
    if (type == 'all') {
      return await _productRepository.getFilteredProducts(
        page: page,
      );
    }

    // FEATURED CATEGORY
    if (type == 'category' && categoryId != null) {
      return await _productRepository.getCategoryProducts(
        id: categoryId.toString(),
        page: page,
      );
    }

    // AUCTION STATUS
    if (type == 'status') {
      switch (categoryId) {
        case 37:
          return await _productRepository.getHotAuctions(
            page: page,
          );

        case 26:
          return await _productRepository.getEndingSoonProducts(
            page: page,
          );

        case 27:
          return await _productRepository.getUpcomingProducts(
            page: page,
          );
      }
    }

    // Safe fallback.
    return await _productRepository.getFilteredProducts(
      page: page,
    );
  }

  // ============================================================
  // SELECT CATEGORY OR STATUS FILTER
  // ============================================================

  void selectCategorySectionFilter({
    int? categoryId,
    required String type,
  }) {
    if (selectedCategorySectionId == categoryId &&
        selectedCategorySectionType == type &&
        !isCategorySectionInitial) {
      return;
    }

    fetchCategorySectionProducts(
      categoryId: categoryId,
      type: type,
      resetList: true,
    );
  }

  // ============================================================
  // LOAD MORE CATEGORY SECTION PRODUCTS
  // ============================================================

  Future<void> loadMoreCategorySectionProducts() async {
    if (showCategorySectionLoading ||
        isCategorySectionInitial ||
        !hasMoreCategorySectionProducts) {
      return;
    }

    final total = totalCategorySectionProducts ??
        categorySectionProductList.length;

    final desiredCount =
        categorySectionVisibleCount + 6 > total
            ? total
            : categorySectionVisibleCount + 6;

    // Products are already in memory. No API request needed.
    if (categorySectionProductList.length >= desiredCount) {
      categorySectionVisibleCount = desiredCount;
      notifyListeners();
      return;
    }

    // Fetch the next API page.
    await fetchCategorySectionProducts(
      categoryId: selectedCategorySectionId,
      type: selectedCategorySectionType,
      resetList: false,
      visibleCountAfterFetch: desiredCount,
    );
  }

  // ============================================================
  // RESET CATEGORY SECTION ONLY
  // ============================================================

  void resetCategorySection() {
    // Invalidate requests still running.
    _categorySectionRequestId++;

    categorySectionProductList.clear();

    isCategorySectionInitial = true;
    showCategorySectionLoading = false;

    totalCategorySectionProducts = 0;
    categorySectionPage = 1;
    categorySectionVisibleCount = 6;

    selectedCategorySectionId = null;
    selectedCategorySectionType = 'all';

    notifyListeners();
  }

  // ============================================================
  // TODAY'S DEAL
  // ============================================================

  Future<void> fetchTodayDealData() async {
    try {
      final deal =
          await _productRepository.getTodaysDealProducts();

      if (deal.success == true &&
          (deal.products ?? []).isNotEmpty) {
        isTodayDeal = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching today deal: $e');
    }
  }

  // ============================================================
  // FLASH DEAL
  // ============================================================

  Future<void> fetchFlashDealData() async {
    try {
      final deal = await FlashDealRepository().getFlashDeals();

      if (deal.success == true &&
          (deal.flashDeals ?? []).isNotEmpty) {
        isFlashDeal = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching flash deal: $e');
    }
  }

  // ============================================================
  // CAROUSEL
  // ============================================================

  Future<void> fetchCarouselImages() async {
    try {
      final response = await SlidersRepository().getSliders();

      carouselImageList
        ..clear()
        ..addAll(response.sliders ?? []);

      isCarouselInitial = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching carousel images: $e');
      isCarouselInitial = false;
      notifyListeners();
    }
  }

  // ============================================================
  // BANNER ONE
  // ============================================================

  Future<void> fetchBannerOneImages() async {
    try {
      final response =
          await SlidersRepository().getBannerOneImages();

      bannerOneImageList
        ..clear()
        ..addAll(response.sliders ?? []);

      isBannerOneInitial = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching banner one: $e');
      isBannerOneInitial = false;
      notifyListeners();
    }
  }

  // ============================================================
  // BANNER TWO
  // ============================================================

  Future<void> fetchBannerTwoImages() async {
    try {
      final response =
          await SlidersRepository().getBannerTwoImages();

      bannerTwoImageList
        ..clear()
        ..addAll(response.sliders ?? []);

      isBannerTwoInitial = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching banner two: $e');
      isBannerTwoInitial = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FEATURED CATEGORIES
  // ============================================================

  Future<void> fetchFeaturedCategories() async {
    try {
      final response =
          await CategoryRepository().getFeturedCategories();

      featuredCategoryList
        ..clear()
        ..addAll(response.categories ?? []);

      isCategoryInitial = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching featured categories: $e');
      isCategoryInitial = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FEATURED PRODUCTS
  // ============================================================

  Future<void> fetchFeaturedProducts() async {
    try {
      final response =
          await _productRepository.getFeaturedProducts(
        page: featuredProductPage,
      );

      featuredProductPage++;

      featuredProductList.addAll(response.products ?? []);

      isFeaturedProductInitial = false;
      totalFeaturedProductData = response.meta?.total ?? 0;
      showFeaturedLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      isFeaturedProductInitial = false;
      showFeaturedLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // HOT AUCTION PRODUCTS
  // ============================================================

  Future<void> fetchHotAuctionProducts() async {
    try {
      final response =
          await _productRepository.getHotAuctions(
        page: hotAuctionPage,
      );

      hotAuctionPage++;

      hotAuctionProductList.addAll(response.products ?? []);

      isHotAuctionInitial = false;
      totalHotAuctionData = response.meta?.total ?? 0;
      showHotAuctionLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching hot auction products: $e');
      isHotAuctionInitial = false;
      showHotAuctionLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ENDING SOON PRODUCTS
  // ============================================================

  Future<void> fetchEndingSoonProducts() async {
    try {
      final response =
          await _productRepository.getEndingSoonProducts(
        page: endingSoonPage,
      );

      endingSoonPage++;

      endingSoonProductList.addAll(response.products ?? []);

      isEndingSoonInitial = false;
      totalEndingSoonData = response.meta?.total ?? 0;
      showEndingSoonLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching ending soon products: $e');
      isEndingSoonInitial = false;
      showEndingSoonLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPCOMING PRODUCTS
  // ============================================================

  Future<void> fetchUpcomingProducts() async {
    try {
      final response =
          await _productRepository.getUpcomingProducts(
        page: upcomingPage,
      );

      upcomingPage++;

      upcomingProductList.addAll(response.products ?? []);

      isUpcomingInitial = false;
      totalUpcomingData = response.meta?.total ?? 0;
      showUpcomingLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching upcoming products: $e');
      isUpcomingInitial = false;
      showUpcomingLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ENDED PRODUCTS
  // ============================================================

  Future<void> fetchEndedProducts() async {
    try {
      final response =
          await _productRepository.getEndedProducts(
        page: endedPage,
      );

      endedPage++;

      endedProductList.addAll(response.products ?? []);

      isEndedInitial = false;
      totalEndedData = response.meta?.total ?? 0;
      showEndedLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching ended products: $e');
      isEndedInitial = false;
      showEndedLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REGULAR PRODUCTS
  // ============================================================

  Future<void> fetchAllProducts() async {
    try {
      final response =
          await _productRepository.getFilteredProducts(
        page: allProductPage,
      );

      allProductList.addAll(response.products ?? []);

      isAllProductInitial = false;
      totalAllProductData = response.meta?.total ?? 0;
      showAllLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all products: $e');
      isAllProductInitial = false;
      showAllLoadingContainer = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ALL AUCTIONS
  // ============================================================

  Future<void> fetchAllAuctions() async {
    try {
      final response =
          await _productRepository.getAllProducts(
        page: allAuctionsPage,
      );

      allAuctionsList.addAll(response.products ?? []);

      allAuctionsPage++;

      isAllAuctionsInitial = false;
      totalAllAuctionsData = response.meta?.total ?? 0;
      showAllAuctionsLoadingContainer = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all auctions: $e');

      isAllAuctionsInitial = false;
      showAllAuctionsLoadingContainer = false;

      notifyListeners();
    }
  }

  // ============================================================
  // RESET ALL HOMEPAGE DATA
  // ============================================================

  void reset() {
    carouselImageList.clear();
    bannerOneImageList.clear();
    bannerTwoImageList.clear();
    featuredCategoryList.clear();

    isCarouselInitial = true;
    isBannerOneInitial = true;
    isBannerTwoInitial = true;
    isCategoryInitial = true;

    cartCount = 0;

    resetCategorySection();

    resetFeaturedProductList();
    resetAllProductList();
    resetHotAuctionProductList();
    resetEndingSoonProductList();
    resetUpcomingProductList();
    resetEndedProductList();
    resetAllAuctionsList();
  }

  Future<void> onRefresh() async {
    reset();
    fetchAll();
  }

  // ============================================================
  // RESET FEATURED PRODUCTS
  // ============================================================

  void resetFeaturedProductList() {
    featuredProductList.clear();

    isFeaturedProductInitial = true;
    totalFeaturedProductData = 0;
    featuredProductPage = 1;
    showFeaturedLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET REGULAR PRODUCTS
  // ============================================================

  void resetAllProductList() {
    allProductList.clear();

    isAllProductInitial = true;
    totalAllProductData = 0;
    allProductPage = 1;
    showAllLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET HOT AUCTIONS
  // ============================================================

  void resetHotAuctionProductList() {
    hotAuctionProductList.clear();

    isHotAuctionInitial = true;
    totalHotAuctionData = 0;
    hotAuctionPage = 1;
    showHotAuctionLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET ENDING SOON
  // ============================================================

  void resetEndingSoonProductList() {
    endingSoonProductList.clear();

    isEndingSoonInitial = true;
    totalEndingSoonData = 0;
    endingSoonPage = 1;
    showEndingSoonLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET UPCOMING
  // ============================================================

  void resetUpcomingProductList() {
    upcomingProductList.clear();

    isUpcomingInitial = true;
    totalUpcomingData = 0;
    upcomingPage = 1;
    showUpcomingLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET ENDED AUCTIONS
  // ============================================================

  void resetEndedProductList() {
    endedProductList.clear();

    isEndedInitial = true;
    totalEndedData = 0;
    endedPage = 1;
    showEndedLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // RESET ALL AUCTIONS
  // ============================================================

  void resetAllAuctionsList() {
    allAuctionsList.clear();

    isAllAuctionsInitial = true;
    totalAllAuctionsData = 0;
    allAuctionsPage = 1;
    showAllAuctionsLoadingContainer = false;

    notifyListeners();
  }

  // ============================================================
  // MAIN PRODUCT SCROLL LISTENER
  // ============================================================

  void mainScrollListener() {
    mainScrollController.addListener(() {
      if (!mainScrollController.hasClients) return;

      if (mainScrollController.position.pixels >=
          mainScrollController.position.maxScrollExtent) {
        if (!showAllLoadingContainer &&
            allProductList.length < (totalAllProductData ?? 0)) {
          allProductPage++;
          showAllLoadingContainer = true;
          fetchAllProducts();
        }
      }
    });
  }

  // ============================================================
  // HOT AUCTION SCROLL LISTENER
  // ============================================================

  void hotAuctionScrollListener() {
    if (hotAuctionScrollController == null) return;

    hotAuctionScrollController!.addListener(() {
      if (!hotAuctionScrollController!.hasClients) return;

      if (hotAuctionScrollController!.position.pixels >=
          hotAuctionScrollController!.position.maxScrollExtent) {
        if (!showHotAuctionLoadingContainer &&
            hotAuctionProductList.length <
                (totalHotAuctionData ?? 0)) {
          showHotAuctionLoadingContainer = true;
          fetchHotAuctionProducts();
        }
      }
    });
  }

  // ============================================================
  // ENDING SOON SCROLL LISTENER
  // ============================================================

  void endingSoonScrollListener() {
    if (endingSoonScrollController == null) return;

    endingSoonScrollController!.addListener(() {
      if (!endingSoonScrollController!.hasClients) return;

      if (endingSoonScrollController!.position.pixels >=
          endingSoonScrollController!.position.maxScrollExtent) {
        if (!showEndingSoonLoadingContainer &&
            endingSoonProductList.length <
                (totalEndingSoonData ?? 0)) {
          showEndingSoonLoadingContainer = true;
          fetchEndingSoonProducts();
        }
      }
    });
  }

  // ============================================================
  // UPCOMING SCROLL LISTENER
  // ============================================================

  void upcomingScrollListener() {
    if (upcomingScrollController == null) return;

    upcomingScrollController!.addListener(() {
      if (!upcomingScrollController!.hasClients) return;

      if (upcomingScrollController!.position.pixels >=
          upcomingScrollController!.position.maxScrollExtent) {
        if (!showUpcomingLoadingContainer &&
            upcomingProductList.length < (totalUpcomingData ?? 0)) {
          showUpcomingLoadingContainer = true;
          fetchUpcomingProducts();
        }
      }
    });
  }

  // ============================================================
  // ALL AUCTIONS SCROLL LISTENER
  // ============================================================

  void allAuctionsScrollListener() {
    if (allAuctionsScrollController == null) return;

    allAuctionsScrollController!.addListener(() {
      if (!allAuctionsScrollController!.hasClients) return;

      if (allAuctionsScrollController!.position.pixels >=
          allAuctionsScrollController!.position.maxScrollExtent - 100) {
        if (!showAllAuctionsLoadingContainer &&
            allAuctionsList.length < (totalAllAuctionsData ?? 0)) {
          showAllAuctionsLoadingContainer = true;
          fetchAllAuctions();
        }
      }
    });
  }

  // ============================================================
  // INITIALIZE SCROLL CONTROLLERS
  // ============================================================

  void initScrollControllers() {
    hotAuctionScrollController ??= ScrollController();
    endingSoonScrollController ??= ScrollController();
    upcomingScrollController ??= ScrollController();
    allProductScrollController ??= ScrollController();
    featuredCategoryScrollController ??= ScrollController();
    allAuctionsScrollController ??= ScrollController();

    hotAuctionScrollListener();
    endingSoonScrollListener();
    upcomingScrollListener();
    allAuctionsScrollListener();
  }

  // ============================================================
  // PIRATED ANIMATION
  // ============================================================

  void initPiratedAnimation(vnc) {
    pirated_logo_controller = AnimationController(
      vsync: vnc,
      duration: const Duration(milliseconds: 2000),
    );

    pirated_logo_animation = Tween(
      begin: 40.0,
      end: 60.0,
    ).animate(
      CurvedAnimation(
        curve: Curves.bounceOut,
        parent: pirated_logo_controller,
      ),
    );

    pirated_logo_controller.addStatusListener(
      (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          pirated_logo_controller.repeat();
        }
      },
    );

    pirated_logo_controller.forward();
  }

  // ============================================================
  // SLIDER INDEX
  // ============================================================

  void incrementCurrentSlider(index) {
    current_slider = index;
    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    // Do not call notifyListeners() from dispose().
    // Only dispose the animation if it was initialized.
    try {
      pirated_logo_controller.dispose();
    } catch (_) {
      // Animation was never initialized.
    }

    hotAuctionScrollController?.dispose();
    endingSoonScrollController?.dispose();
    upcomingScrollController?.dispose();
    allProductScrollController?.dispose();
    featuredCategoryScrollController?.dispose();
    allAuctionsScrollController?.dispose();
    mainScrollController.dispose();

    super.dispose();
  }
}
