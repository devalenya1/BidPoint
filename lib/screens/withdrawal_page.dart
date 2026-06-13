import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({Key? key}) : super(key: key);

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  
  UserInformation? _userInfo;  // Store user info for balance and withdrawal history
  
  double _availableBalance = 0.0;
  double _minimumWithdrawAmount = 10.00;
  double _withdrawAmount = 0;
  final TextEditingController _amountController = TextEditingController();
  
  List<AffiliateWithdrawRequest> _withdrawalHistory = [];
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchWithdrawalData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  // ============ FETCH WITHDRAWAL DATA FROM API ============
  Future<void> _fetchWithdrawalData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
          _availableBalance = _userInfo?.affiliateBalance ?? 0.0;
          _withdrawalHistory = _userInfo?.affiliateWithdrawRequests ?? [];
        });
      } else {
        _useDefaultData();
      }
    } catch (e) {
      print("Error loading withdrawal data: $e");
      _useDefaultData();
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  void _useDefaultData() {
    setState(() {
      _availableBalance = 0.0;
      _withdrawalHistory = [];
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchWithdrawalData();
  }
  
  // ============ SUBMIT WITHDRAWAL REQUEST ============
  Future<void> _submitWithdrawalRequest(double amount) async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // TODO: Call API to submit withdrawal request
      // var response = await ProfileRepository().submitWithdrawalRequest(amount);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Refresh data after successful submission
      await _fetchWithdrawalData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.withdrawal_request_submitted),
            backgroundColor: MyTheme.accent_color,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error submitting withdrawal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit withdrawal request'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  void _showWithdrawModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEEF2F8)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.withdraw_request,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Modal Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Available Balance Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.available_balance,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                FormatHelper.formatPrice(_availableBalance),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0092AC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Withdrawal Amount Field
                        Text(
                          AppLocalizations.of(context)!.withdrawal_amount,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  FormatHelper.getCurrencySymbol(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      _withdrawAmount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Min/Max Hint
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.min_ucf}: ${FormatHelper.formatPrice(_minimumWithdrawAmount)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.max_ucf}: ${FormatHelper.formatPrice(_availableBalance)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Quick Amount Buttons
                        if (_availableBalance > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                _buildQuickAmountButton(
                                  amount: (_minimumWithdrawAmount < _availableBalance) 
                                      ? _minimumWithdrawAmount 
                                      : _availableBalance,
                                  setModalState: setModalState,
                                ),
                                const SizedBox(width: 10),
                                _buildQuickAmountButton(
                                  amount: (25.0 < _availableBalance) ? 25.0 : _availableBalance,
                                  setModalState: setModalState,
                                ),
                                const SizedBox(width: 10),
                                _buildQuickAmountButton(
                                  amount: (50.0 < _availableBalance) ? 50.0 : _availableBalance,
                                  setModalState: setModalState,
                                ),
                                const SizedBox(width: 10),
                                _buildQuickAmountButton(
                                  amount: _availableBalance,
                                  label: AppLocalizations.of(context)!.max_ucf,
                                  setModalState: setModalState,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Modal Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFEEF2F8)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.cancel_ucf,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isSubmitting ? null : () => _validateAndSubmit(setModalState, context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isSubmitting ? MyTheme.medium_grey : MyTheme.accent_color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.confirm_withdrawal,
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
            );
          },
        );
      },
    );
  }
  
  Widget _buildQuickAmountButton({
    required double amount,
    String? label,
    required StateSetter setModalState,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            _withdrawAmount = amount;
            _amountController.text = amount.toStringAsFixed(2);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label ?? '${FormatHelper.getCurrencySymbol()}${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
  
  void _validateAndSubmit(StateSetter setModalState, BuildContext modalContext) {
    if (_withdrawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_withdrawAmount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_withdrawAmount < _minimumWithdrawAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal amount is ${FormatHelper.formatPrice(_minimumWithdrawAmount)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Close modal
    Navigator.pop(modalContext);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppLocalizations.of(context)!.confirm_withdrawal,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context)!.amount_ucf}: ${FormatHelper.formatPrice(_withdrawAmount)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel_ucf,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitWithdrawalRequest(_withdrawAmount);
                _amountController.clear();
                _withdrawAmount = 0;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.confirm_ucf),
            ),
          ],
        );
      },
    );
  }
  
  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return AppLocalizations.of(context)!.approved_ucf;
      case 2:
        return AppLocalizations.of(context)!.rejected_ucf;
      default:
        return AppLocalizations.of(context)!.pending_ucf;
    }
  }
  
  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF2E7D32);
      case 2:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }
  
  Color _getStatusBackgroundColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFFE8F5E9);
      case 2:
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF3E0);
    }
  }
  
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.affiliate_ucf,
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
            ? _buildShimmer()
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards Row
                    Row(
                      children: [
                        // Affiliate Balance Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: const Icon(
                                    Icons.attach_money,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.affiliate_balance,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  FormatHelper.formatPrice(_availableBalance),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Withdraw Request Card
                        Expanded(
                          child: GestureDetector(
                            onTap: _showWithdrawModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEEF2F8)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      size: 28,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.withdraw_request,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppLocalizations.of(context)!.withdraw_ucf,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Withdraw Request History Section
                    Text(
                      AppLocalizations.of(context)!.withdraw_request_history,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // History List
                    Expanded(
                      child: _withdrawalHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '💰',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!.no_withdrawal_requests_found,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _withdrawalHistory.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final withdrawal = _withdrawalHistory[index];
                                final date = withdrawal.createdAt;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Left side - Index and Date
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '#${(index + 1).toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                date != null ? _formatDate(date) : 'Unknown date',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                FormatHelper.formatPrice(withdrawal.amount ?? 0),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0092AC),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      // Right side - Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusBackgroundColor(withdrawal.status ?? 0),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusText(withdrawal.status ?? 0),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(withdrawal.status ?? 0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards Row Shimmer
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120, radius: 16)),
              const SizedBox(width: 15),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120, radius: 16)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // History Header Shimmer
          ShimmerHelper().buildBasicShimmer(height: 20, width: 180),
          const SizedBox(height: 16),
          
          // History Items Shimmer
          Expanded(
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => 
                  ShimmerHelper().buildBasicShimmer(height: 80, radius: 12),
            ),
          ),
        ],
      ),
    );
  }
}