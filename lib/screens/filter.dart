import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/reg_ex_inpur_formatter.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/brand_repository.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/search_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:active_ecommerce_flutter/screens/notifications_page.dart';
import 'package:active_ecommerce_flutter/screens/affiliate_page.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class Filter extends StatefulWidget {
  Filter({
    Key? key,
    this.selected_filter = "product",
    this.categoryName,
    this.categoryId,
  }) : super(key: key);

  final String selected_filter;
  final String? categoryName;
  final int? categoryId;

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  ScrollController _productScrollController = ScrollController();
  
  // Filter state
  List<dynamic> _selectedCategories = [];
  String? _selectedSort = "";
  String? _searchKey = "";
  TextEditingController _searchController = TextEditingController();
  
  // Price range state (using slider)
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _minPossiblePrice = 0;
  double _maxPossiblePrice = 1000;
  
  // Data lists
  List<dynamic> _productList = [];
  List<dynamic> _filterCategoryList = [];
  
  // Loading states
  bool _isProductInitial = true;
  
  // Pagination
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;
  
  // Bottom sheet visibility
  bool _isFilterDrawerOpen = false;
  
  // Total products found
  int _totalProductsFound = 0;
  
  // Track selected sort label for display
  String _selectedSortLabel = "";
  
  // Header state
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
    _fetchFilteredCategories();
    _fetchProductData();
    _setupScrollListeners();
    _updateSortLabel();
    _fetchCounts();
  }

  void _updateSortLabel() {
    switch (_selectedSort) {
      case "newest":
        _selectedSortLabel = AppLocalizations.of(context)!.newest_ucf;
        break;
      case "oldest":
        _selectedSortLabel = AppLocalizations.of(context)!.oldest_ucf;
        break;
      case "price_low_to_high":
        _selectedSortLabel = AppLocalizations.of(context)!.price_low_to_high;
        break;
      case "price_high_to_low":
        _selectedSortLabel = AppLocalizations.of(context)!.price_high_to_low;
        break;
      case "popularity":
        _selectedSortLabel = AppLocalizations.of(context)!.popularity_ucf;
        break;
      case "top_rated":
        _selectedSortLabel = AppLocalizations.of(context)!.top_rated_ucf;
        break;
      default:
        _selectedSortLabel = AppLocalizations.of(context)!.default_ucf;
    }
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

  void _redirectToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
  }

  void _setupScrollListeners() {
    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels >= 
          _productScrollController.position.maxScrollExtent - 100) {
        if (!_showProductLoadingContainer && _productList.length < (_totalProductData ?? 0)) {
          setState(() {
            _productPage++;
            _showProductLoadingContainer = true;
          });
          _fetchProductData();
        }
      }
    });
  }

  void _fetchFilteredCategories() async {
    var response = await CategoryRepository().getFilterPageCategories();
    setState(() {
      _filterCategoryList = response.categories ?? [];
    });
  }

  Future<void> _fetchProductData() async {
    var response = await ProductRepository().getFilteredProducts(
      page: _productPage,
      name: _searchKey,
      sort_key: _selectedSort,
      brands: "",
      categories: _selectedCategories.join(","),
      max: _priceRange.end > 0 ? _priceRange.end.toString() : "",
      min: _priceRange.start > 0 ? _priceRange.start.toString() : "",
    );
    
    setState(() {
      _productList.addAll(response.products ?? []);
      _isProductInitial = false;
      _totalProductData = response.meta?.total ?? 0;
      _totalProductsFound = response.meta?.total ?? 0;
      _showProductLoadingContainer = false;
    });
  }

  void _resetProductList() {
    setState(() {
      _productList.clear();
      _isProductInitial = true;
      _totalProductData = 0;
      _productPage = 1;
      _showProductLoadingContainer = false;
    });
    _fetchProductData();
  }

  void _onSearchSubmit() {
    _resetProductList();
  }

  void _onSortChange(String value, String label) {
    setState(() {
      _selectedSort = value == "" ? null : value;
      _selectedSortLabel = label;
      _productPage = 1;
      _productList.clear();
      _isProductInitial = true;
      _showProductLoadingContainer = false;
    });
    _fetchProductData();
  }

  void _applyFilter() {
    _resetProductList();
    _closeFilterDrawer();
  }

  void _clearFilters() {
    setState(() {
      _priceRange = RangeValues(_minPossiblePrice, _maxPossiblePrice);
      _selectedCategories.clear();
    });
  }

  void _openFilterDrawer() => setState(() => _isFilterDrawerOpen = true);
  void _closeFilterDrawer() => setState(() => _isFilterDrawerOpen = false);

  Future<void> _onRefresh() async {
    _resetProductList();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppLocalizations.of(context)!.sort_by_ucf,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption("", AppLocalizations.of(context)!.default_ucf),
              _buildSortOption("newest", AppLocalizations.of(context)!.newest_ucf),
              _buildSortOption("oldest", AppLocalizations.of(context)!.oldest_ucf),
              _buildSortOption("price_low_to_high", AppLocalizations.of(context)!.price_low_to_high),
              _buildSortOption("price_high_to_low", AppLocalizations.of(context)!.price_high_to_low),
              _buildSortOption("popularity", AppLocalizations.of(context)!.popularity_ucf),
              _buildSortOption("top_rated", AppLocalizations.of(context)!.top_rated_ucf),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel_ucf,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSort == value;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _onSortChange(value, label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? MyTheme.accent_color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MyTheme.accent_color : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Main Content
            _buildProductList(),
            
            // Top Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),
            
            // Loading Indicator
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildProductLoadingContainer(),
            ),
            
            // Filter Bottom Sheet
            if (_isFilterDrawerOpen)
              _buildFilterBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Row (from Home page)
          Row(
            children: [
              Expanded(child: _buildSearchBox()),
              // Notification Icon
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
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
          const SizedBox(height: 12),
          // Products count
          Text(
            '$_totalProductsFound ${AppLocalizations.of(context)!.products_found}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          // Sort and Filter buttons row - Sort 30%, Filter 10% of parent width
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Sort Button - 30% width
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: GestureDetector(
                  onTap: _showSortDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_vert, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedSortLabel.isNotEmpty ? _selectedSortLabel : AppLocalizations.of(context)!.sort_ucf,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button - 10% width
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: GestureDetector(
                  onTap: _openFilterDrawer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return GestureDetector(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    _searchKey = value;
                    _resetProductList();
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search_anything,
                    hintStyle: TextStyle(fontSize: 13.0, color: MyTheme.textfield_grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchKey = _searchController.text;
                    _resetProductList();
                  }
                },
                child: Image.asset('assets/search.png', height: 16, color: MyTheme.dark_grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return GestureDetector(
      onTap: _closeFilterDrawer,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.filters_ucf,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: _closeFilterDrawer,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories Section (moved to top)
                            Text(
                              AppLocalizations.of(context)!.categories_ucf,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ..._filterCategoryList.map((category) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedCategories.contains(category.id)) {
                                      _selectedCategories.remove(category.id);
                                    } else {
                                      _selectedCategories.add(category.id);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedCategories.contains(category.id) 
                                        ? MyTheme.accent_color 
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          category.name ?? '',
                                          style: TextStyle(
                                            color: _selectedCategories.contains(category.id) 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (_selectedCategories.contains(category.id))
                                        const Icon(Icons.check, size: 16, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                            
                            const SizedBox(height: 24),
                            
                            // Price Range Section (moved below categories)
                            Text(
                              AppLocalizations.of(context)!.price_range_ucf,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            
                            // Price Range Slider
                            RangeSlider(
                              values: _priceRange,
                              min: _minPossiblePrice,
                              max: _maxPossiblePrice,
                              divisions: 100,
                              activeColor: MyTheme.accent_color,
                              inactiveColor: Colors.grey.shade300,
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _priceRange = values;
                                });
                              },
                              labels: RangeLabels(
                                '\$${_priceRange.start.toStringAsFixed(0)}',
                                '\$${_priceRange.end.toStringAsFixed(0)}',
                              ),
                            ),
                            
                            // Min/Max Labels
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Min: \$${_priceRange.start.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    'Max: \$${_priceRange.end.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _clearFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.clear_all_ucf,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _applyFilter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.apply_ucf,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isProductInitial && _productList.isEmpty) {
      return ShimmerHelper().buildProductGridShimmer(scontroller: _productScrollController);
    } else if (_productList.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: MyTheme.accent_color,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 180,
            bottom: 70, // Space for bottom navigation bar
          ),
          child: MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            padding: const EdgeInsets.all(12),
            itemCount: _productList.length,
            itemBuilder: (context, index) => ProductCard(
              id: _productList[index].id,
              slug: _productList[index].slug,
              image: _productList[index].thumbnail_image,
              name: _productList[index].name,
              main_price: _productList[index].main_price,
              stroked_price: _productList[index].stroked_price,
              has_discount: _productList[index].has_discount,
              discount: _productList[index].discount,
              is_wholesale: _productList[index].isWholesale,
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    }
  }

  Widget _buildProductLoadingContainer() {
    if (!_showProductLoadingContainer) return const SizedBox.shrink();
    return Container(
      height: 36,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(_totalProductData == _productList.length
          ? AppLocalizations.of(context)!.no_more_products_ucf
          : AppLocalizations.of(context)!.loading_more_products_ucf),
    );
  }
}