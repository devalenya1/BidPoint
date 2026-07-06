import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  
  // ============ PAGINATION STATE ============
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  UserInformation? _userInfo;
  
  double _availableBalance = 0.0;
  double _minimumWithdrawAmount = 10.00;
  double _withdrawAmount = 0;
  final TextEditingController _amountController = TextEditingController();
  
  List<AffiliateWithdrawRequest> _withdrawalHistory = [];
  
  final ProfileRepository _profileRepository = ProfileRepository();

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
  
  String _getCurrencySymbol() {
    return '\$';
  }
  
  // ============ FETCH WITHDRAWAL DATA FROM API WITH PAGINATION ============
  Future<void> _fetchWithdrawalData({bool loadMore = false}) async {
    try {
      if (loadMore) {
        if (_isLoadingMore || !_hasMore) return;
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _currentPage = 1;
          _hasMore = true;
          _withdrawalHistory.clear();
        });
      }

      final page = loadMore ? _currentPage + 1 : 1;
      
      var response = await _profileRepository.getUserInfoResponse(
        notificationPage: 1,
        notificationPerPage: 10,
        pointPage: 1,
        pointPerPage: 10,
        cashPage: 1,
        cashPerPage: 10,
        withdrawPage: page,
        withdrawPerPage: _perPage,
      );
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final newUserInfo = response.data![0];
        
        // Update pagination info from withdraw_pagination
        final pagination = newUserInfo.withdrawPagination;
        if (pagination != null) {
          _currentPage = pagination.currentPage;
          _totalPages = pagination.totalPages;
          _totalItems = pagination.total;
          _perPage = pagination.perPage;
          _hasMore = pagination.hasNext;
        }
        
        setState(() {
          if (loadMore) {
            // Append new items to existing list
            final newItems = newUserInfo.affiliateWithdrawRequests ?? [];
            _withdrawalHistory.addAll(newItems);
          } else {
            // First page - replace all data
            _userInfo = newUserInfo;
            _availableBalance = _userInfo?.affiliateBalance ?? 0.0;
            _withdrawalHistory = _userInfo?.affiliateWithdrawRequests ?? [];
          }
        });
      } else {
        if (!loadMore) {
          _useDefaultData();
        }
      }
    } catch (e) {
      print("Error loading withdrawal data: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_withdrawal_data);
      if (!loadMore) {
        _useDefaultData();
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
      });
    }
  }
  
  // ============ LOAD MORE (INFINITE SCROLL) ============
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await _fetchWithdrawalData(loadMore: true);
  }
  
  void _useDefaultData() {
    setState(() {
      _availableBalance = 0.0;
      _withdrawalHistory = [];
      _totalItems = 0;
      _totalPages = 1;
      _hasMore = false;
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchWithdrawalData(loadMore: false);
  }
  
  // ============ SUBMIT WITHDRAWAL REQUEST TO SERVER ============
  Future<void> _submitWithdrawalRequest(double amount) async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final response = await _profileRepository.submitWithdrawalRequest(amount);
      
      if (response['success'] == true) {
        ToastComponent.showSuccess(
          response['message'] ?? AppLocalizations.of(context)!.withdrawal_request_submitted,
        );
        
        // Refresh data after successful submission
        await _fetchWithdrawalData(loadMore: false);
      } else {
        ToastComponent.showError(
          response['message'] ?? AppLocalizations.of(context)!.withdrawal_request_failed,
        );
      }
    } catch (e) {
      print("Error submitting withdrawal: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.withdrawal_request_failed);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  // ============ CENTER POPUP DIALOG (Not Bottom Sheet) ============
  void _showWithdrawModal() {
    _amountController.clear();
    _withdrawAmount = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.request_quote,
                      color: MyTheme.accent_color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.withdraw_request,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxWidth: 450.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Available Balance Display
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.available_balance,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            FormatHelper.formatPrice(_availableBalance),
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0092AC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Withdrawal Amount Field
                    Text(
                      AppLocalizations.of(context)!.withdrawal_amount,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5.w),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Text(
                              _getCurrencySymbol(),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
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
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.min_ucf}: ${FormatHelper.formatPrice(_minimumWithdrawAmount)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.max_ucf}: ${FormatHelper.formatPrice(_availableBalance)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Quick Amount Buttons
                    if (_availableBalance > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: Row(
                          children: [
                            _buildQuickAmountButton(
                              amount: (_minimumWithdrawAmount < _availableBalance) 
                                  ? _minimumWithdrawAmount 
                                  : _availableBalance,
                              setModalState: setModalState,
                            ),
                            SizedBox(width: 8.w),
                            _buildQuickAmountButton(
                              amount: (25.0 < _availableBalance) ? 25.0 : _availableBalance,
                              setModalState: setModalState,
                            ),
                            SizedBox(width: 8.w),
                            _buildQuickAmountButton(
                              amount: (50.0 < _availableBalance) ? 50.0 : _availableBalance,
                              setModalState: setModalState,
                            ),
                            SizedBox(width: 8.w),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.cancel_ucf,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _validateAndSubmit(setModalState, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyTheme.accent_color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.confirm_withdrawal,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
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
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Text(
            label ?? '${_getCurrencySymbol()}${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
  
  void _validateAndSubmit(StateSetter setModalState, BuildContext modalContext) {
    if (_withdrawAmount <= 0) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_valid_amount);
      return;
    }
    
    if (_withdrawAmount > _availableBalance) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.insufficient_balance);
      return;
    }
    
    if (_withdrawAmount < _minimumWithdrawAmount) {
      ToastComponent.showWarning(
        '${AppLocalizations.of(context)!.min_withdrawal_amount} ${FormatHelper.formatPrice(_minimumWithdrawAmount)}'
      );
      return;
    }
    
    // Close the modal
    Navigator.pop(modalContext);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            AppLocalizations.of(context)!.confirm_withdrawal,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.amount_ucf,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Text(
                      FormatHelper.formatPrice(_withdrawAmount),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel_ucf,
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
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
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.confirm_ucf,
                style: TextStyle(fontSize: 14.sp),
              ),
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
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // Detect when user scrolls to bottom
                  if (!_isLoadingMore &&
                      _hasMore &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                    _loadMore();
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards Row
                      Row(
                        children: [
                          // Affiliate Balance Card
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    child: Icon(
                                      Icons.attach_money,
                                      size: 28.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.affiliate_balance,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    FormatHelper.formatPrice(_availableBalance),
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          // Withdraw Request Card
                          Expanded(
                            child: GestureDetector(
                              onTap: _showWithdrawModal,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FC),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: const Color(0xFFEEF2F8), width: 1.w),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 28.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.withdraw_request,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF666666),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      AppLocalizations.of(context)!.withdraw_ucf,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Withdraw Request History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.withdraw_request_history,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.total_ucf}: $_totalItems',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      
                      // History List - With proper container for empty state
                      Container(
                        width: double.infinity,
                        child: _withdrawalHistory.isEmpty
                            ? _buildEmptyState()
                            : Column(
                                children: [
                                  ..._withdrawalHistory.map((withdrawal) {
                                    final date = withdrawal.createdAt;
                                    return Container(
                                      padding: EdgeInsets.all(16.w),
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FC),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 40.w,
                                                  child: Text(
                                                    '#${(_withdrawalHistory.indexOf(withdrawal) + 1).toString().padLeft(2, '0')}',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF666666),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16.w),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      date != null ? _formatDate(date) : AppLocalizations.of(context)!.unknown_date,
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: const Color(0xFF666666),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      FormatHelper.formatPrice(withdrawal.amount ?? 0),
                                                      style: TextStyle(
                                                        fontSize: 16.sp,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF0092AC),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          Flexible(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: _getStatusBackgroundColor(withdrawal.status ?? 0),
                                                borderRadius: BorderRadius.circular(20.r),
                                              ),
                                              child: Text(
                                                _getStatusText(withdrawal.status ?? 0),
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(withdrawal.status ?? 0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  // Loading indicator at bottom
                                  if (_isLoadingMore)
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      child: Center(
                                        child: SizedBox(
                                          height: 24.w,
                                          width: 24.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            color: MyTheme.accent_color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // End of list message
                                  if (!_hasMore && _withdrawalHistory.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 16.h),
                                      child: Text(
                                        'No more withdrawal history',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF999999),
                                        ),
                                        textAlign: TextAlign.center,
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
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            '💰',
            style: TextStyle(fontSize: 48.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.no_withdrawal_requests_found,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120.h, radius: 16.r)),
              SizedBox(width: 15.w),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 120.h, radius: 16.r)),
            ],
          ),
          SizedBox(height: 24.h),
          ShimmerHelper().buildBasicShimmer(height: 20.h, width: 180.w),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => 
                ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 12.r),
          ),
        ],
      ),
    );
  }
}