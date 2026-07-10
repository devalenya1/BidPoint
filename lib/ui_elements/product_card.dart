import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';


class ProductCard extends StatefulWidget {
  final int id;
  final String slug;
  final String? image;
  final String? name;
  final String? description;
  final int? pointPerBid;
  final dynamic auctionEndDate;
  final dynamic auctionStartDate;
  final dynamic currentBid;
  final dynamic startingBid;
  final bool isAuctionActive;
  // Add these for compatibility with calls from other files
  final String? main_price;
  final String? stroked_price;
  final bool? has_discount;
  final dynamic discount;
  final bool? is_wholesale;

  const ProductCard({
    Key? key,
    required this.id,
    required this.slug,
    this.image,
    this.name,
    this.description,
    this.pointPerBid,
    this.auctionEndDate,
    this.auctionStartDate,
    this.currentBid,
    this.startingBid,
    this.isAuctionActive = true,
    this.main_price,
    this.stroked_price,
    this.has_discount,
    this.discount,
    this.is_wholesale,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
  String _auctionStatus = "active"; // "upcoming", "active", "ended"
  bool _isProcessing = false;
  
  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _determineAuctionStatus();
    if (_auctionStatus == "active" && widget.auctionEndDate != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _determineAuctionStatus() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // ============================================
    // STEP 1: Check if auction is UPCOMING
    // ============================================
    // This should be checked FIRST before anything else
    if (widget.auctionStartDate != null) {
      // Case 1: Server returns string "Upcoming" - THIS IS THE MOST IMPORTANT CASE
      if (widget.auctionStartDate is String && widget.auctionStartDate == "Upcoming") {
        _auctionStatus = "upcoming";
        _timeLeft = "Upcoming";
        return;
      }
      
      // Case 2: Server returns timestamp as int
      if (widget.auctionStartDate is int) {
        final startDate = widget.auctionStartDate as int;
        if (startDate > now) {
          _auctionStatus = "upcoming";
          _timeLeft = "Upcoming";
          return;
        }
      }
      
      // Case 3: Server returns timestamp as string
      if (widget.auctionStartDate is String) {
        final startDate = int.tryParse(widget.auctionStartDate);
        if (startDate != null && startDate > now) {
          _auctionStatus = "upcoming";
          _timeLeft = "Upcoming";
          return;
        }
      }
    }
    
    // ============================================
    // STEP 2: Check if auction is ENDED
    // ============================================
    // Only check this if NOT upcoming
    if (widget.auctionEndDate != null) {
      // Case 1: Server returns string "Ended"
      if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
        _auctionStatus = "ended";
        _timeLeft = "Ended";
        return;
      }
      
      // Case 2: Server returns timestamp as int
      if (widget.auctionEndDate is int) {
        final endDate = widget.auctionEndDate as int;
        if (endDate <= 0 || endDate <= now) {
          _auctionStatus = "ended";
          _timeLeft = "Ended";
          return;
        }
      }
      
      // Case 3: Server returns timestamp as string
      if (widget.auctionEndDate is String) {
        final endDate = int.tryParse(widget.auctionEndDate);
        if (endDate != null && (endDate <= 0 || endDate <= now)) {
          _auctionStatus = "ended";
          _timeLeft = "Ended";
          return;
        }
      }
    }
    
    // ============================================
    // STEP 3: If we get here, auction is ACTIVE
    // ============================================
    _auctionStatus = "active";
    // Start the countdown timer for active auctions
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimer();
    });
  }

  void _updateTimer() {
    // Don't update if not active
    if (_auctionStatus != "active") {
      return;
    }
    
    if (widget.auctionEndDate == null) {
      if (mounted) {
        setState(() {
          _timeLeft = "No Timer";
        });
      }
      return;
    }

    // Handle string values
    if (widget.auctionEndDate is String) {
      if (widget.auctionEndDate == "Ended") {
        if (mounted) {
          setState(() {
            _timeLeft = "Ended";
            _auctionStatus = "ended";
          });
        }
        _timer?.cancel();
        return;
      }
      // Try to parse string as int
      final parsed = int.tryParse(widget.auctionEndDate);
      if (parsed == null) {
        return;
      }
      // Continue with parsed value
      _handleCountdown(parsed);
      return;
    }

    // Handle int values
    if (widget.auctionEndDate is int) {
      _handleCountdown(widget.auctionEndDate);
      return;
    }
  }

  void _handleCountdown(int endDate) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = endDate - now;

    if (distance < 0) {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
          _auctionStatus = "ended";
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

  // ============ PRICE HELPERS ============
  
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

  void _navigateToProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(slug: widget.slug),
      ),
    );
  }

  Future<void> _notifyMe() async {
    if (_isProcessing) return;
    
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    
    _isProcessing = true;
    setState(() {});
    
    try {
      final response = await ProductRepository().notifyMeForAuction(widget.id);
      
      if (response['success'] == true) {
        ToastComponent.showSuccess(
          response['message'] ?? 'You will be notified when this auction starts!',
        );
      } else {
        ToastComponent.showError(
          response['message'] ?? 'Failed to set notification',
        );
      }
    } catch (e) {
      ToastComponent.showError('Error setting notification');
    } finally {
      _isProcessing = false;
      setState(() {});
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Login Required',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please login to set notification',
          style: TextStyle(fontSize: 13.sp),
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
    final isUpcoming = _auctionStatus == "upcoming";
    final isEnded = _auctionStatus == "ended";
    final isActive = _auctionStatus == "active";

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
          // Product Image with Timer
          Stack(
            children: [
              GestureDetector(
                onTap: _navigateToProduct,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
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
              // Timer Badge - Always show for all auction types
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isEnded 
                        ? Colors.red 
                        : (isUpcoming 
                            ? Colors.orange 
                            : const Color(0xFF009572)),
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
                        isEnded 
                            ? Icons.cancel 
                            : (isUpcoming
                                ? Icons.schedule
                                : Icons.access_time),
                        size: 10.sp, 
                        color: Colors.white,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        isUpcoming ? "Upcoming" : _timeLeft,
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Product Details
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                GestureDetector(
                  onTap: _navigateToProduct,
                  child: Text(
                    widget.name ?? 'Product',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Description
                GestureDetector(
                  onTap: _navigateToProduct,
                  child: Text(
                    widget.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: const Color(0xFF8F9AA7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 10.h),
                
                // Current Bid and Points Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Current Bid / Starting Bid
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUpcoming ? 'Starting Bid' : (isEnded ? 'Final Bid' : 'Current Bid'),
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: isEnded ? Colors.grey : const Color(0xFF80818B),
                          ),
                        ),
                        Text(
                          _formatPrice(displayBid),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: isEnded ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    // Points Badge - Hide for ended auctions
                    if (!isEnded)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 9.sp,
                              color: const Color(0xFF0092AC),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '1 Bid = ${widget.pointPerBid ?? 0}',
                              style: TextStyle(
                                fontSize: 6.sp,
                                fontWeight: FontWeight.w600,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // View Product Button OR Notify Me Button (for upcoming)
                GestureDetector(
                  onTap: isUpcoming ? _notifyMe : _navigateToProduct,
                  child: Container(
                    width: double.infinity,
                    height: 35.h,
                    decoration: BoxDecoration(
                      color: isEnded ? Colors.grey : (isUpcoming ? Colors.orange : MyTheme.accent_color),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: isUpcoming
                          ? (_isProcessing
                              ? SizedBox(
                                  height: 14.w,
                                  width: 14.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 12.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Notify Me',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isEnded ? 'Ended' : 'View Product',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (!isEnded) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 11.sp,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
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
  }
}