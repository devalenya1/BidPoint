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

  /// Matches HTML `$retail_value = $product->purchase_price ?? 0;`
  final dynamic purchasePrice;

  // Kept for backward compatibility — not rendered by this card.
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
  String _auctionStatus = "active"; // "upcoming" | "active" | "ended"
  bool _isProcessing = false;

  // Slide-to-bid state (only for active)
  double _slideOffset = 0;
  double _thumbStartX = 0;
  bool _isDragging = false;
  static const double _thumbSize = 41;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // STATUS / TIMER
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // PRICE HELPERS
  // ─────────────────────────────────────────────────────────────
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
    return FormatHelper.formatPrice(_parsePrice(price));
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

  double _getRetailValue() => _parsePrice(widget.purchasePrice);

  // ─────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────
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
        loc?.error_placing_bid_ucf ?? 'Error placing bid',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLoginDialog({bool bidPrompt = false}) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          loc?.login_required_ucf ?? 'Login Required',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          bidPrompt
              ? (loc?.please_login_to_place_bid_ucf ??
                  'Please login to place a bid')
              : (loc?.please_login_to_set_notification_ucf ??
                  'Please login to set notification'),
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc?.cancel_ucf ?? 'Cancel',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            child: Text(
              loc?.login_ucf ?? 'Login',
              style: TextStyle(fontSize: 14.sp, color: MyTheme.accent_color),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SLIDE HELPERS
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        return isNarrow ? _buildStackedCard() : _buildDesktopCard();
      },
    );
  }

  Widget _buildDesktopCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(19.r),
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
            Expanded(flex: 42, child: _buildPhotoArea(loc)),
            SizedBox(width: 18.w),
            Expanded(flex: 58, child: _buildInfoColumn(loc, isDesktop: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(19.r),
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
          SizedBox(height: 185.h, child: _buildPhotoArea(loc)),
          SizedBox(height: 12.h),
          _buildInfoColumn(loc, isDesktop: false),
        ],
      ),
    );
  }

  // ── INFO COLUMN (name / retail / price / CTA) ────────────────
  Widget _buildInfoColumn(AppLocalizations loc, {required bool isDesktop}) {
    final isEnded = _auctionStatus == "ended";
    final isUpcoming = _auctionStatus == "upcoming";
    final retailValue = _getRetailValue();
    final displayBid = _getDisplayBid();
    final points = widget.pointPerBid ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _navigateToProduct,
          child: Text(
            widget.name ?? loc.product_ucf,
            style: TextStyle(
              fontSize: isDesktop ? 15.sp : 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF193a58),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 6.h),

        // Retail value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.retail_value_ucf,
              style: TextStyle(
                  fontSize: isDesktop ? 11.sp : 10.sp,
                  color: const Color(0xFF71879d)),
            ),
            Text(
              _formatPrice(retailValue),
              style: TextStyle(
                  fontSize: isDesktop ? 11.sp : 10.sp,
                  color: const Color(0xFF71879d)),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Price row
        if (isEnded)
          _buildEndedPriceRow(displayBid, isDesktop)
        else if (isUpcoming)
          _buildUpcomingPriceRow(loc, points, isDesktop)
        else
          _buildActivePriceRow(displayBid, points, isDesktop),

        SizedBox(height: 10.h),

        if (isDesktop)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildCta(loc),
            ),
          )
        else
          _buildCta(loc),
      ],
    );
  }

  // Price row variants
  Widget _buildEndedPriceRow(double displayBid, bool isDesktop) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _formatPrice(displayBid),
        style: TextStyle(
          fontSize: isDesktop ? 25.sp : 22.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0d806f),
          letterSpacing: -0.04,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildUpcomingPriceRow(
      AppLocalizations loc, int points, bool isDesktop) {
    final unit = points == 1 ? loc.point_singular_ucf : loc.points_plural_ucf;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            loc.starting_soon_ucf,
            style: TextStyle(
              fontSize: isDesktop ? 19.sp : 17.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF28bfa8),
              letterSpacing: -0.04,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            '◉ $points $unit ${loc.per_bid_ucf}',
            style: TextStyle(
              fontSize: isDesktop ? 11.sp : 10.sp,
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

  Widget _buildActivePriceRow(double displayBid, int points, bool isDesktop) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            _formatPrice(displayBid),
            style: TextStyle(
              fontSize: isDesktop ? 25.sp : 22.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00a98d),
              letterSpacing: -0.04,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            '◉ $points ${loc.point_per_bid_ucf}',
            style: TextStyle(
              fontSize: isDesktop ? 11.sp : 10.sp,
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

  // ── CTA / BUTTON (varies by state) ───────────────────────────
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
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 13.w),
        decoration: BoxDecoration(
          color: const Color(0xFFe8f8f4),
          borderRadius: BorderRadius.circular(11.r),
        ),
        alignment: Alignment.center,
        child: Text(
          loc.view_product_ucf,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0c7b73),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifyButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _isProcessing ? null : _notifyMe,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 43.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFeffffb), Color(0xFFddf8f2)],
          ),
          border: Border.all(color: const Color(0xFF41c7b5), width: 1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: _isProcessing
            ? SizedBox(
                width: 18.w,
                height: 18.w,
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
                      fontSize: 12.sp,
                      color: const Color(0xFF075f5d),
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      loc.notify_me_when_starts_ucf,
                      style: TextStyle(
                        fontSize: 12.sp,
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
        final maxOffset = (constraints.maxWidth - _thumbSize - 8).clamp(
          0.0,
          double.infinity,
        );

        return GestureDetector(
          onHorizontalDragStart: _onSlideStart,
          onHorizontalDragUpdate: (d) => _onSlideUpdate(d, maxOffset),
          onHorizontalDragEnd: (_) => _onSlideEnd(maxOffset),
          child: Container(
            height: 49.h,
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
                      width: 20.w,
                      height: 20.w,
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
                          width: _thumbSize - 8,
                          height: _thumbSize - 8,
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
                            size: 22.sp,
                            color: const Color(0xFF078c9f),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: Text(
                            _slideOffset > 20
                                ? loc.quick_bid_ucf
                                : loc.swipe_to_bid_ucf,
                            style: TextStyle(
                              fontSize: 12.sp,
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
                        right: 14.w,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '››',
                            style: TextStyle(
                              fontSize: 14.sp,
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

  // ── PHOTO + BADGE + HEART ────────────────────────────────────
  Widget _buildPhotoArea(AppLocalizations loc) {
    final isEnded = _auctionStatus == "ended";
    final isUpcoming = _auctionStatus == "upcoming";

    return ClipRRect(
      borderRadius: BorderRadius.circular(11.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _navigateToProduct,
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
                        size: 40.sp,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(Icons.image, size: 40.sp, color: Colors.grey),
            ),
          ),

          // Badge — top-left
          if (isEnded)
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFe8f1f8),
                  border: Border.all(color: const Color(0xFFbbd1e3), width: 1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  loc.completed_ucf,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: const Color(0xFF3b5a75),
                  ),
                ),
              ),
            )
          else if (isUpcoming)
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFe5f9f6),
                  border: Border.all(color: const Color(0xFF72d8cb), width: 1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  loc.coming_soon_ucf,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: const Color(0xFF087b76),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
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
                        size: 12.sp, color: const Color(0xFF573024)),
                    SizedBox(width: 3.w),
                    Text(
                      _isTimerLoading ? '' : _timeLeft,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF573024),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Heart — top-right
          Positioned(
            top: 12.h,
            right: 12.w,
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x18153550), blurRadius: 12),
                ],
              ),
              child: Icon(
                Icons.favorite_border,
                size: 16.sp,
                color: const Color(0xFF6b8499),
              ),
            ),
          ),
        ],
      ),
    );
  }
}