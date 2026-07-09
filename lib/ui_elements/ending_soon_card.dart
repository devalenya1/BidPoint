import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';

class EndingSoonCard extends StatefulWidget {
  final int id;
  final String slug;
  final String? image;
  final String? name;
  final String? description;
  final int? pointPerBid;
  final dynamic auctionEndDate;
  final dynamic currentBid;
  final dynamic startingBid;
  final bool isAuctionActive;
  final String? cardType; // 'left' or 'right'

  const EndingSoonCard({
    Key? key,
    required this.id,
    required this.slug,
    this.image,
    this.name,
    this.description,
    this.pointPerBid,
    this.auctionEndDate,
    this.currentBid,
    this.startingBid,
    this.isAuctionActive = true,
    this.cardType,
  }) : super(key: key);

  @override
  State<EndingSoonCard> createState() => _EndingSoonCardState();
}

class _EndingSoonCardState extends State<EndingSoonCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
  bool _isProcessing = false;
  double _swipeAmount = 0.0;
  bool _isSwiping = false;
  double _startX = 0;
  double _startY = 0;

  @override
  void initState() {
    super.initState();
    if (widget.auctionEndDate != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimer();
    });
  }

  void _updateTimer() {
    if (widget.auctionEndDate == null) {
      if (mounted) {
        setState(() {
          _timeLeft = "No Timer";
        });
      }
      return;
    }

    if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
        });
      }
      _timer?.cancel();
      return;
    }

    if (widget.auctionEndDate is String && widget.auctionEndDate == "Upcoming") {
      if (mounted) {
        setState(() {
          _timeLeft = "Upcoming";
        });
      }
      return;
    }

    int endDate;
    if (widget.auctionEndDate is int) {
      endDate = widget.auctionEndDate;
    } else if (widget.auctionEndDate is String) {
      endDate = int.tryParse(widget.auctionEndDate) ?? 0;
    } else {
      return;
    }

    if (endDate <= 0) {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
        });
      }
      _timer?.cancel();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = endDate - now;

    if (distance < 0) {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
        });
      }
      _timer?.cancel();
      return;
    }

    final days = distance ~/ (24 * 3600);
    final hours = (distance % (24 * 3600)) ~/ 3600;
    final minutes = (distance % 3600) ~/ 60;
    final seconds = distance % 60;

    String timeString;
    if (days > 0) {
      timeString = "${days}d ${hours}h";
    } else if (hours > 0) {
      timeString = "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      timeString = "${minutes}m ${seconds}s";
    } else {
      timeString = "${seconds}s";
    }

    if (mounted) {
      setState(() {
        _timeLeft = timeString;
      });
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // NEW - Uses FormatHelper
  String _formatPrice(dynamic price) {
    final doubleValue = _parsePrice(price);
    return FormatHelper.formatPrice(doubleValue);
  }

  double _getDisplayBid() {
    if (widget.currentBid != null) {
      final parsed = _parsePrice(widget.currentBid);
      if (parsed > 0) return parsed;
    }
    if (widget.startingBid != null) {
      final parsed = _parsePrice(widget.startingBid);
      if (parsed > 0) return parsed;
    }
    return 0.0;
  }

  void _onPanStart(DragStartDetails details) {
    _startX = details.localPosition.dx;
    _startY = details.localPosition.dy;
    _isSwiping = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    
    final deltaX = details.localPosition.dx - _startX;
    final deltaY = details.localPosition.dy - _startY;
    
    if (deltaX > 5 && deltaY.abs() < 50) {
      setState(() {
        _swipeAmount = deltaX.clamp(0.0, 60.0);
      });
    } else if (deltaX < -5) {
      setState(() {
        _swipeAmount = 0;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isSwiping) return;
    
    final wasSwiped = _swipeAmount >= 40;
    
    setState(() {
      _isSwiping = false;
      _swipeAmount = 0;
    });
    
    if (wasSwiped) {
      _quickBid();
    }
  }

  Future<void> _quickBid() async {
    if (_isProcessing) return;
    
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    
    _isProcessing = true;
    setState(() {});
    
    try {
      final currentBid = _getDisplayBid();
      final minBid = currentBid + 0.01;
      
      final response = await ProductRepository().quickBid(
        widget.id.toString(),
        minBid.toString(),
        type: 'quick',
      );
      
      if (response.success == true) {
        // ✅ Using showSuccess - Green with success sound
        ToastComponent.showSuccess(
          'Quick bid placed! Amount: ${_formatPrice(minBid)}',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(slug: widget.slug),
          ),
        );
      } else {
        // ✅ Using showError - Red with error sound
        ToastComponent.showError(
          response.message ?? 'Failed to place bid',
        );
      }
    } catch (e) {
      // ✅ Using showError - Red with error sound
      ToastComponent.showError('Error placing bid');
    } finally {
      _isProcessing = false;
      setState(() {});
    }
  }

  void _navigateToProductDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(slug: widget.slug),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Login Required',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please login to place a bid',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
            child: Text(
              'Login',
              style: TextStyle(fontSize: 14.sp, color: MyTheme.accent_color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayBid = _getDisplayBid();
    final isLeft = widget.cardType == 'left';
    final showTimer = _timeLeft != "No Timer" && _timeLeft != "Upcoming";

    if (isLeft) {
      return _buildLeftCard(displayBid, showTimer);
    } else {
      return _buildRightCard(displayBid, showTimer);
    }
  }

  Widget _buildLeftCard(double displayBid, bool showTimer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3.r,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image with Timer
          Stack(
            children: [
              GestureDetector(
                onTap: _navigateToProductDetails,
                child: SizedBox(
                  width: 100.w,
                  height: 100.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
                    child: widget.image != null && widget.image!.isNotEmpty
                        ? Image.network(
                            widget.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.image, size: 30.sp, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 30.sp, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              if (showTimer)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _timeLeft == "Ended" 
                          ? Colors.red 
                          : const Color(0xFF009572),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.r,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _timeLeft == "Ended" 
                              ? Icons.cancel 
                              : Icons.access_time,
                          size: 8.sp, 
                          color: Colors.white,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          _timeLeft,
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _navigateToProductDetails,
                    child: Text(
                      widget.name ?? 'Product',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid',
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: const Color(0xFF80818B),
                            ),
                          ),
                          Text(
                            _formatPrice(displayBid),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 7.sp,
                              color: const Color(0xFF0092AC),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '1 Bid = ${widget.pointPerBid ?? 0}',
                              style: TextStyle(
                                fontSize: 5.sp,
                                fontWeight: FontWeight.w600,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Swipe to Bid Button
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTap: _navigateToProductDetails,
                    child: Container(
                      width: double.infinity,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            width: 20.w + (_swipeAmount),
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: _swipeAmount > 20 ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: _swipeAmount > 20 ? Colors.white : MyTheme.accent_color,
                              ),
                            ),
                          ),
                          Center(
                            child: _isProcessing
                                ? SizedBox(
                                    height: 14.w,
                                    width: 14.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_swipeAmount < 20) ...[
                                        SizedBox(width: 20.w),
                                        Text(
                                          'Swipe to Bid',
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Quick Bid',
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightCard(double displayBid, bool showTimer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3.r,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Stack(
            children: [
              GestureDetector(
                onTap: _navigateToProductDetails,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                  child: Container(
                    height: 100.h,
                    width: double.infinity,
                    child: widget.image != null && widget.image!.isNotEmpty
                        ? Image.network(
                            widget.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.image, size: 40.sp, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 40.sp, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              if (showTimer)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _timeLeft == "Ended" 
                          ? Colors.red 
                          : const Color(0xFF009572),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.r,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _timeLeft == "Ended" 
                              ? Icons.cancel 
                              : Icons.access_time,
                          size: 7.sp, 
                          color: Colors.white,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          _timeLeft,
                          style: TextStyle(
                            fontSize: 6.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _navigateToProductDetails,
                        child: Text(
                          widget.name ?? 'Product',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 7.sp,
                              color: const Color(0xFF0092AC),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '1 Bid = ${widget.pointPerBid ?? 0}',
                              style: TextStyle(
                                fontSize: 5.sp,
                                fontWeight: FontWeight.w600,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid',
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: const Color(0xFF80818B),
                            ),
                          ),
                          Text(
                            _formatPrice(displayBid),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Swipe to Bid Button
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTap: _navigateToProductDetails,
                    child: Container(
                      width: double.infinity,
                      height: 35.h,
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            width: 20.w + (_swipeAmount),
                            height: 35.h,
                            decoration: BoxDecoration(
                              color: _swipeAmount > 20 ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: _swipeAmount > 20 ? Colors.white : MyTheme.accent_color,
                              ),
                            ),
                          ),
                          Center(
                            child: _isProcessing
                                ? SizedBox(
                                    height: 14.w,
                                    width: 14.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_swipeAmount < 20) ...[
                                        SizedBox(width: 20.w),
                                        Text(
                                          'Swipe',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Quick Bid',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
