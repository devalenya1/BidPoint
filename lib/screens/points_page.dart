import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/repositories/customer_package_repository.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/checkout.dart';
import 'package:active_ecommerce_flutter/screens/points_history_page.dart'; // ✅ Import points history page
import 'package:active_ecommerce_flutter/custom/enum_classes.dart';
import '../repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';

// Import the data model
import '../data_model/user_info_response.dart';
import '../data_model/customer_package_response.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({Key? key}) : super(key: key);

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> with SingleTickerProviderStateMixin {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPurchasing = false;
  bool _isDrawerOpen = false;
  bool _isDrawerAnimating = false;
  
  UserInformation? _userInfo;
  
  // Real packages from API
  List<Package> _packages = [];
  Package? _selectedPackage;
  
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _overlayFadeAnimation;
  
  // Scroll controller for package slider
  final ScrollController _packageScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for drawer
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _drawerSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeOut),
    );
    
    _overlayFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeOut),
    );
    
    if (is_logged_in.$ == true) {
      _fetchUserData();
      _fetchPackages();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _drawerAnimationController.dispose();
    _packageScrollController.dispose();
    super.dispose();
  }
  
  // ============ FETCH USER DATA FROM API ============
  Future<void> _fetchUserData() async {
    try {
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        points_balance.$ = _userInfo?.balance?.toString() ?? "0";
        points_balance.save();
        
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_user_data);
    }
  }
  
  // ============ FETCH REAL PACKAGES FROM API ============
  Future<void> _fetchPackages() async {
    try {
      var response = await CustomerPackageRepository().getList();
      
      if (response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _packages = response.data!;
          
          // Auto-select middle/second package (index 1) like HTML does
          if (_packages.length >= 2) {
            _selectedPackage = _packages[1];
          } else if (_packages.isNotEmpty) {
            _selectedPackage = _packages[0];
          }
        });
        
        // Scroll to selected package after drawer opens
        if (_selectedPackage != null && _packages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToPackage(_selectedPackage!);
          });
        }
      }
    } catch (e) {
      print("Error loading packages: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_packages);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await Future.wait([
      _fetchUserData(),
      _fetchPackages(),
    ]);
  }
  
  // ============ SCROLL TO SPECIFIC PACKAGE ============
  void _scrollToPackage(Package package) {
    final index = _packages.indexWhere((p) => p.id == package.id);
    if (index != -1 && _packageScrollController.hasClients) {
      // Calculate scroll position to center the package
      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = screenWidth * 0.69; // 69% of screen width like HTML
      final spacing = 12.0;
      
      double scrollPosition = index * (cardWidth + spacing);
      // Center the card
      scrollPosition = scrollPosition - (screenWidth / 2) + (cardWidth / 2);
      if (scrollPosition < 0) scrollPosition = 0;
      
      _packageScrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // ============ GET PACKAGE POINTS ============
  int _getPackagePoints(Package package) {
    return package.productUploadLimit ?? 0;
  }
  
  // ============ GET PACKAGE PRICE ============
  double _getPackagePrice(Package package) {
    if (package.price == null) return 0.0;
    if (package.price is double) return package.price;
    if (package.price is int) return (package.price as int).toDouble();
    if (package.price is String) {
      return double.tryParse(package.price) ?? 0.0;
    }
    return 0.0;
  }
  
  // ============ SUBMIT PURCHASE (Connects to Payment Gateway) ============
  Future<void> _submitPurchase() async {
    if (_selectedPackage == null) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_select_a_package);
      return;
    }
    
    // Check if package has valid ID
    if (_selectedPackage!.id == null || _selectedPackage!.id! <= 0) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.invalid_package_selected);
      return;
    }
    
    final price = _getPackagePrice(_selectedPackage!);
    
    // Close drawer
    await _closeBuyPointsDrawer();
    
    if (price > 0) {
      // Navigate to checkout with proper parameters
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Checkout(
            title: AppLocalizations.of(context)!.purchase_package,
            rechargeAmount: price,
            paymentFor: PaymentFor.PackagePay,
            packageId: _selectedPackage!.id,
          ),
        ),
      ).then((_) {
        _fetchUserData();
      });
    } else {
      // Free package
      // ... rest of free package code
    }
  }
  
  void _openBuyPointsDrawer() {
    setState(() {
      _isDrawerOpen = true;
      _isDrawerAnimating = true;
    });
    _drawerAnimationController.forward();
    
    // Scroll to selected package when drawer opens (matches HTML behavior)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedPackage != null) {
        _scrollToPackage(_selectedPackage!);
      } else if (_packages.isNotEmpty) {
        final index = _packages.length >= 2 ? 1 : 0;
        _scrollToPackage(_packages[index]);
      }
    });
  }
  
  Future<void> _closeBuyPointsDrawer() async {
    await _drawerAnimationController.reverse();
    if (mounted) {
      setState(() {
        _isDrawerOpen = false;
        _isDrawerAnimating = false;
      });
    }
  }
  
  void _selectPackage(Package package) {
    if (package.id != null && package.id! > 0) {
      setState(() {
        _selectedPackage = package;
      });
    } else {
      ToastComponent.showWarning(AppLocalizations.of(context)!.invalid_package_selected);
    }
  }
  
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  String _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'paypal':
        return '💰';
      case 'stripe':
        return '💳';
      default:
        return '💵';
    }
  }
  
  String _formatPrice(double price) {
    return FormatHelper.formatPrice(price);
  }
  
  // Helper getters
  List<CustomerPackagePayment> get _purchaseHistory {
    return _userInfo?.customerPackagePayments ?? [];
  }
  
  int get _userPoints {
    return (_userInfo?.balance ?? 0).toInt();
  }
  
  String get _userName {
    return _userInfo?.name ?? "";
  }
  
  String get _userEmail {
    return _userInfo?.email ?? "";
  }
  
  String get _userAvatar {
    return _userInfo?.avatar ?? "";
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.points_ucf,
          style: TextStyle(
            fontSize: 18.sp, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF0F172A)
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Icon(Icons.arrow_back_ios, size: 18.sp, color: const Color(0xFF64748B)),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Main(initialIndex: 0),
                ),
              );
            }
          },
        ),
        toolbarHeight: 60.h,
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : _buildBody(),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          ShimmerHelper().buildBasicShimmer(height: 180.h, radius: 24.r),
          SizedBox(height: 24.h),
          ShimmerHelper().buildBasicShimmer(height: 20.h, width: 150.w),
          SizedBox(height: 16.h),
          Column(
            children: List.generate(2, (index) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 16.r),
              ),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
  
  // ============ MAIN BODY ============
  Widget _buildBody() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              _buildUserPointsCard(),
              SizedBox(height: 24.h),
              _buildPurchaseHistory(),
              SizedBox(height: 30.h),
            ],
          ),
        ),
        
        // Bottom Drawer - Responsive height
        if (_isDrawerOpen || _isDrawerAnimating)
          AnimatedBuilder(
            animation: _drawerAnimationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Overlay
                  GestureDetector(
                    onTap: _closeBuyPointsDrawer,
                    child: Container(
                      color: Colors.black.withOpacity(0.5 * _overlayFadeAnimation.value),
                    ),
                  ),
                  
                  // Drawer - Responsive height
                  Transform.translate(
                    offset: Offset(0, MediaQuery.of(context).size.height * _drawerSlideAnimation.value),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.45,
                        width: double.infinity,
                        padding: EdgeInsets.only(bottom: 70.h),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              margin: EdgeInsets.only(top: 12.h),
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            
                            // Header with cancel button on the right
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(width: 32.w),
                                  Text(
                                    AppLocalizations.of(context)!.our_package_ucf,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF000417),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _closeBuyPointsDrawer,
                                    child: Container(
                                      width: 32.w,
                                      height: 32.w,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F6F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Responsive package slider with flexible height
                            Expanded(
                              child: _buildPackageSlider(),
                            ),
                            
                            // Buy button - Fixed at bottom of drawer
                            Container(
                              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                              child: GestureDetector(
                                onTap: _isPurchasing ? null : _submitPurchase,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: MyTheme.accent_color,
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: _isPurchasing
                                      ? Center(
                                          child: SizedBox(
                                            height: 20.w,
                                            width: 20.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.w,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.buy_now_ucf,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.sp,
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
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildPackageSlider() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive card size based on available space
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          
          // Responsive card height - use percentage of available height
          final cardHeight = availableHeight * 0.85;
          final cardWidth = availableWidth * 0.75;
          
          return SingleChildScrollView(
            controller: _packageScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _packages.asMap().entries.map((entry) {
                final index = entry.key;
                final package = entry.value;
                final isSelected = _selectedPackage?.id == package.id;
                final packagePrice = _getPackagePrice(package);
                final packagePoints = _getPackagePoints(package);
                
                return Container(
                  width: cardWidth.clamp(200.w, 400.w),
                  height: cardHeight.clamp(120.h, 300.h),
                  margin: EdgeInsets.only(right: index != _packages.length - 1 ? 12.w : 0),
                  child: _buildPackageCard(
                    package: package,
                    isSelected: isSelected,
                    packagePoints: packagePoints,
                    packagePrice: packagePrice,
                    cardHeight: cardHeight.clamp(120.h, 300.h),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPackageCard({
    required Package package,
    required bool isSelected,
    required int packagePoints,
    required double packagePrice,
    double? cardHeight,
  }) {
    final height = cardHeight ?? 150.h;
    final imageSize = height * 0.50;
    
    return GestureDetector(
      onTap: () => _selectPackage(package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : const Color(0xFFEEF2F8),
            width: 2.w,
          ),
          borderRadius: BorderRadius.circular(20.r),
          color: isSelected ? MyTheme.accent_color : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 12.r,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            // Left side - Package info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    package.name ?? AppLocalizations.of(context)!.package_ucf,
                    style: TextStyle(
                      fontSize: (height * 0.12).clamp(16.sp, 22.sp),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFFA5A5BA),
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: height * 0.04),
                  
                  Text(
                    '$packagePoints ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
                    style: TextStyle(
                      fontSize: (height * 0.19).clamp(20.sp, 28.sp),
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF000417),
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: height * 0.03),
                  
                  Text(
                    packagePrice == 0 
                        ? AppLocalizations.of(context)!.free_ucf 
                        : _formatPrice(packagePrice),
                    style: TextStyle(
                      fontSize: (height * 0.12).clamp(14.sp, 18.sp),
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF80818B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Package image
            Container(
              width: imageSize.clamp(50.w, 90.w),
              height: imageSize.clamp(50.h, 90.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: package.logo != null && package.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Image.network(
                        package.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.card_giftcard, 
                              size: imageSize.clamp(28.sp, 52.sp), 
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.card_giftcard, 
                        size: imageSize.clamp(28.sp, 52.sp), 
                        color: Colors.grey,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ============ UPDATED: USER POINTS CARD ============
  Widget _buildUserPointsCard() {
    return Container(
      padding: EdgeInsets.all(20.w), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          // User avatar and name - Reduced size
          Row(
            children: [
              Container(
                width: 50.w, // Reduced from 70
                height: 50.w, // Reduced from 70
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2.w, // Reduced from 3
                  ),
                ),
                child: ClipOval(
                  child: _userAvatar.isNotEmpty
                      ? Image.network(
                          _userAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 28.sp, // Reduced from 40
                              color: MyTheme.medium_grey,
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 28.sp, // Reduced from 40
                          color: MyTheme.medium_grey,
                        ),
                ),
              ),
              SizedBox(width: 12.w), // Reduced from 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : AppLocalizations.of(context)!.guest_user,
                      style: TextStyle(
                        fontSize: 15.sp, // Reduced from 17
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2.h), // Reduced from 4
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 10.sp, // Reduced from 11
                        color: const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h), // Reduced from 20
          
          // Points and buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Points section - Reduced size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.referral_and_points,
                      style: TextStyle(
                        fontSize: 8.sp, // Reduced from 9
                        fontWeight: FontWeight.w700,
                        color: MyTheme.accent_color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h), // Reduced from 4
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_userPoints',
                          style: TextStyle(
                            fontSize: 20.sp, // Reduced from 23
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 3.w), // Reduced from 4
                        Text(
                          AppLocalizations.of(context)!.points_ucf,
                          style: TextStyle(
                            fontSize: 10.sp, // Reduced from 11
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    // ✅ NEW: View button below points
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PointsHistoryPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: MyTheme.accent_color.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.view_ucf,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Buy Points button - Same size as before
              GestureDetector(
                onTap: _openBuyPointsDrawer,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.buy_point,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
  
  Widget _buildPurchaseHistory() {
    final history = _purchaseHistory;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.purchase_history} (${history.length})',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 16.h),
        if (history.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return _buildHistoryItem(history[index]);
            },
          ),
      ],
    );
  }
  
  Widget _buildHistoryItem(CustomerPackagePayment item) {
    final amount = item.amount ?? 0.0;
    final packageName = item.packageName ?? '';
    
    int packagePoints = 0;
    if (item.customerPackageId != null) {
      final foundPackage = _packages.firstWhere(
        (p) => p.id == item.customerPackageId,
        orElse: () => Package(),
      );
      if (foundPackage.id != null) {
        packagePoints = _getPackagePoints(foundPackage);
      }
    }
    
    if (packagePoints == 0) {
      packagePoints = (item.amount ?? 0).toInt();
    }
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      _getPaymentMethodIcon(item.paymentMethod ?? ''),
                      style: TextStyle(fontSize: 30.sp),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName.isNotEmpty ? packageName : AppLocalizations.of(context)!.package_purchase,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$packagePoints ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: MyTheme.accent_color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F8),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          item.paymentMethod ?? AppLocalizations.of(context)!.unknown,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(amount),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                item.createdAt != null ? _formatDate(item.createdAt!) : '',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 50.sp,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.purchase_history_empty,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context)!.purchase_history_empty_desc,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}