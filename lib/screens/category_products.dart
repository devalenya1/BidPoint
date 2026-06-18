import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/useful_elements.dart';
import 'package:active_ecommerce_flutter/data_model/category_response.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';

class CategoryProducts extends StatefulWidget {
  CategoryProducts({Key? key, required this.slug}) : super(key: key);
  final String slug;

  @override
  _CategoryProductsState createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();

  List<dynamic> _productList = [];
  List<Category> _subCategoryList = [];
  bool _isInitial = true;
  int _page = 1;
  String _searchKey = "";
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  bool _showSearchBar = false;
  Category? categoryInfo;

  getSubCategory() async {
    var res = await CategoryRepository().getCategories(parent_id: widget.slug);
    _subCategoryList.addAll(res.categories!);
    setState(() {});
  }
  
  getCategoryInfo() async {
    var res = await CategoryRepository().getCategoryInfo(widget.slug);
    print(res.categories.toString());
    if (res.categories?.isNotEmpty ?? false) {
      categoryInfo = res.categories?.first ?? null;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getCategoryInfo();
    fetchAllDate();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  fetchData() async {
    var productResponse = await ProductRepository().getCategoryProducts(
        id: widget.slug, page: _page, name: _searchKey);
    _productList.addAll(productResponse.products!);
    _isInitial = false;
    _totalData = productResponse.meta!.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  fetchAllDate() {
    fetchData();
    getSubCategory();
  }

  reset() {
    _subCategoryList.clear();
    _productList.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchAllDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: Stack(
        children: [
          buildProductList(),
          Align(
            alignment: Alignment.bottomCenter,
            child: buildLoadingContainer(),
          ),
        ],
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalData == _productList.length
            ? AppLocalizations.of(context)!.no_more_products_ucf
            : AppLocalizations.of(context)!.loading_more_products_ucf),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _subCategoryList.isEmpty
          ? DeviceInfo(context).height! / 10
          : DeviceInfo(context).height! / 6.5,
      flexibleSpace: Container(
        height: DeviceInfo(context).height! / 4,
        width: DeviceInfo(context).width,
        color: MyTheme.accent_color,
        alignment: Alignment.topRight,
        child: Image.asset(
          "assets/background_1.png",
        ),
      ),
      bottom: PreferredSize(
        child: AnimatedContainer(
          height: _subCategoryList.isEmpty ? 0 : 60,
          duration: Duration(milliseconds: 500),
          child: !_isInitial ? buildSubCategory() : buildSubCategory(),
        ),
        preferredSize: Size.fromHeight(0.0),
      ),
      title: buildAppBarTitle(context),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildAppBarTitle(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: buildAppBarTitleOption(context),
      secondChild: buildAppBarSearchOption(context),
      firstCurve: Curves.fastOutSlowIn,
      secondCurve: Curves.fastOutSlowIn,
      crossFadeState: _showSearchBar
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 500),
    );
  }

  Container buildAppBarTitleOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  // Navigate to Main screen (home) with bottom navigation
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Main(initialIndex: 0),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2,
            child: Text(
              categoryInfo?.name ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Spacer(),
          SizedBox(
            width: 20,
            child: IconButton(
              onPressed: () {
                _showSearchBar = true;
                setState(() {});
              },
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.search,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildAppBarSearchOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      width: DeviceInfo(context).width,
      height: 40,
      child: TextField(
        controller: _searchController,
        onTap: () {},
        onChanged: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        onSubmitted: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        autofocus: false,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              _showSearchBar = false;
              setState(() {});
            },
            icon: Icon(
              Icons.clear,
              color: Colors.white,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          hintText: "${AppLocalizations.of(context)!.search_products_from} : ",
          hintStyle: TextStyle(fontSize: 14.0, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.0),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.all(8.0),
        ),
      ),
    );
  }

  ListView buildSubCategory() {
    return ListView.separated(
      padding: EdgeInsets.only(left: 18, right: 18, bottom: 10),
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return CategoryProducts(
                    slug: _subCategoryList[index].slug!,
                  );
                },
              ),
            );
          },
          child: Container(
            height: _subCategoryList.isEmpty ? 0 : 46,
            width: _subCategoryList.isEmpty ? 0 : 96,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _subCategoryList[index].name!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: MyTheme.accent_color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(
          width: 10,
        );
      },
      itemCount: _subCategoryList.length,
    );
  }

  buildProductList() {
    if (_isInitial && _productList.length == 0) {
      return SingleChildScrollView(
        child: ShimmerHelper()
            .buildProductGridShimmer(scontroller: _scrollController),
      );
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10, left: 16, right: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive column count
                int crossAxisCount = 2; // Default for mobile
                if (constraints.maxWidth >= 1024) {
                  crossAxisCount = 4; // Web: 4 columns
                } else if (constraints.maxWidth >= 768) {
                  crossAxisCount = 3; // Tablet: 3 columns
                }
                
                // Calculate spacing
                double spacing = 14;
                double cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                double cardHeight = cardWidth + 140; // Image + content height
                
                return MasonryGridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  itemCount: _productList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final product = _productList[index];
                    return SizedBox(
                      height: cardHeight,
                      child: ProductCard(
                        id: product.id ?? 0,
                        slug: product.slug ?? '',
                        image: product.thumbnail_image,
                        name: product.name,
                        description: product.name,
                        pointPerBid: product.pointPerBid,
                        auctionEndDate: product.auctionEndDate,
                        currentBid: product.highestBid,
                        startingBid: product.startingBid,
                        main_price: product.main_price,
                        stroked_price: product.stroked_price,
                        isAuctionActive: product.auctionEndDate != null &&
                            product.auctionEndDate is int &&
                            product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container(); // should never be happening
    }
  }
}