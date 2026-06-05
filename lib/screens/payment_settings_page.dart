import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({Key? key}) : super(key: key);

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  // Bank details
  bool _bankConnected = false;
  TextEditingController _bankNameController = TextEditingController();
  TextEditingController _accountHolderController = TextEditingController();
  TextEditingController _accountNumberController = TextEditingController();
  
  // PayPal details
  bool _paypalConnected = false;
  TextEditingController _paypalEmailController = TextEditingController();
  
  // Modal visibility
  bool _isBankModalOpen = false;
  bool _isPaypalModalOpen = false;
  
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }
  
  void _loadSavedData() {
    // Demo: Load saved data from shared preferences or API
    // For demo purposes, we'll set some sample data
    _bankConnected = false;
    _paypalConnected = false;
    
    // Uncomment to test with pre-filled data
    // _bankNameController.text = "Chase Bank";
    // _accountHolderController.text = "John Doe";
    // _accountNumberController.text = "****1234";
    // _paypalEmailController.text = "john.doe@example.com";
    // _bankConnected = true;
    // _paypalConnected = true;
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  void _openBankModal() {
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
    setState(() {
      _isPaypalModalOpen = true;
    });
  }
  
  void _closePaypalModal() {
    setState(() {
      _isPaypalModalOpen = false;
    });
  }
  
  void _saveBankDetails() {
    // Validate
    if (_bankNameController.text.trim().isEmpty ||
        _accountHolderController.text.trim().isEmpty ||
        _accountNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.please_fill_all_fields),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Save logic here
    setState(() {
      _bankConnected = true;
      _isBankModalOpen = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.bank_details_saved),
        backgroundColor: MyTheme.accent_color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _savePaypalDetails() {
    // Validate
    if (_paypalEmailController.text.trim().isEmpty ||
        !_paypalEmailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enter_valid_email),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Save logic here
    setState(() {
      _paypalConnected = true;
      _isPaypalModalOpen = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.paypal_details_saved),
        backgroundColor: MyTheme.accent_color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
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
                ),
                const SizedBox(height: 8),
                
                // PayPal Details Card
                _buildPaymentCard(
                  icon: Icons.payment,
                  title: AppLocalizations.of(context)!.paypal_details,
                  description: AppLocalizations.of(context)!.paypal_details_desc,
                  isConnected: _paypalConnected,
                  onTap: _openPaypalModal,
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
    );
  }
  
 
  
  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              // Right side - Status and Arrow
              Row(
                children: [
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
                maxHeight: 500,
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
                              onTap: _saveBankDetails,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
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
                maxHeight: 350,
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
                              onTap: _savePaypalDetails,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: MyTheme.accent_color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
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