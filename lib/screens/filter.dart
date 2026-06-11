import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/custom/useful_elements.dart';
import 'package:active_ecommerce_flutter/helpers/reg_ex_inpur_formatter.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/brand_repository.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/search_repository.dart';
import 'package:active_ecommerce_flutter/repositories/shop_repository.dart';
import 'package:active_ecommerce_flutter/screens/activity_page.dart';
import 'package:active_ecommerce_flutter/screens/category_list.dart';
import 'package:active_ecommerce_flutter/screens/home.dart';
import 'package:active_ecommerce_flutter/screens/points_page.dart';
import 'package:active_ecommerce_flutter/screens/profile.dart';
import 'package:active_ecommerce_flutter/screens/seller_details.dart';
import 'package:active_ecommerce_flutter/ui_elements/brand_square_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/shop_square_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:one_context/one_context.dart';
import 'package:toast/toast.dart';

class WhichFilter {
  String option_key;
  String name;

  WhichFilter(this.option_key, this.name);

  static List<WhichFilter> getWhichFilterList() {
    return <WhichFilter>[
      WhichFilter('product', 'Products'),
      WhichFilter('sellers', 'Sellers'),
      WhichFilter('brands', 'Brands'),
    ];
  }
}

class Filter extends StatefulWidget {
  Filter({
    Key? key,
    this.selected_filter = "product",
  }) : super(key: key);

  final String selected_filter;

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final _amountValidator = RegExInputFormatter.withRegex(
      '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$');

  ScrollController _productScrollController = ScrollController();
  ScrollController _brandScrollController = ScrollController();
  ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  WhichFilter? _selectedFilter;
  String? _givenSelectedFilterOptionKey;
  String? _selectedSort = "";

  List<WhichFilter> _which_filter_list = WhichFilter.getWhichFilterList();
  List<DropdownMenuItem<WhichFilter>>? _dropdownWhichFilterItems;
  List<dynamic> _selectedCategories = [];
  List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = new TextEditingController();
  final TextEditingController _minPriceController = new TextEditingController();
  final TextEditingController _maxPriceController = new TextEditingController();

  List<dynamic> _filterBrandList = [];
  bool _filteredBrandsCalled = false;
  List<dynamic> _filterCategoryList = [];
  bool _filteredCategoriesCalled = false;

  List<dynamic> _searchSuggestionList = [];

  String? _searchKey = "";

  List<dynamic> _productList = [];
  bool _isProductInitial = true;
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;

  List<dynamic> _brandList = [];
  bool _isBrandInitial = true;
  int _brandPage = 1;
  int? _totalBrandData = 0;
  bool _showBrandLoadingContainer = false;

  List<dynamic> _shopList = [];
  bool _isShopInitial = true;
  int _shopPage = 1;
  int? _totalShopData = 0;
  bool _showShopLoadingContainer = false;

  // Filter drawer visibility for mobile
  bool _isFilterDrawerOpen = false;
  
  // Bottom navigation current index
  int _currentBottomIndex = 1; // Categories is index 1 in main navigation

  fetchFilteredBrands() async {
    var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
    _filterBrandList.addAll(filteredBrandResponse.brands!);
    _filteredBrandsCalled = true;
    setState(() {});
  }

  fetchFilteredCategories() async {
    var filteredCategoriesResponse =
        await CategoryRepository().getFilterPageCategories();
    _filterCategoryList.addAll(filteredCategoriesResponse.categories!);
    _filteredCategoriesCalled = true;
    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    _brandScrollController.dispose();
    _shopScrollController.dispose();
    super.dispose();
  }

