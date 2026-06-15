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
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
  
  // Price range state (using buttons instead of inputs)
  double _minPrice = 0;
  double _maxPrice = 0;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 0;
  List<double> _priceRanges = [0, 25, 50, 100, 200, 500, 1000];
  
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
  bool _isSortDrawerOpen = false;
  
  // Total products found
  int _totalProductsFound = 0;

  @override
  void initState() {
    super.initState();
    _fetchFilteredCategories();
    _fetchProductData();
    _setupScrollListeners();
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
      max: _selectedMaxPrice > 0 ? _selectedMaxPrice.toString() : "",
      min: _selectedMinPrice > 0 ? _selectedMinPrice.toString() : "",
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

  void _onSortChange(String value) {
    setState(() {
      _selectedSort = value == "" ? null : value;
      _productPage = 1;
      _productList.clear();
      _isProductInitial = true;
      _showProductLoadingContainer = false;
    });
    _fetchProductData();
    _closeSortDrawer();
  }

  void _applyFilter() {
    _resetProductList();
    _closeFilterDrawer();
  }

  void _clearFilters() {
    setState(() {
      _selectedMinPrice = 0;
      _selectedMaxPrice = 0;
      _selectedCategories.clear();
    });
  }

  void _openFilterDrawer() => setState(() => _isFilterDrawerOpen = true);
  void _closeFilterDrawer() => setState(() => _isFilterDrawerOpen = false);
  void _openSortDrawer() => setState(() => _isSortDrawerOpen = true);
  void _closeSortDrawer() => setState(() => _isSortDrawerOpen = false);

  Future<void> _onRefresh() async {
    _resetProductList();
  }

  String _getTitle() {
    if (widget.categoryName != null && widget.categoryName!.isNotEmpty) {
      return widget.categoryName!;
    }
    return AppLocalizations.of(context)!.all_products_ucf;
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
            
            // Filter Bottom Sheet (70% height)
            if (_isFilterDrawerOpen)
              _buildFilterBottomSheet(),
            
            // Sort Bottom Sheet
            if (_isSortDrawerOpen)
              _buildSortBottomSheet(),
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
          // Back button and title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Products count
          Text(
            '$_totalProductsFound ${AppLocalizations.of(context)!.products_found}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          // Sort and Filter buttons row
          Row(
            children: [
              // Sort Button
              Expanded(
                child: GestureDetector(
                  onTap: _openSortDrawer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_vert, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.sort_ucf,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              Expanded(
                child: GestureDetector(
                  onTap: _openFilterDrawer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.filter_ucf,
                          style: const TextStyle(fontSize: 14),
                        ),
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
                            // Price Range Section
                            Text(
                              AppLocalizations.of(context)!.price_range_ucf,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            // Price buttons (like HTML)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _priceRanges.map((price) {
                                final bool isSelected = _selectedMinPrice == 0 && price == 0
                                    ? _selectedMaxPrice == 0
                                    : _selectedMinPrice == 0 && _selectedMaxPrice == price;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (price == 0) {
                                        _selectedMinPrice = 0;
                                        _selectedMaxPrice = 0;
                                      } else {
                                        _selectedMinPrice = 0;
                                        _selectedMaxPrice = price;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? MyTheme.accent_color : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? MyTheme.accent_color : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      price == 0 ? AppLocalizations.of(context)!.any_ucf : '\$${price.toStringAsFixed(0)}+',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            
                            // Custom Price Range
                            Text(
                              AppLocalizations.of(context)!.custom_range_ucf,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPriceRangeField(
                                    hint: AppLocalizations.of(context)!.min_ucf,
                                    value: _selectedMinPrice,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMinPrice = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text("-"),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPriceRangeField(
                                    hint: AppLocalizations.of(context)!.max_ucf,
                                    value: _selectedMaxPrice,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMaxPrice = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Categories Section
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

  Widget _buildPriceRangeField({
    required String hint,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            onChanged(double.tryParse(value) ?? 0);
          } else {
            onChanged(0);
          }
        },
      ),
    );
  }

  Widget _buildSortBottomSheet() {
    return GestureDetector(
      onTap: _closeSortDrawer,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.7,
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
                            AppLocalizations.of(context)!.sort_by_ucf,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: _closeSortDrawer,
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
                    // Sort Options
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
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

  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSort == value;
    return GestureDetector(
      onTap: () => _onSortChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? MyTheme.accent_color.withOpacity(0.1) : Colors.transparent,
        ),
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
            top: MediaQuery.of(context).padding.top + 140,
            bottom: 20,
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