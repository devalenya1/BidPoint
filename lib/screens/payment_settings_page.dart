import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({Key? key}) : super(key: key);

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  // ============ LOCAL STATE ============
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
      _fetchUserData();
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
  
  // ============ FETCH DATA FROM API ============
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        _loadPaymentDetailsFromUserInfo();
        
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_payment_details);
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
    
    final hasPaypal = _userInfo!.paypalEmail != null && _userInfo!.paypalEmail!.isNotEmpty;
    if (hasPaypal) {
      _paypalEmailController.text = _userInfo!.paypalEmail!;
    }
    
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
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchUserData();
  }
  
  // Helper getters for payment status
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
    if (_bankNameController.text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_enter_bank_name);
      return;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_enter_account_holder_name);
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_enter_account_number);
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
        
        ToastComponent.showDialog(AppLocalizations.of(context)!.bank_details_saved_successfully);
        
        await _fetchUserData();
      } else {
        ToastComponent.showDialog(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error saving bank details: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.something_went_wrong);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _savePaypalDetails() async {
    if (_paypalEmailController.text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_enter_paypal_email);
      return;
    }
    if (!_paypalEmailController.text.contains('@')) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.please_enter_valid_email);
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
        
        ToastComponent.showDialog(AppLocalizations.of(context)!.paypal_details_saved_successfully);
        
        await _fetchUserData();
      } else {
        ToastComponent.showDialog(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error saving PayPal details: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.something_went_wrong);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.disconnect_bank,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.disconnect_bank_confirmation,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel_ucf),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.disconnect_ucf),
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
        
        ToastComponent.showDialog(AppLocalizations.of(context)!.bank_disconnected_successfully);
        await _fetchUserData();
      } else {
        ToastComponent.showDialog(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error disconnecting bank: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.something_went_wrong);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.disconnect_paypal,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.disconnect_paypal_confirmation,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel_ucf),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.disconnect_ucf),
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
        
        ToastComponent.showDialog(AppLocalizations.of(context)!.paypal_disconnected_successfully);
        await _fetchUserData();
      } else {
        ToastComponent.showDialog(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error disconnecting PayPal: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.something_went_wrong);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  void _openBankModal() {
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
  
  // ============ BUILD UI ============
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    child: Column(
                      children: [
                        _buildPaymentCard(
                          icon: Icons.account_balance,
                          title: AppLocalizations.of(context)!.bank_details,
                          description: AppLocalizations.of(context)!.bank_details_desc,
                          isConnected: _bankConnected,
                          onTap: _openBankModal,
                          onDisconnect: _bankConnected ? _disconnectBank : null,
                        ),
                        const SizedBox(height: 8),
                        
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
                  
                  if (_isBankModalOpen)
                    _buildBankModal(),
                  
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        children: [
          ShimmerHelper().buildBasicShimmer(height: 80, radius: 7),
          const SizedBox(height: 8),
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
    return InkWell(
      onTap: onTap,  // Whole card is now tappable
      borderRadius: BorderRadius.circular(7),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFEEF2F8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              label: AppLocalizations.of(context)!.ifsc_code,
                              hint: AppLocalizations.of(context)!.enter_ifsc_code,
                              controller: _ifscCodeController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MyTheme.accent_color),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}