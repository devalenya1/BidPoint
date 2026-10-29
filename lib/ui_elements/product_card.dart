import 'dart:async';

import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final dynamic purchasePrice;

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
    this.purchasePrice,
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
  String _timeLeft = "";
  bool _isTimerLoading = true;
  String _auctionStatus = "active";
  bool _isProcessing = false;
  bool _isWishlisted = false;
  bool _isWishlistLoading = false;

  double _slideOffset = 0;
  double _thumbStartX = 0;
  bool _isDragging = false;
  static const double _thumbSize = 28;

  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _determineAuctionStatus();
    if (_auctionStatus == "active") {
      _startTimer();
    } else {
      _isTimerLoading = false;
    }
    _fetchWishlistStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWishlistStatus() async {
    if (!is_logged_in.$) return;
    try {
      final result = await _productRepository.getWishlistStatus(widget.id);
      if (result['success'] == true) {
        setState(() => _isWishlisted = result['isInWishlist'] ?? false);
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    if (_isWishlistLoading) return;

    final wasIn = _isWishlisted;
    setState(() {
      _isWishlistLoading = true;
      _isWishlisted = !wasIn;
    });

    try {
      if (wasIn) {
        await _productRepository.removeFromWishlist(widget.id);
      } else {
        await _productRepository.addToWishlist(widget.id);
      }
      if (mounted) {
        ToastComponent.showSuccess(
          wasIn
              ? AppLocalizations.of(context)!.removed_from_wishlist
              : AppLocalizations.of(context)!.added_to_wishlist,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isWishlisted = wasIn);
        ToastComponent.showError(
            AppLocalizations.of(context)!.wishlist_update_failed);
      }
    } finally {
      if (mounted) setState(() => _isWishlistLoading = false);
    }
  }

  void _determineAuctionStatus() {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (widget.auctionEndDate != null) {
      if (widget.auctionEndDate is String &&
          widget.auctionEndDate == "Upcoming") {
        _auctionStatus = "upcoming";
        _timeLeft = loc?.upcoming_ucf ?? "Upcoming";
        return;
      }
      if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
        _auctionStatus = "ended";
        _timeLeft = loc?.ended_ucf ?? "Ended";
        return;
      }
      if (widget.auctionEndDate is int) {
        final endDate = widget.auctionEndDate as int;
        if (endDate <= 0 || endDate <= now) {
          _auctionStatus = "ended";
          _timeLeft = loc?.ended_ucf ?? "Ended";
          return;
        }
        _auctionStatus = "active";
        return;
      }
      if (widget.auctionEndDate is String) {
        final endDate = int.tryParse(widget.auctionEndDate);
        if (endDate != null) {
          if (endDate <= 0 || endDate <= now) {
            _auctionStatus = "ended";
            _timeLeft = loc?.ended_ucf ?? "Ended";
            return;
          }
          _auctionStatus = "active";
          return;
        }
      }
    }

    if (widget.auctionStartDate != null) {
      if (widget.auctionStartDate is String &&
          widget.auctionStartDate == "Upcoming") {
        _auctionStatus = "upcoming";
        _timeLeft = loc?.upcoming_ucf ?? "Upcoming";
        return;
      }
      if (widget.auctionStartDate is int) {
        final startDate = widget.auctionStartDate as int;
        if (startDate > now) {
          _auctionStatus = "upcoming";
          _timeLeft = loc?.upcoming_ucf ?? "Upcoming";
          return;
        }
      }
      if (widget.auctionStartDate is String) {
        final startDate = int.tryParse(widget.auctionStartDate);
        if (startDate != null && startDate > now) {
          _auctionStatus = "upcoming";
          _timeLeft = loc?.upcoming_ucf ?? "Upcoming";
          return;
        }
      }
    }

    _auctionStatus = "active";
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    final loc = AppLocalizations.of(context);
    if (_auctionStatus != "active") return;

    if (widget.auctionEndDate == null) {
      if (mounted) {
        setState(() {
          _timeLeft = loc?.no_timer_ucf ?? "No Timer";
          _isTimerLoading = false;
        });
      }
      return;
    }

    if (widget.auctionEndDate is String) {
      if (widget.auctionEndDate == "Ended") {
        if (mounted) {
          setState(() {
            _timeLeft = loc?.ended_ucf ?? "Ended";
            _auctionStatus = "ended";
            _isTimerLoading = false;
          });
        }
        _timer?.cancel();
        return;
      }
      if (widget.auctionEndDate == "Upcoming") {
        if (mounted) {
          setState(() {
            _timeLeft = loc?.upcoming_ucf ?? "Upcoming";
            _auctionStatus = "upcoming";
            _isTimerLoading = false;
          });
        }
        _timer?.cancel();
        return;
      }
      final parsed = int.tryParse(widget.auctionEndDate);
      if (parsed == null) return;
      _handleCountdown(parsed);
      return;
    }

    if (widget.auctionEndDate is int) {
      _handleCountdown(widget.auctionEndDate);
    }
  }

  void _handleCountdown(int endDate) {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = endDate - now;

    if (distance < 0) {
      if (mounted) {
        setState(() {
          _timeLeft = loc?.ended_ucf ?? "Ended";
          _auctionStatus = "ended";
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

    final dSuffix = loc?.day_short_ucf ?? "d";
    final hSuffix = loc?.hour_short_ucf ?? "h";
    final mSuffix = loc?.minute_short_ucf ?? "m";
    final sSuffix = loc?.second_short_ucf ?? "s";

    String timeString;
    if (days > 0) {
      timeString = "$days$dSuffix $hours$hSuffix";
    } else if (hours > 0) {
      timeString = "$hours$hSuffix $minutes$mSuffix";
    } else if (minutes > 0) {
      timeString = "$minutes$mSuffix $seconds$sSuffix";
    } else {
      timeString = "$seconds$sSuffix";
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

  String _formatPrice(dynamic price) =>
      FormatHelper.formatPrice(_parsePrice(price));

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

  double _getRetailValue() => _parsePrice(widget.purchasePrice);

  void _navigateToProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(slug: widget.slug)),
    );
  }

  Future<void> _notifyMe() async {
    if (_isProcessing) return;
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final loc = AppLocalizations.of(context);
      final response = await _productRepository.notifyMeForAuction(widget.id);
      if (response['success'] == true) {
        ToastComponent.showSuccess(
          response['message'] ??
              (loc?.notify_me_success_ucf ??
                  'You will be notified when this auction starts!'),
        );
      } else {
        ToastComponent.showError(
          response['message'] ??
              (loc?.failed_to_set_notification_ucf ??
                  'Failed to set notification'),
        );
      }
    } catch (_) {
      final loc = AppLocalizations.of(context);
      ToastComponent.showError(
        loc?.error_setting_notification_ucf ?? 'Error setting notification',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _quickBid() async {
    if (_isProcessing) return;
    if (!is_logged_in.$) {
      _showLoginDialog(bidPrompt: true);
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final currentBid = _getDisplayBid();
      final minBid = currentBid + 0.01;
      final loc = AppLocalizations.of(context);

      final response = await _productRepository.quickBid(
        widget.id.toString(),
        minBid.toString(),
        type: 'quick',
      );

      if (response.success == true) {
        ToastComponent.showSuccess(
          '${loc?.quick_bid_placed_success_ucf ?? "Quick bid placed! Amount:"} ${_formatPrice(minBid)}',
        );
        if (!mounted) return;
        _navigateToProduct();
      } else {
        ToastComponent.showError(
          response.message ??
              (loc?.failed_to_place_bid_ucf ?? 'Failed to place bid'),
        );
      }
    } catch (_) {
      final loc = AppLocalizations.of(context);
      ToastComponent.showError(
          loc?.error_placing_bid_ucf ?? 'Error placing bid');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLoginDialog({bool bidPrompt = false}) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          loc?.login_required_ucf ?? 'Login Required',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          bidPrompt
              ? (loc?.please_login_to_place_bid_ucf ??
                  'Please login to place a bid')
              : (loc?.please_login_to_set_notification_ucf ??
                  'Please login to set notification'),
          style: TextStyle(fontSize: 12.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc?.cancel_ucf ?? 'Cancel',
              style: TextStyle(
                  fontSize: 12.sp, color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => Login()));
            },
            child: Text(
              loc?.login_ucf ?? 'Login',
              style:
                  TextStyle(fontSize: 12.sp, color: MyTheme.accent_color),
            ),
          ),
        ],
      ),
    );
  }

  void _onSlideStart(DragStartDetails d) {
    _thumbStartX = d.localPosition.dx;
    _isDragging = true;
  }

  void _onSlideUpdate(DragUpdateDetails d, double maxOffset) {
    if (!_isDragging) return;
    final dx = d.localPosition.dx - _thumbStartX;
    setState(() => _slideOffset = dx.clamp(0.0, maxOffset));
  }

  void _onSlideEnd(double maxOffset) {
    if (!_isDragging) return;
    _isDragging = false;
    final shouldBid = _slideOffset > maxOffset * 0.75;
    setState(() => _slideOffset = shouldBid ? maxOffset : 0);
    Future.delayed(Duration(milliseconds: shouldBid ? 200 : 300), () {
      if (mounted) setState(() => _slideOffset = 0);
    });
    if (shouldBid) _quickBid();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEnded = _auctionStatus == "ended";
    final isUpcoming = _auctionStatus == "upcoming";
    final retailValue = _getRetailValue();
    final displayBid = _getDisplayBid();
    final points = widget.pointPerBid ?? 1;

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121b4965),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      // ── MainAxisSize.max fills the IntrinsicHeight-stretched parent ──
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: _buildPhotoArea(loc),
          ),
          SizedBox(height: 7.h),
          GestureDetector(
            onTap: _navigateToProduct,
            child: Text(
              widget.name ?? loc.product_ucf,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF193a58),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.retail_value_ucf,
                style: TextStyle(
                    fontSize: 8.sp, color: const Color(0xFF71879d)),
              ),
              Text(
                _formatPrice(retailValue),
                style: TextStyle(
                    fontSize: 8.sp, color: const Color(0xFF71879d)),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          if (isEnded)
            _buildEndedPriceRow(displayBid)
          else if (isUpcoming)
            _buildUpcomingPriceRow(loc, points)
          else
            _buildActivePriceRow(displayBid, points),

          // ═══ FIX #4: expand remaining space, pin the CTA to the bottom ═══
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: _buildCta(loc),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedPriceRow(double displayBid) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _formatPrice(displayBid),
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0d806f),
          letterSpacing: -0.3,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildUpcomingPriceRow(AppLocalizations loc, int points) {
    final unit = points == 1 ? loc.point_singular_ucf : loc.points_plural_ucf;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            loc.starting_soon_ucf,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF28bfa8),
              letterSpacing: -0.3,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 3.w),
        Flexible(
          child: Text(
            '◉ $points $unit ${loc.per_bid_ucf}',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF177f81),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePriceRow(double displayBid, int points) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            _formatPrice(displayBid),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00a98d),
              letterSpacing: -0.3,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 3.w),
        Flexible(
          child: Text(
            '◉ $points ${loc.point_per_bid_ucf}',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF177f81),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCta(AppLocalizations loc) {
    switch (_auctionStatus) {
      case "ended":
        return _buildViewProductButton(loc);
      case "upcoming":
        return _buildNotifyButton(loc);
      default:
        return _buildSlideToBid(loc);
    }
  }

  Widget _buildViewProductButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _navigateToProduct,
      child: Container(
        width: double.infinity,
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFe8f8f4),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          loc.view_product_ucf,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0c7b73),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNotifyButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _isProcessing ? null : _notifyMe,
      child: Container(
        width: double.infinity,
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFeffffb), Color(0xFFddf8f2)],
          ),
          border: Border.all(color: const Color(0xFF41c7b5), width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: _isProcessing
            ? SizedBox(
                width: 14.w,
                height: 14.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF075f5d),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '♧',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: const Color(0xFF075f5d),
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      loc.notify_me_when_starts_ucf,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF075f5d),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSlideToBid(AppLocalizations loc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = (constraints.maxWidth - _thumbSize - 6).clamp(
          0.0,
          double.infinity,
        );

        return GestureDetector(
          onHorizontalDragStart: _onSlideStart,
          onHorizontalDragUpdate: (d) => _onSlideUpdate(d, maxOffset),
          onHorizontalDragEnd: (_) => _onSlideEnd(maxOffset),
          child: Container(
            height: 36.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.9, 0),
                end: Alignment(0.9, 0),
                colors: [Color(0xFF0dbca9), Color(0xFF2086d8)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x55FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x351597ba),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _isProcessing
                ? Center(
                    child: SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        left: 4.w + _slideOffset,
                        top: 4.h,
                        bottom: 4.h,
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x70063e62),
                                blurRadius: 7,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 16.sp,
                            color: const Color(0xFF078c9f),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            _slideOffset > 20
                                ? loc.quick_bid_ucf
                                : loc.swipe_to_bid_ucf,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.01,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8.w,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '››',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: const Color(0xB3E5FFFF),
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoArea(AppLocalizations loc) {
    final isEnded = _auctionStatus == "ended";
    final isUpcoming = _auctionStatus == "upcoming";

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _navigateToProduct,
            child: Container(
              color: const Color(0xFFf5fafd),
              child: widget.image != null && widget.image!.isNotEmpty
                  ? Image.network(
                      widget.image!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image,
                        size: 24.sp,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(Icons.image, size: 24.sp, color: Colors.grey),
            ),
          ),
          Positioned(
            top: 6.h,
            left: 6.w,
            child: _buildStatusBadge(loc, isEnded, isUpcoming),
          ),
          Positioned(
            top: 6.h,
            right: 6.w,
            child: GestureDetector(
              onTap: _toggleWishlist,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.93),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x18153550), blurRadius: 8),
                  ],
                ),
                child: _isWishlistLoading
                    ? Padding(
                        padding: EdgeInsets.all(4.w),
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFFf06979),
                        ),
                      )
                    : Icon(
                        _isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 12.sp,
                        color: _isWishlisted
                            ? const Color(0xFFf06979)
                            : const Color(0xFF6b8499),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
      AppLocalizations loc, bool isEnded, bool isUpcoming) {
    // ═══ FIX #2: hardcoded uppercase to match HTML exactly ═══
    if (isEnded) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: const Color(0xFFe8f1f8),
          border: Border.all(color: const Color(0xFFbbd1e3), width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          'COMPLETED',
          style: TextStyle(
            fontSize: 7.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            color: const Color(0xFF3b5a75),
          ),
        ),
      );
    }
    if (isUpcoming) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: const Color(0xFFe5f9f6),
          border: Border.all(color: const Color(0xFF72d8cb), width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          'COMING SOON',
          style: TextStyle(
            fontSize: 7.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            color: const Color(0xFF087b76),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFff8d75), Color(0xFFffbd82)],
        ),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time,
              size: 8.sp, color: const Color(0xFF573024)),
          SizedBox(width: 2.w),
          Text(
            _isTimerLoading ? '' : _timeLeft,
            style: TextStyle(
              fontSize: 7.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF573024),
            ),
          ),
        ],
      ),
    );
  }
}