  init() {
    _givenSelectedFilterOptionKey = widget.selected_filter;

    _dropdownWhichFilterItems = buildDropdownWhichFilterItems(_which_filter_list);
    _selectedFilter = _dropdownWhichFilterItems![0].value;

    for (int x = 0; x < _dropdownWhichFilterItems!.length; x++) {
      if (_dropdownWhichFilterItems![x].value!.option_key ==
          _givenSelectedFilterOptionKey) {
        _selectedFilter = _dropdownWhichFilterItems![x].value;
      }
    }

    fetchFilteredCategories();
    fetchFilteredBrands();

    if (_selectedFilter!.option_key == "sellers") {
      fetchShopData();
    } else if (_selectedFilter!.option_key == "brands") {
      fetchBrandData();
    } else {
      fetchProductData();
    }

    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        fetchProductData();
      }
    });

    _brandScrollController.addListener(() {
      if (_brandScrollController.position.pixels ==
          _brandScrollController.position.maxScrollExtent) {
        setState(() {
          _brandPage++;
        });
        _showBrandLoadingContainer = true;
        fetchBrandData();
      }
    });

    _shopScrollController.addListener(() {
      if (_shopScrollController.position.pixels ==
          _shopScrollController.position.maxScrollExtent) {
        setState(() {
          _shopPage++;
        });
        _showShopLoadingContainer = true;
        fetchShopData();
      }
    });
  }

  fetchProductData() async {
    var productResponse = await ProductRepository().getFilteredProducts(
        page: _productPage,
        name: _searchKey,
        sort_key: _selectedSort,
        brands: _selectedBrands.join(",").toString(),
        categories: _selectedCategories.join(",").toString(),
        max: _maxPriceController.text.toString(),
        min: _minPriceController.text.toString());

    _productList.addAll(productResponse.products!);
    _isProductInitial = false;
    _totalProductData = productResponse.meta!.total;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  resetProductList() {
    _productList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  fetchBrandData() async {
    var brandResponse =
        await BrandRepository().getBrands(page: _brandPage, name: _searchKey);
    _brandList.addAll(brandResponse.brands!);
    _isBrandInitial = false;
    _totalBrandData = brandResponse.meta!.total;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  resetBrandList() {
    _brandList.clear();
    _isBrandInitial = true;
    _totalBrandData = 0;
    _brandPage = 1;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  fetchShopData() async {
    var shopResponse =
        await ShopRepository().getShops(page: _shopPage, name: _searchKey);
    _shopList.addAll(shopResponse.shops);
    _isShopInitial = false;
    _totalShopData = shopResponse.meta.total;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _searchSuggestionList.clear();
    setState(() {});
  }

  resetShopList() {
    _shopList.clear();
    _isShopInitial = true;
    _totalShopData = 0;
    _shopPage = 1;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onProductListRefresh() async {
    reset();
    resetProductList();
    fetchProductData();
  }

  Future<void> _onBrandListRefresh() async {
    reset();
    resetBrandList();
    fetchBrandData();
  }

  Future<void> _onShopListRefresh() async {
    reset();
    resetShopList();
    fetchShopData();
  }

  _applyProductFilter() {
    reset();
    resetProductList();
    fetchProductData();
    _closeFilterDrawer();
  }

  _onSearchSubmit() {
    reset();
    if (_selectedFilter!.option_key == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter!.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  _onSortChange() {
    // Reset and reload products with new sort
    _productList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    fetchProductData();
  }

  _onWhichFilterChange() {
    if (_selectedFilter!.option_key == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter!.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
      List which_filter_list) {
    List<DropdownMenuItem<WhichFilter>> items = [];
    for (WhichFilter which_filter_item
        in which_filter_list as Iterable<WhichFilter>) {
      items.add(
        DropdownMenuItem(
          value: which_filter_item,
          child: Text(which_filter_item.name),
        ),
      );
    }
    return items;
  }

  Container buildProductLoadingContainer() {
    return Container(
      height: _showProductLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalProductData == _productList.length
            ? "No more products"
            : "Loading more products"),
      ),
    );
  }

  Container buildBrandLoadingContainer() {
    return Container(
      height: _showBrandLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalBrandData == _brandList.length
            ? "No more brands"
            : "Loading more brands"),
      ),
    );
  }

  Container buildShopLoadingContainer() {
    return Container(
      height: _showShopLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalShopData == _shopList.length
            ? "No more shops"
            : "Loading more shops"),
      ),
    );
  }

  void _openFilterDrawer() {
    setState(() {
      _isFilterDrawerOpen = true;
    });
  }

  void _closeFilterDrawer() {
    setState(() {
      _isFilterDrawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: Column(
              children: [
                _buildSearchBar(),
                _buildBottomAppBar(),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            _selectedFilter!.option_key == 'product'
                ? buildProductList()
                : (_selectedFilter!.option_key == 'brands'
                    ? buildBrandList()
                    : buildShopList()),
            Align(
                alignment: Alignment.bottomCenter,
                child: _selectedFilter!.option_key == 'product'
                    ? buildProductLoadingContainer()
                    : (_selectedFilter!.option_key == 'brands'
                        ? buildBrandLoadingContainer()
                        : buildShopLoadingContainer())),
            // Filter Bottom Sheet
            if (_isFilterDrawerOpen)
              _buildFilterBottomSheet(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 70,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentBottomIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CategoryList(slug: "", is_base_category: true)));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PointsPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ActivityPage()));
              break;
            case 4:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Profile()));
              break;
          }
        },
        currentIndex: _currentBottomIndex,
        backgroundColor: Colors.white.withOpacity(0.95),
        unselectedItemColor: const Color.fromRGBO(168, 175, 179, 1),
        selectedItemColor: MyTheme.accent_color,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.asset(
                "assets/home.png",
                color: _currentBottomIndex == 0
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.asset(
                "assets/categories.png",
                color: _currentBottomIndex == 1
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16,
              ),
            ),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.asset(
                "assets/crown.png",
                color: _currentBottomIndex == 2
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16,
              ),
            ),
            label: 'Points',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.asset(
                "assets/task-square.png",
                color: _currentBottomIndex == 3
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16,
              ),
            ),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.asset(
                "assets/profile.png",
                color: _currentBottomIndex == 4
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16,
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (txt) {
                  _searchKey = txt;
                  setState(() {});
                  _onSearchSubmit();
                },
                decoration: const InputDecoration(
                  hintText: 'Search Here...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchKey = "";
                  setState(() {});
                  _onSearchSubmit();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close, size: 16, color: Color(0xFF999999)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Type Dropdown
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<WhichFilter>(
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                value: _selectedFilter,
                items: _dropdownWhichFilterItems,
                onChanged: (WhichFilter? selectedFilter) {
                  setState(() {
                    _selectedFilter = selectedFilter;
                  });
                  _onWhichFilterChange();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedFilter!.option_key == "product") {
                  _openFilterDrawer();
                } else {
                  ToastComponent.showDialog(
                      "You can use sorting while searching for products",
                      gravity: Toast.center,
                      duration: Toast.lengthLong);
                }
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_outlined, size: 16),
                    SizedBox(width: 4),
                    Text('Filter', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedFilter!.option_key == "product") {
                  _showSortDialog();
                } else {
                  ToastComponent.showDialog(
                      "You can use filters while searching for products",
                      gravity: Toast.center,
                      duration: Toast.lengthLong);
                }
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_vert, size: 16),
                    SizedBox(width: 4),
                    Text('Sort', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
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
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEEF2F8)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeFilterDrawer,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body - Scrollable filters
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Range Section
                          _buildFilterSectionHeader('Price range'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minPriceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [_amountValidator],
                                  decoration: InputDecoration(
                                    hintText: 'Minimum',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('-'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _maxPriceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [_amountValidator],
                                  decoration: InputDecoration(
                                    hintText: 'Maximum',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Categories Section
                          _buildFilterSectionHeader('Categories'),
                          const SizedBox(height: 8),
                          if (_filterCategoryList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('No categories available')),
                            )
                          else
                            Column(
                              children: _filterCategoryList.map((category) {
                                final isSelected = _selectedCategories.contains(category.id);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedCategories.remove(category.id);
                                      } else {
                                        _selectedCategories.clear();
                                        _selectedCategories.add(category.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? MyTheme.accent_color : const Color(0xFFF8F9FA),
                                      border: Border.all(
                                        color: isSelected ? MyTheme.accent_color : const Color(0xFFE9ECEF),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF495057),
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check, size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 20),
                          // Brands Section
                          _buildFilterSectionHeader('Brands'),
                          const SizedBox(height: 8),
                          if (_filterBrandList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('No brands available')),
                            )
                          else
                            Column(
                              children: _filterBrandList.map((brand) {
                                final isSelected = _selectedBrands.contains(brand.id);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedBrands.remove(brand.id);
                                      } else {
                                        _selectedBrands.add(brand.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? MyTheme.accent_color : const Color(0xFFF8F9FA),
                                      border: Border.all(
                                        color: isSelected ? MyTheme.accent_color : const Color(0xFFE9ECEF),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            brand.name,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF495057),
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check, size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFEEF2F8)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _minPriceController.clear();
                                _maxPriceController.clear();
                                _selectedCategories.clear();
                                _selectedBrands.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Clear All',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _applyProductFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'APPLY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sort products by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption("", "Default"),
            _buildSortOption("price_high_to_low", "Price high to low"),
            _buildSortOption("price_low_to_high", "Price low to high"),
            _buildSortOption("new_arrival", "New arrival"),
            _buildSortOption("popularity", "Popularity"),
            _buildSortOption("top_rated", "Top rated"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      dense: true,
      title: Text(label),
      value: value,
      groupValue: _selectedSort,
      activeColor: MyTheme.accent_color,
      contentPadding: EdgeInsets.zero,
      onChanged: (newValue) {
        setState(() {
          _selectedSort = newValue;
        });
        Navigator.pop(context);
        _onSortChange();
      },
    );
  }

  // Keep existing product list, brand list, shop list methods unchanged
  Container buildProductList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildProductScrollableList(),
          )
        ],
      ),
    );
  }

  buildProductScrollableList() {
    if (_isProductInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onProductListRefresh,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 16),
              MasonryGridView.count(
                itemCount: _productList.length,
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ProductCard(
                    id: _productList[index].id,
                    slug: _productList[index].slug,
                    image: _productList[index].thumbnail_image,
                    name: _productList[index].name,
                    main_price: _productList[index].main_price,
                    stroked_price: _productList[index].stroked_price,
                    has_discount: _productList[index].has_discount,
                    discount: _productList[index].discount,
                    is_wholesale: _productList[index].isWholesale,
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalProductData == 0) {
      return const Center(child: Text("No product is available"));
    } else {
      return Container();
    }
  }

  Container buildBrandList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildBrandScrollableList(),
          )
        ],
      ),
    );
  }

  buildBrandScrollableList() {
    if (_isBrandInitial && _brandList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_brandList.length > 0) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onBrandListRefresh,
        child: SingleChildScrollView(
          controller: _brandScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 16),
              GridView.builder(
                itemCount: _brandList.length,
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1),
                padding: const EdgeInsets.only(top: 20, bottom: 10, left: 16, right: 16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return BrandSquareCard(
                    id: _brandList[index].id,
                    slug: _brandList[index].slug,
                    image: _brandList[index].logo,
                    name: _brandList[index].name,
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalBrandData == 0) {
      return const Center(child: Text("No brand is available"));
    } else {
      return Container();
    }
  }

  Container buildShopList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildShopScrollableList(),
          )
        ],
      ),
    );
  }

  buildShopScrollableList() {
    if (_isShopInitial && _shopList.length == 0) {
      return SingleChildScrollView(
          controller: _scrollController,
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_shopList.length > 0) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onShopListRefresh,
        child: SingleChildScrollView(
          controller: _shopScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 16),
              GridView.builder(
                itemCount: _shopList.length,
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.7),
                padding: const EdgeInsets.only(top: 20, bottom: 10, left: 16, right: 16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ShopSquareCard(
                    id: _shopList[index].id,
                    shopSlug: _shopList[index].slug,
                    image: _shopList[index].logo,
                    name: _shopList[index].name,
                    stars: double.parse(_shopList[index].rating.toString()),
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalShopData == 0) {
      return const Center(child: Text("No shop is available"));
    } else {
      return Container();
    }
  }
}