import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/useful_elements.dart';
import 'package:active_ecommerce_flutter/data_model/category_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/screens/category_products.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryList extends StatefulWidget {
  CategoryList({
    Key? key,
    required this.slug,
    this.is_base_category = false,
    this.is_top_category = false,
    this.bottomAppbarIndex,
  }) : super(key: key);

  final String slug;
  final bool is_base_category;
  final bool is_top_category;
  final BottomAppbarIndex? bottomAppbarIndex;

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0; // 0 = Recommended, 1 = A-Z
  String _searchQuery = "";
  List<dynamic>? _categories = [];
  List<dynamic>? _filteredCategories = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterCategories();
    });
  }

  void _filterCategories() {
    if (_categories == null) return;
    
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories!);
    } else {
      _filteredCategories = _categories!
          .where((category) => category.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    
    // Apply sorting if A-Z tab is selected
    if (_selectedTab == 1) {
      _filteredCategories!.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _sortAZ() {
    setState(() {
      _selectedTab = 1;
      if (_filteredCategories != null) {
        _filteredCategories!.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _resetToRecommended() {
    setState(() {
      _selectedTab = 0;
      _filterCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            getAppBarTitle(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              } else {
                // Go to home if can't pop
                context.go("/");
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => Main(),
                //   ),
                // );
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            // Tabs (Recommended & A-Z)
            _buildTabs(),
            // Categories Grid
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.arrow_left,
                size: 18,
                color: MyTheme.dark_font_grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Text(
            getAppBarTitle(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MyTheme.dark_font_grey,
            ),
          ),
        ],
      ),
    );
  }

  String getAppBarTitle() {
    return widget.is_top_category
        ? AppLocalizations.of(context)!.top_categories_ucf
        : AppLocalizations.of(context)!.categories_ucf;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: MyTheme.light_grey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              Icons.search,
              size: 14,
              color: MyTheme.medium_grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search_here_ucf,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: MyTheme.medium_grey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: MyTheme.dark_font_grey,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: MyTheme.medium_grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MyTheme.light_grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            title: AppLocalizations.of(context)!.recommended_ucf,
            isActive: _selectedTab == 0,
            onTap: _resetToRecommended,
          ),
          const SizedBox(width: 20),
          _buildTabItem(
            title: AppLocalizations.of(context)!.a_z_ucf,
            isActive: _selectedTab == 1,
            onTap: _sortAZ,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? MyTheme.accent_color : MyTheme.font_grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    var data = widget.is_top_category
        ? CategoryRepository().getTopCategories()
        : CategoryRepository().getCategories(parent_id: widget.slug);
        
    return FutureBuilder(
      future: data,
      builder: (context, AsyncSnapshot<CategoryResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.something_went_wrong,
              style: TextStyle(color: MyTheme.font_grey),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.categories != null) {
          _categories = snapshot.data!.categories;
          if (_filteredCategories == null || _filteredCategories!.isEmpty) {
            _filteredCategories = List.from(_categories!);
          }
          if (_searchQuery.isEmpty && _filteredCategories!.isEmpty) {
            _filteredCategories = List.from(_categories!);
          }
          
          if (_filteredCategories!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category,
                    size: 64,
                    color: MyTheme.medium_grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.no_category_found,
                    style: TextStyle(
                      fontSize: 14,
                      color: MyTheme.font_grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                crossAxisCount: _getCrossAxisCount(),
              ),
              itemCount: _filteredCategories!.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildCategoryItemCard(_filteredCategories![index]);
              },
            ),
          );
        } else {
          return _buildShimmer();
        }
      },
    );
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 992) {
      return 6; // Desktop: 6 items
    } else if (width > 768) {
      return 4; // Tablet: 4 items
    } else {
      return 3; // Mobile: 3 items
    }
  }

  Widget _buildCategoryItemCard(dynamic category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProducts(
              slug: category.slug ?? "",
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyTheme.light_grey,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Category Image
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: category.banner ?? '',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: MyTheme.light_grey,
                        child: Icon(
                          Icons.category,
                          size: 40,
                          color: MyTheme.medium_grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Category Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: MyTheme.light_grey,
                border: Border(
                  top: BorderSide(
                    color: MyTheme.light_grey,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                category.name ?? '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  color: MyTheme.dark_font_grey,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          crossAxisCount: _getCrossAxisCount(),
        ),
        itemCount: 12,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: MyTheme.light_grey,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ShimmerHelper().buildBasicShimmer(),
          );
        },
      ),
    );
  }
}