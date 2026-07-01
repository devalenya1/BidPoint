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
import 'package:active_ecommerce_flutter/ui_elements/auction_product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/category_list.dart';
import '../screens/points_page.dart';
import '../screens/activity_page.dart';
import '../screens/profile.dart';
import '../screens/main.dart';

// Import the data model
import '../data_model/user_info_response.dart';
import '../presenter/bottom_appbar_index.dart';
import '../presenter/cart_counter.dart';

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

  // Bottom navigation
  int _currentIndex = 0;
  BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();

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
        _selectedSortLabel = AppLocalizations.of(context)!.sort_by_ucf;
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
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
        return Directionality(
          textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            contentPadding: EdgeInsets.only(top: 16.h, left: 2.w, right: 2.w, bottom: 2.h),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        AppLocalizations.of(context)!.sort_products_by_ucf,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                    RadioListTile(
                      dense: true,
                      value: "",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.default_ucf,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.default_ucf);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      dense: true,
                      value: "price_high_to_low",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.price_high_to_low,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.price_high_to_low);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      dense: true,
                      value: "price_low_to_high",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.price_low_to_high,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.price_low_to_high);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      dense: true,
                      value: "new_arrival",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.new_arrival_ucf,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.new_arrival_ucf);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      dense: true,
                      value: "popularity",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.popularity_ucf,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.popularity_ucf);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      dense: true,
                      value: "top_rated",
                      groupValue: _selectedSort,
                      activeColor: MyTheme.accent_color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppLocalizations.of(context)!.top_rated_ucf,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onChanged: (dynamic value) {
                        setState(() {
                          _selectedSort = value;
                        });
                        _onSortChange(value, AppLocalizations.of(context)!.top_rated_ucf);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.close_all_capital,
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
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
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? MyTheme.accent_color : Colors.grey.shade400,
                  width: 2.w,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
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
        // Bottom Navigation Bar
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 70.h,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Main(initialIndex: 0),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryList(
                    slug: "",
                    is_base_category: true,
                  ),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PointsPage(),
                ),
              );
              break;
            case 3:
              if (is_logged_in.$) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivityPage(),
                  ),
                );
              } else {
                _redirectToLogin();
              }
              break;
            case 4:
              if (is_logged_in.$) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(),
                  ),
                );
              } else {
                _redirectToLogin();
              }
              break;
          }
        },
        currentIndex: _currentIndex,
        backgroundColor: Colors.white.withOpacity(0.95),
        unselectedItemColor: const Color.fromRGBO(168, 175, 179, 1),
        selectedItemColor: MyTheme.accent_color,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12.sp,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Image.asset(
                "assets/home.png",
                color: _currentIndex == 0
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16.w,
              ),
            ),
            label: AppLocalizations.of(context)!.home_ucf,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Image.asset(
                "assets/categories.png",
                color: _currentIndex == 1
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16.w,
              ),
            ),
            label: AppLocalizations.of(context)!.categories_ucf,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Image.asset(
                "assets/crown.png",
                color: _currentIndex == 2
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16.w,
              ),
            ),
            label: AppLocalizations.of(context)!.points_ucf,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Image.asset(
                "assets/task-square.png",
                color: _currentIndex == 3
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16.w,
              ),
            ),
            label: AppLocalizations.of(context)!.activity_ucf,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Image.asset(
                "assets/profile.png",
                color: _currentIndex == 4
                    ? MyTheme.accent_color
                    : const Color.fromRGBO(153, 153, 153, 1),
                height: 16.w,
              ),
            ),
            label: AppLocalizations.of(context)!.profile_ucf,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12.h,
        left: 16.w,
        right: 16.w,
        bottom: 12.h,
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
                padding: EdgeInsets.only(left: 12.w),
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
                        if (_showNotificationBadge)
                          Positioned(
                            top: 2.h,
                            right: 2.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(color: MyTheme.accent_color, borderRadius: BorderRadius.circular(10.r)),
                              constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                              child: Text(
                                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.white),
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
                        if (_showMessageBadge)
                          Positioned(
                            top: 2.h,
                            right: 2.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(color: MyTheme.accent_color, borderRadius: BorderRadius.circular(10.r)),
                              constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                              child: Text(
                                _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.white),
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
          // ✅ FIX: Products count and Sort/Filter in same row
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Products count - Left side
              Text(
                '$_totalProductsFound ${AppLocalizations.of(context)!.products_found}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey,
                ),
              ),
              // Sort and Filter buttons - Right side
              Row(
                children: [
                  // Sort Button
                  GestureDetector(
                    onTap: _showSortDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.w),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert, size: 14.sp, color: const Color(0xFF64748B)),
                          SizedBox(width: 4.w),
                          Text(
                            _selectedSortLabel.isNotEmpty ? _selectedSortLabel : AppLocalizations.of(context)!.sort_ucf,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Filter Button
                  GestureDetector(
                    onTap: _openFilterDrawer,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt, size: 16.sp, color: Colors.white),
                          SizedBox(width: 4.w),
                          // Text(
                          //   AppLocalizations.of(context)!.filter_ucf,
                          //   style: TextStyle(
                          //     fontSize: 12.sp,
                          //     fontWeight: FontWeight.w500,
                          //     color: Colors.white,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        height: 40.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300, width: 1.w),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    hintStyle: TextStyle(fontSize: 13.sp, color: MyTheme.textfield_grey),
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
                child: Image.asset('assets/search.png', height: 16.w, color: MyTheme.dark_grey),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: EdgeInsets.only(top: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.filters_ucf,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: _closeFilterDrawer,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 20.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1.h),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories Section
                            Text(
                              AppLocalizations.of(context)!.categories_ucf,
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12.h),
                            ..._filterCategoryList.map((category) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
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
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: _selectedCategories.contains(category.id) 
                                        ? MyTheme.accent_color 
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          category.name ?? '',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: _selectedCategories.contains(category.id) 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (_selectedCategories.contains(category.id))
                                        Icon(Icons.check, size: 16.sp, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                            
                            SizedBox(height: 24.h),
                            
                            // Price Range Section
                            Text(
                              AppLocalizations.of(context)!.price_range_ucf,
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12.h),
                            
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
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Min: \$${_priceRange.start.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    'Max: \$${_priceRange.end.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
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
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _clearFilters,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.clear_all_ucf,
                                    style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: _applyFilter,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.apply_ucf,
                                    style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
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
            // ✅ FIXED: Reduced from 180.h to 120.h to remove large gap
            top: MediaQuery.of(context).padding.top + 120.h,
            bottom: 70.h,
          ),
          child: MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            padding: EdgeInsets.all(12.w),
            itemCount: _productList.length,
            itemBuilder: (context, index) {
              final product = _productList[index];
              
              bool isActive = false;
              if (product.auctionEndDate != null && product.auctionEndDate is int) {
                isActive = product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
              }
              
              return ProductCard(
                id: product.id ?? 0,
                slug: product.slug ?? '',
                image: product.thumbnail_image,
                name: product.name,
                description: product.name ?? '',
                pointPerBid: product.pointPerBid,
                auctionEndDate: product.auctionEndDate,
                currentBid: product.highestBid,
                startingBid: product.startingBid,
                main_price: product.main_price,
                stroked_price: product.stroked_price,
                isAuctionActive: isActive,
              );
            },
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.no_product_is_available,
          style: TextStyle(fontSize: 14.sp),
        ),
      );
    }
  }

  Widget _buildProductLoadingContainer() {
    if (!_showProductLoadingContainer) return const SizedBox.shrink();
    return Container(
      height: 36.h,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        _totalProductData == _productList.length
            ? AppLocalizations.of(context)!.no_more_products_ucf
            : AppLocalizations.of(context)!.loading_more_products_ucf,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }
}