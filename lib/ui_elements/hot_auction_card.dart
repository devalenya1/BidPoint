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

class HotAuctionCard extends StatefulWidget {
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
  final dynamic purchasePrice;

  const HotAuctionCard({
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
    this.purchasePrice,
  }) : super(key: key);

  @override
  State<HotAuctionCard> createState() => _HotAuctionCardState();
}

class _HotAuctionCardState extends State<HotAuctionCard> {
  Timer? _timer;
  String _timeLeft = "";
  bool _isTimerLoading = true;
  bool _isProcessing = false;
  bool _isWishlisted = false;
  bool _isWishlistLoading = false;

  double _slideOffset = 0;
  double _thumbStartX = 0;
  bool _isDragging = false;
  static const double _thumbSize = 30;

  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  void _startTimer() {
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    final loc = AppLocalizations.of(context);
    if (widget.auctionEndDate == null) {
      if (mounted) {
        setState(() {
          _timeLeft = loc?.no_timer_ucf ?? "No Timer";
          _isTimerLoading = false;
        });
      }
      return;
    }
    if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
      if (mounted) {
        setState(() {
          _timeLeft = loc?.ended_ucf ?? "Ended";
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
          _timeLeft = loc?.ended_ucf ?? "Ended";
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
          _timeLeft = loc?.ended_ucf ?? "Ended";
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

  double _getRetailValue() {
    if (widget.purchasePrice != null) {
      final parsed = _parsePrice(widget.purchasePrice);
      if (parsed > 0) return parsed;
    }
    return _getDisplayBid() * 100;
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

  Future<void> _quickBid() async {
    if (_isProcessing) return;
    if (!is_logged_in.$) {
      _showLoginDialog();
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetails(slug: widget.slug)),
        );
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

  void _navigateToProductDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(slug: widget.slug)),
    );
  }

  void _showLoginDialog() {
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
          loc?.please_login_to_place_bid_ucf ?? 'Please login to place a bid',
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

  // ═══════════════════════════════════════════════════════════
  // BUILD — matches HTML .bp-hot-card dimensions
  //   photo 42% | info 58%
  //   padding 9 (was 16 in HTML, but user requested 9 everywhere)
  //   border-radius 17 (kept from HTML)
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 700;
        final isVeryNarrow = constraints.maxWidth < 260;

        // On mobile, stacked (photo on top). On desktop, side by side.
        if (isMobile || isVeryNarrow) {
          return _buildMobileCard();
        }
        return _buildDesktopCard();
      },
    );
  }

  Widget _buildDesktopCard() {
    final loc = AppLocalizations.of(context)!;
    final displayBid = _getDisplayBid();
    final retailValue = _getRetailValue();
    final points = widget.pointPerBid ?? 0;
    final endedText = loc.ended_ucf;
    final noTimerText = loc.no_timer_ucf;
    final showTimer = !_isTimerLoading &&
        _timeLeft != endedText &&
        _timeLeft != noTimerText;

    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(17.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121b4965),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 42, child: _buildPhotoArea(showTimer)),
            SizedBox(width: 9.w),
            Expanded(
              flex: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _navigateToProductDetails,
                    child: Text(
                      widget.name ?? loc.product_ucf,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF193a58),
                        height: 1.2,
                      ),
                      maxLines: 1,
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
                            fontSize: 9.sp,
                            color: const Color(0xFF71879d)),
                      ),
                      Text(
                        _formatPrice(retailValue),
                        style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF71879d)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(displayBid),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00a98d),
                            letterSpacing: -0.4,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          '◉ $points ${loc.point_per_bid_ucf}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF177f81),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  _buildProgressBar(),
                  SizedBox(height: 7.h),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildSlideToBid(loc),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard() {
    final loc = AppLocalizations.of(context)!;
    final displayBid = _getDisplayBid();
    final retailValue = _getRetailValue();
    final points = widget.pointPerBid ?? 0;
    final endedText = loc.ended_ucf;
    final noTimerText = loc.no_timer_ucf;
    final showTimer = !_isTimerLoading &&
        _timeLeft != endedText &&
        _timeLeft != noTimerText;

    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(17.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121b4965),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 128.h, child: _buildPhotoArea(showTimer)),
          SizedBox(height: 9.h),
          GestureDetector(
            onTap: _navigateToProductDetails,
            child: Text(
              widget.name ?? loc.product_ucf,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF193a58),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.retail_value_ucf,
                style: TextStyle(
                    fontSize: 10.sp, color: const Color(0xFF71879d)),
              ),
              Text(
                _formatPrice(retailValue),
                style: TextStyle(
                    fontSize: 10.sp, color: const Color(0xFF71879d)),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _formatPrice(displayBid),
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00a98d),
                    letterSpacing: -0.4,
                    height: 1,
                  ),
                ),
              ),
              Text(
                '◉ $points ${loc.point_per_bid_ucf}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF177f81),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _buildProgressBar(),
          SizedBox(height: 8.h),
          _buildSlideToBid(loc),
        ],
      ),
    );
  }

  Widget _buildPhotoArea(bool showTimer) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _navigateToProductDetails,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFe9f3fa), Color(0xFFf6fbff)],
                ),
              ),
              child: widget.image != null && widget.image!.isNotEmpty
                  ? Image.network(
                      widget.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image,
                        size: 28.sp,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(Icons.image, size: 28.sp, color: Colors.grey),
            ),
          ),
          if (showTimer)
            Positioned(
              top: 9.h,
              left: 9.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff8d75), Color(0xFFffbd82)],
                  ),
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time,
                        size: 10.sp, color: const Color(0xFF573024)),
                    SizedBox(width: 3.w),
                    Text(
                      _timeLeft,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF573024),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 9.h,
            right: 9.w,
            child: GestureDetector(
              onTap: _toggleWishlist,
              child: Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.93),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x18153550), blurRadius: 10),
                  ],
                ),
                child: _isWishlistLoading
                    ? Padding(
                        padding: EdgeInsets.all(5.w),
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFFf06979),
                        ),
                      )
                    : Icon(
                        _isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14.sp,
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

  Widget _buildProgressBar() {
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: const Color(0xFFe8f0f6),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.2,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF18c6b1), Color(0xFF48aee4)],
            ),
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToBid(AppLocalizations loc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = (constraints.maxWidth - _thumbSize - 8).clamp(
          0.0,
          double.infinity,
        );

        return GestureDetector(
          onHorizontalDragStart: _onSlideStart,
          onHorizontalDragUpdate: (d) => _onSlideUpdate(d, maxOffset),
          onHorizontalDragEnd: (_) => _onSlideEnd(maxOffset),
          child: Container(
            height: 40.h,
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
                  blurRadius: 14,
                  offset: Offset(0, 5),
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
                                blurRadius: 9,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 18.sp,
                            color: const Color(0xFF078c9f),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22.w),
                          child: Text(
                            _slideOffset > 20
                                ? loc.quick_bid_ucf
                                : loc.swipe_to_bid_ucf,
                            style: TextStyle(
                              fontSize: 10.sp,
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
                        right: 10.w,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '››',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
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
}