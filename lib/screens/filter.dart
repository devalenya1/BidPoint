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

  bool get _showNotificationBadge =>
      is_logged_in.$ && _unreadNotificationCount > 0;

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

      if (response.success == true &&
          response.data != null &&
          response.data!.isNotEmpty) {
        setState(() => _userInfo = response.data![0]);
        unread_notifications_count.$ =
            _userInfo!.unreadNotificationsCount ?? 0;
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
        if (!_showProductLoadingContainer &&
            _productList.length < (_totalProductData ?? 0)) {
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
          textDirection:
              app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            contentPadding: EdgeInsets.only(
                top: 16.h, left: 2.w, right: 2.w, bottom: 2.h),
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
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w600),
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
                        _onSortChange(
                            value, AppLocalizations.of(context)!.default_ucf);
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
                        _onSortChange(value,
                            AppLocalizations.of(context)!.price_high_to_low);
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
                        _onSortChange(value,
                            AppLocalizations.of(context)!.price_low_to_high);
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
                        _onSortChange(value,
                            AppLocalizations.of(context)!.new_arrival_ucf);
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
                        _onSortChange(
                            value, AppLocalizations.of(context)!.popularity_ucf);
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
                        _onSortChange(
                            value, AppLocalizations.of(context)!.top_rated_ucf);
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
                  style: TextStyle(
                      fontSize: 14.sp, color: const Color(0xFF64748B)),
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
                  color: isSelected
                      ? MyTheme.accent_color
                      : Colors.grey.shade400,
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

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FD),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // ── MAIN COLUMN: header + tools + list ──────────
              Column(
                children: [
                  _buildBpUtilityHeader(),
                  _buildToolsBar(),
                  Expanded(child: _buildProductList()),
                ],
              ),

              // ── FLOATING PAGINATION INDICATOR ──────────────
              if (_showProductLoadingContainer)
                Positioned(
                  bottom: 12.h,
                  right: 12.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22173A5A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _totalProductData == _productList.length
                              ? AppLocalizations.of(context)!
                                  .no_more_products_ucf
                              : AppLocalizations.of(context)!
                                  .loading_more_products_ucf,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── FILTER BOTTOM SHEET OVERLAY ─────────────────
              // (restored from original — this is the fix)
              if (_isFilterDrawerOpen) _buildFilterBottomSheet(),
            ],
          ),
        ),

        // ── NEW BidPoints mobile bottom bar ─────────────────
        bottomNavigationBar: _buildBpMobileBar(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NEW: BIDPOINTS UTILITY HEADER (same design as Home)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBpUtilityHeader() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFdceaf3))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C123866),
              blurRadius: 22,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 15.w : 28.w,
              vertical: isMobile ? 8.h : 9.h,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/app_logo.png',
                  width: isMobile ? 37.w : 48.w,
                  height: (isMobile ? 42.0 : 51.0).h,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.gavel,
                    size: isMobile ? 26.sp : 32.sp,
                    color: const Color(0xFF155e81),
                  ),
                ),
                SizedBox(width: isMobile ? 9.w : 15.w),
                Expanded(child: _buildSearchHeader()),
                SizedBox(width: isMobile ? 5.w : 9.w),
                _headerIconBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  isMobile: isMobile,
                  showDot: _showMessageBadge,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MessengerList()),
                      );
                    } else {
                      _redirectToLogin();
                    }
                  },
                ),
                SizedBox(width: isMobile ? 5.w : 9.w),
                _headerIconBtn(
                  icon: Icons.notifications_none_rounded,
                  isMobile: isMobile,
                  showDot: _showNotificationBadge,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsPage()),
                      ).then((_) => _fetchCounts());
                    } else {
                      _redirectToLogin();
                    }
                  },
                ),
                SizedBox(width: isMobile ? 5.w : 9.w),
                _headerIconBtn(
                  icon: Icons.card_giftcard_rounded,
                  isMobile: isMobile,
                  isGift: true,
                  showDot: false,
                  onTap: () {
                    if (is_logged_in.$) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AffiliatePage()),
                      );
                    } else {
                      _redirectToLogin();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {},
      child: Container(
        height: isMobile ? 36.h : 40.h,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10.w : 13.w),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f7fb),
          border: Border.all(color: const Color(0xFFd8e8f2)),
          borderRadius: BorderRadius.circular(isMobile ? 11.r : 14.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: isMobile ? 17.sp : 19.sp,
              color: const Color(0xFF2d7894),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                loc.search_products_brands_ucf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 11.sp : 13.sp,
                  color: const Color(0xFF6b8a9e),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn({
    required IconData icon,
    required bool isMobile,
    required VoidCallback onTap,
    bool showDot = false,
    bool isGift = false,
  }) {
    final size = isMobile ? 33.w : 41.w;
    final iconSize = isMobile ? 17.sp : 19.sp;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: isMobile ? 35.h : 41.h,
            decoration: BoxDecoration(
              color: isGift ? const Color(0xFFe8f9f5) : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 10.r : 13.r),
              border: Border.all(
                color: isGift
                    ? const Color(0xFFbfeae2)
                    : const Color(0xFFd7e7f1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isGift
                  ? const Color(0xFF0b9f98)
                  : const Color(0xFF185275),
            ),
          ),
          if (showDot)
            Positioned(
              right: isMobile ? 5.w : 7.w,
              top: isMobile ? 5.h : 7.h,
              child: Container(
                width: isMobile ? 6.w : 7.w,
                height: isMobile ? 6.w : 7.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFf1786e),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NEW: TOOLS BAR (Products found + Sort + Filter)
  // ═══════════════════════════════════════════════════════════
  Widget _buildToolsBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(9.w, 9.h, 9.w, 9.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$_totalProductsFound ${AppLocalizations.of(context)!.products_found}',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6a8295),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 9.w),
          GestureDetector(
            onTap: _showSortDialog,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: const Color(0xFFd7e7f1), width: 1),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert,
                      size: 14.sp, color: const Color(0xFF185275)),
                  SizedBox(width: 4.w),
                  Text(
                    _selectedSortLabel.isNotEmpty
                        ? _selectedSortLabel
                        : AppLocalizations.of(context)!.sort_ucf,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF185275),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 9.w),
          GestureDetector(
            onTap: _openFilterDrawer,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded,
                      size: 15.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                  Text(
                    AppLocalizations.of(context)!.filter_ucf ?? 'Filter',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NEW: BIDPOINTS MOBILE BAR (identical to main.dart)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBpMobileBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFdce9f2), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A173A5A),
            blurRadius: 24,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 9.h),
          child: Row(
            children: [
              _bpBarItem(
                index: 0,
                label: AppLocalizations.of(context)!.home_ucf,
                icon: Icons.home_outlined,
              ),
              _bpBarItem(
                index: 1,
                label: AppLocalizations.of(context)!.activity_ucf,
                icon: Icons.show_chart,
              ),
              _bpBarItem(
                index: 2,
                label: AppLocalizations.of(context)!.categories_ucf,
                icon: Icons.grid_view,
              ),
              _bpPointsItem(context),
              _bpProfileItem(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bpBarItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isActive = index == 0;
    final color =
        isActive ? MyTheme.accent_color : const Color(0xFF28516e);

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBottomBarTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22.w,
              height: 20.w,
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bpPointsItem(BuildContext context) {
    final balance = _userInfo?.balance ?? 0;
    final points = (balance is num) ? balance.toInt() : 0;

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBottomBarTap(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '◉',
              style: TextStyle(
                fontSize: 20.sp,
                color: const Color(0xFFdfad37),
                height: 1,
              ),
            ),
            SizedBox(height: 1.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _isLoadingCounts ? '...' : '$points',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF165076),
                    ),
                  ),
                  TextSpan(
                    text: '＋',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF05aa9d),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.points_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF6a8295),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bpProfileItem(BuildContext context) {
    final avatarUrl = _userInfo?.avatar ?? avatar_original.$ ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBottomBarTap(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFeaf9f6),
                border: Border.all(
                  color: const Color(0xFF28516e),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 14.sp,
                        color: const Color(0xFF28516e),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 14.sp,
                      color: const Color(0xFF28516e),
                    ),
            ),
            SizedBox(height: 3.h),
            Text(
              AppLocalizations.of(context)!.profile_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF28516e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar navigation ─────────────────────────────────
  void _onBottomBarTap(int index) {
    if ((index == 3 || index == 4) && !is_logged_in.$) {
      _redirectToLogin();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Main(initialIndex: index),
      ),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FILTER BOTTOM SHEET — restored from original design
  // ═══════════════════════════════════════════════════════════
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.filters_ucf,
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold),
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.categories_ucf,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12.h),
                            ..._filterCategoryList.map((category) => Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedCategories
                                            .contains(category.id)) {
                                          _selectedCategories
                                              .remove(category.id);
                                        } else {
                                          _selectedCategories
                                              .add(category.id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: _selectedCategories
                                                .contains(category.id)
                                            ? MyTheme.accent_color
                                            : Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              category.name ?? '',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: _selectedCategories
                                                        .contains(category.id)
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (_selectedCategories
                                              .contains(category.id))
                                            Icon(Icons.check,
                                                size: 16.sp,
                                                color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                            SizedBox(height: 24.h),
                            Text(
                              AppLocalizations.of(context)!.price_range_ucf,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12.h),
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
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Min: \$${_priceRange.start.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    'Max: \$${_priceRange.end.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade200, width: 1.w)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _clearFilters,
                              child: Container(
                                padding:
                                    EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .clear_all_ucf,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
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
                                padding:
                                    EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.apply_ucf,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
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

  // ═══════════════════════════════════════════════════════════
  // PRODUCT LIST
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductList() {
    if (_isProductInitial && _productList.isEmpty) {
      return ShimmerHelper()
          .buildProductGridShimmer(scontroller: _productScrollController);
    } else if (_productList.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: MyTheme.accent_color,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: 9.h,
            bottom: 90.h,
          ),
          child: MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            padding: EdgeInsets.symmetric(horizontal: 9.w),
            itemCount: _productList.length,
            itemBuilder: (context, index) {
              final product = _productList[index];

              bool isActive = false;
              if (product.auctionEndDate != null &&
                  product.auctionEndDate is int) {
                isActive = product.auctionEndDate >
                    DateTime.now().millisecondsSinceEpoch ~/ 1000;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Card image is square-ish (aspect 1.05), plus ~140px of text/CTA content.
                  // This mirrors what category_products does.
                  final cardWidth = constraints.maxWidth;
                  final cardHeight = cardWidth + 140;
                  return SizedBox(
                    height: cardHeight,
                    child: ProductCard(
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
                    ),
                  );
                },
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
}