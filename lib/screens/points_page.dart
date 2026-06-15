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

class _PointsPageState extends State<PointsPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPurchasing = false;
  bool _isDrawerOpen = false;
  
  UserInformation? _userInfo;
  
  // Real packages from API
  List<Package> _packages = [];
  Package? _selectedPackage;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();
      _fetchPackages();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
          if (_packages.isNotEmpty) {
            _selectedPackage = _packages[0];
          }
        });
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
  
  // ============ SUBMIT PURCHASE (Connects to Payment Gateway) ============
  Future<void> _submitPurchase() async {
    if (_selectedPackage == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_select_a_package);
      return;
    }
    
    final price = _getPackagePrice(_selectedPackage!);
    
    // Close drawer
    _closeBuyPointsDrawer();
    
    // Navigate to checkout for paid packages
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
      // Free package
      setState(() {
        _isPurchasing = true;
      });
      
      try {
        var response = await CustomerPackageRepository().freePackagePayment(_selectedPackage!.id);
        ToastComponent.showDialog(response.message ?? AppLocalizations.of(context)!.package_claimed_successfully);
        
        if (response.result == true) {
          await _fetchUserData();
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
  
  double _getPackagePrice(Package package) {
    if (package.price == null) return 0.0;
    if (package.price is double) return package.price;
    if (package.price is int) return (package.price as int).toDouble();
    if (package.price is String) {
      return double.tryParse(package.price) ?? 0.0;
    }
    return 0.0;
  }
  
  int _getPackagePoints(Package package) {
    if (package.amount == null) return 0;
    
    dynamic amountValue = package.amount;
    
    if (amountValue is int) {
      return amountValue;
    } else if (amountValue is double) {
      return amountValue.toInt();
    } else if (amountValue is String) {
      return int.tryParse(amountValue) ?? 0;
    } else if (amountValue is num) {
      return amountValue.toInt();
    }
    
    return 0;
  }
  
  void _openBuyPointsDrawer() {
    setState(() {
      _isDrawerOpen = true;
    });
  }
  
  void _closeBuyPointsDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
        
        // Bottom Drawer - 40% of screen height
        if (_isDrawerOpen)
          GestureDetector(
            onTap: _closeBuyPointsDrawer,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 40),
                              Text(
                                AppLocalizations.of(context)!.select_package,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              GestureDetector(
                                onTap: _closeBuyPointsDrawer,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: MyTheme.light_grey,
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.separated(
                              itemCount: _packages.length,
                              separatorBuilder: (context, index) => const Divider(height: 0, color: Color(0xFFEEF2F8)),
                              itemBuilder: (context, index) {
                                final package = _packages[index];
                                final isSelected = _selectedPackage?.id == package.id;
                                final packagePrice = _getPackagePrice(package);
                                final packagePoints = _getPackagePoints(package);
                                
                                return GestureDetector(
                                  onTap: () => _selectPackage(package),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? MyTheme.accent_color : const Color(0xFFCBD5E1),
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                package.name ?? AppLocalizations.of(context)!.package,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$packagePoints ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          packagePrice == 0 ? AppLocalizations.of(context)!.free_ucf : _formatPrice(packagePrice),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: MyTheme.accent_color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: GestureDetector(
                            onTap: _isPurchasing ? null : _submitPurchase,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                borderRadius: BorderRadius.circular(12),
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
            ),
          ),
      ],
    );
  }
  
  Widget _buildUserPointsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyTheme.light_grey,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MyTheme.dark_font_grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
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
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: MyTheme.dark_font_grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.points_ucf,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.dark_font_grey,
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
                    style: TextStyle(
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MyTheme.dark_font_grey,
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
                  child: Text(
                    _getPaymentMethodIcon(item.paymentMethod ?? ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.packageName ?? AppLocalizations.of(context)!.package_purchase,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MyTheme.dark_font_grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${amount.toInt()} ${AppLocalizations.of(context)!.points_ucf.toLowerCase()}',
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
                          style: TextStyle(
                            fontSize: 10,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MyTheme.dark_font_grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.createdAt != null ? _formatDate(item.createdAt!) : '',
                style: TextStyle(
                  fontSize: 11,
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