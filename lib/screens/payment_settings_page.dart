import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({Key? key}) : super(key: key);

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSaving = false;
  
  // Modal visibility
  bool _isBankModalOpen = false;
  bool _isPaypalModalOpen = false;
  
  // Form controllers
  TextEditingController _bankNameController = TextEditingController();
  TextEditingController _accountHolderController = TextEditingController();
  TextEditingController _accountNumberController = TextEditingController();
  TextEditingController _ifscCodeController = TextEditingController();
  TextEditingController _paypalEmailController = TextEditingController();
  
  UserInformation? _userInfo;  // Store the complete user info response
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchUserData();  // Fetch fresh data from API
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _paypalEmailController.dispose();
    super.dispose();
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
        
        // Load payment details into controllers
        _loadPaymentDetailsFromUserInfo();
        
        // Save all user data to SharedPreferences for other screens
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      _showError('Failed to load payment details');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ LOAD PAYMENT DETAILS FROM STORED USER INFO ============
  void _loadPaymentDetailsFromUserInfo() {
    if (_userInfo == null) return;
    
    // Load PayPal details
    final hasPaypal = _userInfo!.paypalEmail != null && _userInfo!.paypalEmail!.isNotEmpty;
    if (hasPaypal) {
      _paypalEmailController.text = _userInfo!.paypalEmail!;
    }
    
    // Load Bank details
    final hasBankName = _userInfo!.bankName != null && _userInfo!.bankName!.isNotEmpty;
    final hasAccountHolder = _userInfo!.accountHolder != null && _userInfo!.accountHolder!.isNotEmpty;
    final hasAccountNumber = _userInfo!.accountNumber != null && _userInfo!.accountNumber!.isNotEmpty;
    
    if (hasBankName && hasAccountHolder && hasAccountNumber) {
      _bankNameController.text = _userInfo!.bankName!;
      _accountHolderController.text = _userInfo!.accountHolder!;
      _accountNumberController.text = _userInfo!.accountNumber!;
      _ifscCodeController.text = _userInfo!.ifscCode ?? '';
    }
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  // Helper getters for payment status (derived from _userInfo)
  bool get _bankConnected {
    if (_userInfo == null) return false;
    final hasBankName = _userInfo!.bankName != null && _userInfo!.bankName!.isNotEmpty;
    final hasAccountHolder = _userInfo!.accountHolder != null && _userInfo!.accountHolder!.isNotEmpty;
    final hasAccountNumber = _userInfo!.accountNumber != null && _userInfo!.accountNumber!.isNotEmpty;
    return hasBankName && hasAccountHolder && hasAccountNumber;
  }
  
  bool get _paypalConnected {
    if (_userInfo == null) return false;
    return _userInfo!.paypalEmail != null && _userInfo!.paypalEmail!.isNotEmpty;
  }
  
  String get _displayBankName => _userInfo?.bankName ?? "";
  String get _displayAccountHolder => _userInfo?.accountHolder ?? "";
  String get _displayAccountNumber => _userInfo?.accountNumber ?? "";
  String get _displayIfscCode => _userInfo?.ifscCode ?? "";
  String get _displayPaypalEmail => _userInfo?.paypalEmail ?? "";
  
  Future<void> _saveBankDetails() async {
    // Validate
    if (_bankNameController.text.trim().isEmpty) {
      _showError('Please enter bank name');
      return;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      _showError('Please enter account holder name');
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      _showError('Please enter account number');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await ProfileRepository().updateAffiliatePaymentDetails(
        paypalEmail: _paypalEmailController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountHolder: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
      );
      
      if (response['success'] == true) {
        setState(() {
          _isBankModalOpen = false;
        });
        
        _showSuccess('Bank details saved successfully');
        
        // Refresh user data
        await _fetchUserData();
      } else {
        _showError(response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      print("Error saving bank details: $e");
      _showError('Something went wrong');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _savePaypalDetails() async {
    // Validate
    if (_paypalEmailController.text.trim().isEmpty) {
      _showError('Please enter PayPal email');
      return;
    }
    if (!_paypalEmailController.text.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await ProfileRepository().updateAffiliatePaymentDetails(
        paypalEmail: _paypalEmailController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountHolder: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
      );
      
      if (response['success'] == true) {
        setState(() {
          _isPaypalModalOpen = false;
        });
        
        _showSuccess('PayPal details saved successfully');
        
        // Refresh user data
        await _fetchUserData();
      } else {
        _showError(response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      print("Error saving PayPal details: $e");
      _showError('Something went wrong');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _disconnectBank() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Bank'),
        content: const Text('Are you sure you want to disconnect your bank account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel_ucf),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await ProfileRepository().updateAffiliatePaymentDetails(
        paypalEmail: _paypalEmailController.text.trim(),
        bankName: '',
        accountHolder: '',
        accountNumber: '',
        ifscCode: '',
      );
      
      if (response['success'] == true) {
        setState(() {
          _bankNameController.clear();
          _accountHolderController.clear();
          _accountNumberController.clear();
          _ifscCodeController.clear();
        });
        
        _showSuccess('Bank account disconnected successfully');
        await _fetchUserData();
      } else {
        _showError(response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      print("Error disconnecting bank: $e");
      _showError('Something went wrong');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _disconnectPaypal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect PayPal'),
        content: const Text('Are you sure you want to disconnect your PayPal account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel_ucf),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await ProfileRepository().updateAffiliatePaymentDetails(
        paypalEmail: '',
        bankName: _bankNameController.text.trim(),
        accountHolder: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
      );
      
      if (response['success'] == true) {
        setState(() {
          _paypalEmailController.clear();
        });
        
        _showSuccess('PayPal account disconnected successfully');
        await _fetchUserData();
      } else {
        _showError(response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      print("Error disconnecting PayPal: $e");
      _showError('Something went wrong');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MyTheme.accent_color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  void _openBankModal() {
    // Reset form with current values
    _bankNameController.text = _displayBankName;
    _accountHolderController.text = _displayAccountHolder;
    _accountNumberController.text = _displayAccountNumber;
    _ifscCodeController.text = _displayIfscCode;
    
    setState(() {
      _isBankModalOpen = true;
    });
  }
  
  void _closeBankModal() {
    setState(() {
      _isBankModalOpen = false;
    });
  }
  
  void _openPaypalModal() {
    _paypalEmailController.text = _displayPaypalEmail;
    setState(() {
      _isPaypalModalOpen = true;
    });
  }
  
  void _closePaypalModal() {
    setState(() {
      _isPaypalModalOpen = false;
    });
  }
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.payment_settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()  // Show shimmer while loading
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    child: Column(
                      children: [
                        // Bank Details Card
                        _buildPaymentCard(
                          icon: Icons.account_balance,
                          title: AppLocalizations.of(context)!.bank_details,
                          description: AppLocalizations.of(context)!.bank_details_desc,
                          isConnected: _bankConnected,
                          onTap: _openBankModal,
                          onDisconnect: _bankConnected ? _disconnectBank : null,
                        ),
                        const SizedBox(height: 8),
                        
                        // PayPal Details Card
                        _buildPaymentCard(
                          icon: Icons.payment,
                          title: AppLocalizations.of(context)!.paypal_details,
                          description: AppLocalizations.of(context)!.paypal_details_desc,
                          isConnected: _paypalConnected,
                          onTap: _openPaypalModal,
                          onDisconnect: _paypalConnected ? _disconnectPaypal : null,
                        ),
                      ],
                    ),
                  ),
                  
                  // Bank Modal
                  if (_isBankModalOpen)
                    _buildBankModal(),
                  
                  // PayPal Modal
                  if (_isPaypalModalOpen)
                    _buildPaypalModal(),
                ],
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        children: [
          // Bank card shimmer
          ShimmerHelper().buildBasicShimmer(height: 80, radius: 7),
          const SizedBox(height: 8),
          // PayPal card shimmer
          ShimmerHelper().buildBasicShimmer(height: 80, radius: 7),
        ],
      ),
    );
  }
  
  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isConnected,
    required VoidCallback onTap,
    VoidCallback? onDisconnect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFEEF2F8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Left side - Icon and Info
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: MyTheme.accent_color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Status and Actions
            Row(
              children: [
                if (onDisconnect != null)
                  GestureDetector(
                    onTap: onDisconnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isConnected
                        ? AppLocalizations.of(context)!.connected
                        : AppLocalizations.of(context)!.not_connected,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isConnected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTap,
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBankModal() {
    return GestureDetector(
      onTap: _closeBankModal,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450,
                maxHeight: 550,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
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
                          Text(
                            AppLocalizations.of(context)!.bank_details,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: _closeBankModal,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(50),
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
                    
                    // Modal Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildFormField(
                              label: AppLocalizations.of(context)!.bank_name,
                              hint: AppLocalizations.of(context)!.enter_bank_name,
                              controller: _bankNameController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: AppLocalizations.of(context)!.account_holder_name,
                              hint: AppLocalizations.of(context)!.enter_account_holder_name,
                              controller: _accountHolderController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: AppLocalizations.of(context)!.account_number,
                              hint: AppLocalizations.of(context)!.enter_account_number,
                              controller: _accountNumberController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'IFSC Code',
                              hint: 'Enter IFSC Code',
                              controller: _ifscCodeController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Modal Footer
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
                              onTap: _closeBankModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel_ucf,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSaving ? null : _saveBankDetails,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.save_ucf,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
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
      ),
    );
  }

  Widget _buildPaypalModal() {
    return GestureDetector(
      onTap: _closePaypalModal,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450,
                maxHeight: 380,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
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
                          Text(
                            AppLocalizations.of(context)!.paypal_details,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: _closePaypalModal,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(50),
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
                    
                    // Modal Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildFormField(
                          label: AppLocalizations.of(context)!.paypal_email,
                          hint: AppLocalizations.of(context)!.enter_paypal_email,
                          controller: _paypalEmailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ),
                    
                    // Modal Footer
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
                              onTap: _closePaypalModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel_ucf,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSaving ? null : _savePaypalDetails,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.save_ucf,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
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
      ),
    );
  }
  
  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: MyTheme.accent_color),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }
}