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
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import '../repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({Key? key}) : super(key: key);

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPurchasing = false;
  bool _isDrawerOpen = false;
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  // Package data - Demo packages for now (API not ready)
  List<Map<String, dynamic>> _packages = [];
  Map<String, dynamic>? _selectedPackage;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();  // Fetch fresh data from API
      _loadDemoPackages();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ============ FETCH DATA FROM API (Like ProductDetails) ============
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally like _productDetails
        });
        
        // Optional: Update global SharedValues for points balance
        points_balance.$ = _userInfo?.balance?.toString() ?? "0";
        points_balance.save();
        
        // Save all user data to SharedPreferences for other screens
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showDialog('Failed to load user data');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  void _loadDemoPackages() {
    // Demo packages for UI display (API not ready yet)
    setState(() {
      _packages = [
        {
          'id': 1,
          'name': 'Basic',
          'points': 100,
          'price': 9.99,
          'image': null,
        },
        {
          'id': 2,
          'name': 'Standard',
          'points': 500,
          'price': 39.99,
          'image': null,
        },
        {
          'id': 3,
          'name': 'Premium',
          'points': 1000,
          'price': 69.99,
          'image': null,
        },
        {
          'id': 4,
          'name': 'Platinum',
          'points': 2500,
          'price': 149.99,
          'image': null,
        },
        {
          'id': 5,
          'name': 'Diamond',
          'points': 5000,
          'price': 279.99,
          'image': null,
        },
      ];
      _selectedPackage = _packages[1]; // Select Standard package by default
    });
  }
  
  Future<void> _submitPurchase() async {
    if (_selectedPackage == null) {
      ToastComponent.showDialog('Please select a package first');
      return;
    }
    
    setState(() {
      _isPurchasing = true;
    });
    
    try {
      // TODO: Replace with actual API call to purchase package
      // var response = await ProfileRepository().purchasePackage(_selectedPackage!['id']);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Close drawer
      _closeBuyPointsDrawer();
      
      // Show success dialog
      _showPurchaseSuccessDialog();
      
      // Refresh user data
      await _fetchUserData();
      
    } catch (e) {
      print("Error purchasing package: $e");
      ToastComponent.showDialog('Purchase failed. Please try again.');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }
  
  void _showPurchaseSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Purchase Successful!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Package: ${_selectedPackage!['name']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Points: ${_selectedPackage!['points']} points',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: ${FormatHelper.formatPrice(_selectedPackage!['price'])}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MyTheme.accent_color,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
  
  void _selectPackage(Map<String, dynamic> package) {
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
  
  // Helper to get purchase history from stored user info
  List<CustomerPackagePayment> get _purchaseHistory {
    return _userInfo?.customerPackagePayments ?? [];
  }
  
  // Helper to get user points
  int get _userPoints {
    return (_userInfo?.balance ?? 0).toInt();
  }
  
  // Helper to get user name
  String get _userName {
    return _userInfo?.name ?? "";
  }
  
  // Helper to get user email
  String get _userEmail {
    return _userInfo?.email ?? "";
  }
  
  // Helper to get user avatar
  String get _userAvatar {
    return _userInfo?.avatar ?? "";
  }
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()  // Show shimmer while loading
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
          // User Points Card shimmer
          ShimmerHelper().buildBasicShimmer(height: 180, radius: 24),
          const SizedBox(height: 24),
          // Purchase History header shimmer
          ShimmerHelper().buildBasicShimmer(height: 20, width: 150),
          const SizedBox(height: 16),
          // Purchase history items shimmer
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
        // Main Content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // User Points Card
              _buildUserPointsCard(),
              const SizedBox(height: 24),
              // Purchase History
              _buildPurchaseHistory(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        // Bottom Drawer Overlay
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
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drawer Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Drawer Header
                        _buildDrawerHeader(),
                        // Drawer Body
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Package Cards
                                _buildPackageSlider(),
                                const SizedBox(height: 28),
                                // Buy Button
                                _buildBuyButton(),
                              ],
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
          // User Info Row
          Row(
            children: [
              // Avatar
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
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : 'User',
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
          // Points Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referral & Points',
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
                          'Points',
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
              // Buy Point Button
              GestureDetector(
                onTap: _openBuyPointsDrawer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'Buy Point',
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
          'Purchase History (${history.length})',
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
          // Left Side
          Expanded(
            child: Row(
              children: [
                // Icon
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
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.packageName ?? 'Package Purchase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MyTheme.dark_font_grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${amount.toInt()} points',
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
                          item.paymentMethod ?? 'Unknown',
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
          // Right Side
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
            'Your purchase history is empty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buy points and then check here, all points purchases will be displayed here.',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: MyTheme.light_grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(
            'Our Package',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MyTheme.dark_font_grey,
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
    );
  }
  
  Widget _buildPackageSlider() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _packages.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final package = _packages[index];
          final isSelected = _selectedPackage != null && _selectedPackage!['id'] == package['id'];
          return _buildPackageCard(package, isSelected);
        },
      ),
    );
  }
  
  Widget _buildPackageCard(Map<String, dynamic> package, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectPackage(package),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? MyTheme.accent_color : Colors.white,
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : const Color(0xFFEEF2F8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left - Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    package['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFA5A5BA),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${package['points']} points',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : MyTheme.dark_font_grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package['price'] == 0 ? 'Free' : _formatPrice(package['price']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFF80818B),
                    ),
                  ),
                ],
              ),
            ),
            // Right - Image
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 60,
                color: isSelected ? Colors.white : MyTheme.accent_color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBuyButton() {
    return GestureDetector(
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
                'Buy Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}