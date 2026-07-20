import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_payment_details);
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
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_bank_name);
      return;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_account_holder_name);
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_account_number);
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
        
        ToastComponent.showSuccess(AppLocalizations.of(context)!.bank_details_saved_successfully);
        
        await _fetchUserData();
      } else {
        ToastComponent.showError(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error saving bank details: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.something_went_wrong);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _savePaypalDetails() async {
    if (_paypalEmailController.text.trim().isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_paypal_email);
      return;
    }
    if (!_paypalEmailController.text.contains('@')) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_valid_email);
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
        
        ToastComponent.showSuccess(AppLocalizations.of(context)!.paypal_details_saved_successfully);
        
        await _fetchUserData();
      } else {
        ToastComponent.showError(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error saving PayPal details: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.something_went_wrong);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppLocalizations.of(context)!.disconnect_bank,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.disconnect_bank_confirmation,
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizations.of(context)!.disconnect_ucf,
              style: TextStyle(fontSize: 14.sp),
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
        
        ToastComponent.showSuccess(AppLocalizations.of(context)!.bank_disconnected_successfully);
        await _fetchUserData();
      } else {
        ToastComponent.showError(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error disconnecting bank: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.something_went_wrong);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppLocalizations.of(context)!.disconnect_paypal,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.disconnect_paypal_confirmation,
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizations.of(context)!.disconnect_ucf,
              style: TextStyle(fontSize: 14.sp),
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
        
        ToastComponent.showSuccess(AppLocalizations.of(context)!.paypal_disconnected_successfully);
        await _fetchUserData();
      } else {
        ToastComponent.showError(response['message'] ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      print("Error disconnecting PayPal: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.something_went_wrong);
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
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
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
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
                    child: Column(
                      children: [
                        // ✅ ADDED: Subtitle text at the top
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFFEEF2F8),
                              width: 1.w,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.payment_settings_subtitle,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        
                        _buildPaymentCard(
                          icon: Icons.account_balance,
                          title: AppLocalizations.of(context)!.bank_details,
                          description: AppLocalizations.of(context)!.bank_details_desc,
                          isConnected: _bankConnected,
                          onTap: _openBankModal,
                          onDisconnect: _bankConnected ? _disconnectBank : null,
                        ),
                        SizedBox(height: 8.h),
                        
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
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
      child: Column(
        children: [
          ShimmerHelper().buildBasicShimmer(height: 60.h, radius: 12.r),
          SizedBox(height: 16.h),
          ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 7.r),
          SizedBox(height: 8.h),
          ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 7.r),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(7.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Icon(
                        icon,
                        size: 20.sp,
                        color: MyTheme.accent_color,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      isConnected
                          ? AppLocalizations.of(context)!.connected
                          : AppLocalizations.of(context)!.not_connected,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14.sp,
                    color: const Color(0xFF94A3B8),
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
                maxWidth: 450.w,
                maxHeight: 550.h,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEF2F8)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.bank_details,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: _closeBankModal,
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(50.r),
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
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          children: [
                            _buildFormField(
                              label: AppLocalizations.of(context)!.bank_name,
                              hint: AppLocalizations.of(context)!.enter_bank_name,
                              controller: _bankNameController,
                            ),
                            SizedBox(height: 16.h),
                            _buildFormField(
                              label: AppLocalizations.of(context)!.account_holder_name,
                              hint: AppLocalizations.of(context)!.enter_account_holder_name,
                              controller: _accountHolderController,
                            ),
                            SizedBox(height: 16.h),
                            _buildFormField(
                              label: AppLocalizations.of(context)!.account_number,
                              hint: AppLocalizations.of(context)!.enter_account_number,
                              controller: _accountNumberController,
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16.h),
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
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
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
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel_ucf,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSaving ? null : _saveBankDetails,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        height: 20.w,
                                        width: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.save_ucf,
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
                maxWidth: 450.w,
                maxHeight: 380.h,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEF2F8)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.paypal_details,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: _closePaypalModal,
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(50.r),
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
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: _buildFormField(
                          label: AppLocalizations.of(context)!.paypal_email,
                          hint: AppLocalizations.of(context)!.enter_paypal_email,
                          controller: _paypalEmailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
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
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel_ucf,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSaving ? null : _savePaypalDetails,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        height: 20.w,
                                        width: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.save_ucf,
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
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: MyTheme.accent_color, width: 1.5.w),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}