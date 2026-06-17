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
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_user_data);
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
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_packages);
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
    // Points are stored in productUploadLimit field
    // From server: "product_upload_limit": 1000
    return package.productUploadLimit ?? 0;
  }
  
  // ============ GET PACKAGE PRICE ============
  double _getPackagePrice(Package package) {
    // Price is stored in 'price' field
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
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_select_a_package);
      return;
    }
    
    final price = _getPackagePrice(_selectedPackage!);
    
    // Close drawer
    await _closeBuyPointsDrawer();
    
    // Navigate to checkout for paid packages (matching HTML behavior)
    if (price > 0) {
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
        // Refresh data when returning from checkout
        _fetchUserData();
      });
    } else {
      // Free package - matches HTML behavior where free package shows confirmation
      setState(() {
        _isPurchasing = true;
      });
      
      try {
        // Show confirmation dialog like HTML does
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.confirm_purchase_ucf),
              content: Text(
                '${AppLocalizations.of(context)!.get_ucf} ${_selectedPackage!.name} ${AppLocalizations.of(context)!.package_ucf} ${_getPackagePoints(_selectedPackage!)} ${AppLocalizations.of(context)!.points_ucf.toLowerCase()} ${AppLocalizations.of(context)!.for_free_ucf}?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel_ucf),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    AppLocalizations.of(context)!.confirm_ucf,
                    style: TextStyle(color: MyTheme.accent_color),
                  ),
                ),
              ],
            );
          },
        );
        
        if (shouldProceed == true) {
          var response = await CustomerPackageRepository().freePackagePayment(_selectedPackage!.id);
          ToastComponent.showDialog(response.message ?? AppLocalizations.of(context)!.package_claimed_successfully);
          
          if (response.result == true) {
            await _fetchUserData();
          }
        }
      } catch (e) {
        print("Error purchasing free package: $e");
        ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_claim_package);
      } finally {
        setState(() {
          _isPurchasing = false;
        });
      }
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
    setState(() {
      _selectedPackage = package;
    });
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF64748B)),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              // Go to home if can't pop
              context.go("/");
            }
          },
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 180, radius: 24),
          const SizedBox(height: 24),
          ShimmerHelper().buildBasicShimmer(height: 20, width: 150),
          const SizedBox(height: 16),
          Column(
            children: List.generate(2, (index) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerHelper().buildBasicShimmer(height: 80, radius: 16),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  // ============ MAIN BODY ============
  Widget _buildBody() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildUserPointsCard(),
              const SizedBox(height: 24),
              _buildPurchaseHistory(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        
        // Bottom Drawer - Fixed above bottom navigation bar
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
                  
                  // Drawer - Fixed above bottom navigation bar
                  Transform.translate(
                    offset: Offset(0, MediaQuery.of(context).size.height * _drawerSlideAnimation.value),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.35, // Reduced height
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 70), // Space for bottom nav
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
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            
                            // Header with cancel button on the right
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 32), // Spacer for balance
                                  Text(
                                    AppLocalizations.of(context)!.our_package_ucf,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000417),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _closeBuyPointsDrawer,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F6F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Horizontal scrollable packages
                            Expanded(
                              child: _buildPackageSlider(),
                            ),
                            
                            // Buy button - Fixed at bottom of drawer
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: GestureDetector(
                                onTap: _isPurchasing ? null : _submitPurchase,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: MyTheme.accent_color,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: _isPurchasing
                                      ? const Center(
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.buy_now_ucf,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
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
      child: SingleChildScrollView(
        controller: _packageScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _packages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            final isSelected = _selectedPackage?.id == package.id;
            final packagePrice = _getPackagePrice(package);
            final packagePoints = _getPackagePoints(package);
            
            return Container(
              width: MediaQuery.of(context).size.width * 0.69,
              margin: EdgeInsets.only(right: index != _packages.length - 1 ? 12 : 0),
              child: _buildPackageCard(
                package: package,
                isSelected: isSelected,
                packagePoints: packagePoints,
                packagePrice: packagePrice,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPackageCard({
    required Package package,
    required bool isSelected,
    required int packagePoints,
    required double packagePrice,
  }) {
    return GestureDetector(
      onTap: () => _selectPackage(package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : const Color(0xFFEEF2F8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? MyTheme.accent_color : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 12,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Equal horizontal padding
        child: Row(
          children: [
            // Left side - Package info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    package.name ?? AppLocalizations.of(context)!.package_ucf,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFA5A5BA),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$packagePoints ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF000417),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    packagePrice == 0 
                        ? AppLocalizations.of(context)!.free_ucf 
                        : _formatPrice(packagePrice),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFF80818B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Package image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: package.logo != null && package.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        package.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.card_giftcard, size: 40, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.card_giftcard, size: 40, color: Colors.grey),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserPointsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
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
                              size: 40,
                              color: MyTheme.medium_grey,
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: MyTheme.medium_grey,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : AppLocalizations.of(context)!.guest_user,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.referral_and_points,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MyTheme.accent_color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_userPoints',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.points_ucf,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openBuyPointsDrawer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.buy_point,
                    style: const TextStyle(
                      fontSize: 14,
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    
    // Get package points from the payment
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
    
    // Fallback: if we can't find the package, use a default
    if (packagePoints == 0) {
      packagePoints = (item.amount ?? 0).toInt();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getPaymentMethodIcon(item.paymentMethod ?? ''),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName.isNotEmpty ? packageName : AppLocalizations.of(context)!.package_purchase,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$packagePoints ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MyTheme.accent_color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.paymentMethod ?? AppLocalizations.of(context)!.unknown,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.createdAt != null ? _formatDate(item.createdAt!) : '',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 50,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.purchase_history_empty,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.purchase_history_empty_desc,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}