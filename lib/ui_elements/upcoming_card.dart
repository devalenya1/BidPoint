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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UpcomingCard extends StatefulWidget {
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

  const UpcomingCard({
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
    this.isAuctionActive = false,
  }) : super(key: key);

  @override
  State<UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<UpcomingCard> {
  Timer? _timer;
  String _timeLeft = "";
  bool _isTimerLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
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
    final localizations = AppLocalizations.of(context);
    
    if (widget.auctionEndDate == null) {
      if (mounted) {
        setState(() {
          _timeLeft = localizations?.no_timer_ucf ?? "No Timer";
          _isTimerLoading = false;
        });
      }
      return;
    }

    if (widget.auctionEndDate is String && widget.auctionEndDate == "Upcoming") {
      if (mounted) {
        setState(() {
          _timeLeft = localizations?.upcoming_ucf ?? "Upcoming";
          _isTimerLoading = false;
        });
      }
      return;
    }

    if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
      if (mounted) {
        setState(() {
          _timeLeft = localizations?.upcoming_ucf ?? "Upcoming";
          // _timeLeft = localizations?.ended_ucf ?? "Ended";
          _isTimerLoading = false;
        });
      }
      _timer?.cancel();
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
          _timeLeft = localizations?.upcoming_ucf ?? "Upcoming";
          // _timeLeft = localizations?.ended_ucf ?? "Ended";
          _isTimerLoading = false;
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
          _timeLeft = localizations?.upcoming_ucf ?? "Upcoming";
          // _timeLeft = localizations?.ended_ucf ?? "Ended";
          _isTimerLoading = false;
        });
      }
      _timer?.cancel();
      return;
    }

    final days = distance ~/ (24 * 3600);
    final hours = (distance % (24 * 3600)) ~/ 3600;
    final minutes = (distance % 3600) ~/ 60;
    final seconds = distance % 60;

    final daySuffix = localizations?.day_short_ucf ?? "d";
    final hourSuffix = localizations?.hour_short_ucf ?? "h";
    final minuteSuffix = localizations?.minute_short_ucf ?? "m";
    final secondSuffix = localizations?.second_short_ucf ?? "s";

    String timeString;
    if (days > 0) {
      timeString = "$days$daySuffix $hours$hourSuffix";
    } else if (hours > 0) {
      timeString = "$hours$hourSuffix $minutes$minuteSuffix";
    } else if (minutes > 0) {
      timeString = "$minutes$minuteSuffix $seconds$secondSuffix";
    } else {
      timeString = "$seconds$secondSuffix";
    }

    if (mounted) {
      setState(() {
        _timeLeft = timeString;
        _isTimerLoading = false;
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

  void _navigateToProductDetails() {
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
      final localizations = AppLocalizations.of(context);
      final response = await ProductRepository().notifyMeForAuction(widget.id);
      
      if (response['success'] == true) {
        // ✅ Using showSuccess - Green with success sound
        ToastComponent.showSuccess(
          response['message'] ?? (localizations?.notify_me_success_ucf ?? 'You will be notified when this auction starts!'),
        );
      } else {
        // ✅ Using showError - Red with error sound
        ToastComponent.showError(
          response['message'] ?? (localizations?.failed_to_set_notification_ucf ?? 'Failed to set notification'),
        );
      }
    } catch (e) {
      // ✅ Using showError - Red with error sound
      final localizations = AppLocalizations.of(context);
      ToastComponent.showError(localizations?.error_setting_notification_ucf ?? 'Error setting notification');
    } finally {
      _isProcessing = false;
      setState(() {});
    }
  }

  void _showLoginDialog() {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          localizations?.login_required_ucf ?? 'Login Required',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          localizations?.please_login_to_set_notification_ucf ?? 'Please login to set notification',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations?.cancel_ucf ?? 'Cancel',
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
              localizations?.login_ucf ?? 'Login',
              style: TextStyle(fontSize: 14.sp, color: MyTheme.accent_color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final displayBid = _getDisplayBid();
    
    final upcomingText = localizations?.upcoming_ucf ?? "Upcoming";
    final noTimerText = localizations?.no_timer_ucf ?? "No Timer";
    final showTimer = !_isTimerLoading && _timeLeft != upcomingText && _timeLeft != noTimerText;

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
                onTap: _navigateToProductDetails,
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
              // Timer/Status Badge
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _timeLeft == upcomingText 
                        ? Colors.orange 
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
                        _timeLeft == upcomingText 
                            ? Icons.schedule 
                            : Icons.access_time,
                        size: 10.sp, 
                        color: Colors.white,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        _timeLeft,
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
                  onTap: _navigateToProductDetails,
                  child: Text(
                    widget.name ?? (localizations?.product_ucf ?? 'Product'),
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
                  onTap: _navigateToProductDetails,
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
                
                // Starting Bid and Points Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.starting_bid_ucf ?? 'Starting Bid',
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: const Color(0xFF80818B),
                          ),
                        ),
                        Text(
                          _formatPrice(displayBid),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
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
                            '${localizations?.one_bid_equals_ucf ?? "1 Bid ="} ${widget.pointPerBid ?? 0}',
                            style: TextStyle(
                              fontSize: 6.sp,
                              fontWeight: FontWeight.w500,
                              color: MyTheme.accent_color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // Notify Me Button
                GestureDetector(
                  onTap: _notifyMe,
                  child: Container(
                    width: double.infinity,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? SizedBox(
                              height: 16.w,
                              width: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  localizations?.notify_me_ucf ?? 'Notify Me',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 12.sp,
                                  color: Colors.white,
                                ),
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