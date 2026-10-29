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

  /// Matches HTML `$retail_value = $product->purchase_price ?? 0;`
  final dynamic purchasePrice;

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
    this.purchasePrice,
  }) : super(key: key);

  @override
  State<UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<UpcomingCard> {
  bool _isProcessing = false;
  bool _isWishlisted = false;
  bool _isWishlistLoading = false;

  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _fetchWishlistStatus();
  }

  // ─────────────────────────────────────────────────────────────
  // WISHLIST — same flow as product_details.dart
  // ─────────────────────────────────────────────────────────────
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

  String _formatPrice(dynamic price) =>
      FormatHelper.formatPrice(_parsePrice(price));

  double _getStartingBid() {
    if (widget.startingBid != null) {
      final parsed = _parsePrice(widget.startingBid);
      if (parsed > 0) return parsed;
    }
    if (widget.currentBid != null) {
      final parsed = _parsePrice(widget.currentBid);
      if (parsed > 0) return parsed;
    }
    return 0.0;
  }

  double _getRetailValue() => _parsePrice(widget.purchasePrice);

  // ─────────────────────────────────────────────────────────────
  // NOTIFY ME
  // ─────────────────────────────────────────────────────────────
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
          loc?.please_login_to_set_notification_ucf ??
              'Please login to set notification',
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

  // ── DESKTOP: photo 42% | info 58% ─────────────────────────────
  Widget _buildDesktopCard() {
    final loc = AppLocalizations.of(context)!;
    final retailValue = _getRetailValue();
    final points = widget.pointPerBid ?? 1;

    return Container(
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121b4965),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 42, child: _buildPhotoArea(loc)),
            SizedBox(width: 11.w),
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
                          loc.starting_soon_ucf,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF28bfa8),
                            letterSpacing: -0.04,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          _pointsLabel(loc, points),
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
                  SizedBox(height: 8.h),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildNotifyButton(loc),
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

  // ── STACKED: photo on top ─────────────────────────────────────
  Widget _buildStackedCard() {
    final loc = AppLocalizations.of(context)!;
    final retailValue = _getRetailValue();
    final points = widget.pointPerBid ?? 1;

    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121b4965),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 130.h, child: _buildPhotoArea(loc)),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _navigateToProductDetails,
            child: Text(
              widget.name ?? loc.product_ucf,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF193a58),
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
                    fontSize: 8.sp, color: const Color(0xFF71879d)),
              ),
              Text(
                _formatPrice(retailValue),
                style: TextStyle(
                    fontSize: 8.sp, color: const Color(0xFF71879d)),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  loc.starting_soon_ucf,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF28bfa8),
                    letterSpacing: -0.04,
                    height: 1,
                  ),
                ),
              ),
              Text(
                _pointsLabel(loc, points),
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF177f81),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _buildNotifyButton(loc),
        ],
      ),
    );
  }

  String _pointsLabel(AppLocalizations loc, int points) {
    final unit = points == 1 ? loc.point_singular_ucf : loc.points_plural_ucf;
    return '◉ $points $unit ${loc.per_bid_ucf}';
  }

  // ── PHOTO (image + COMING SOON badge + heart) ────────────────
  Widget _buildPhotoArea(AppLocalizations loc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9.r),
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

          // COMING SOON badge (top-left)
          Positioned(
            top: 6.h,
            left: 6.w,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFe5f9f6),
                border: Border.all(color: const Color(0xFF72d8cb), width: 1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                loc.coming_soon_ucf,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: const Color(0xFF087b76),
                ),
              ),
            ),
          ),

          // Heart (top-right) — real wishlist toggle
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
                    BoxShadow(color: Color(0x18153550), blurRadius: 10),
                  ],
                ),
                child: _isWishlistLoading
                    ? Padding(
                        padding: EdgeInsets.all(5.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: const Color(0xFFf06979),
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

  // ── NOTIFY ME BUTTON (matches .bp-upcoming-remind-btn) ────────
  Widget _buildNotifyButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _isProcessing ? null : _notifyMe,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 32.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFeffffb), Color(0xFFddf8f2)],
          ),
          border: Border.all(color: const Color(0xFF41c7b5), width: 1),
          borderRadius: BorderRadius.circular(10.r),
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
                      fontSize: 10.sp,
                      color: const Color(0xFF075f5d),
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 5.w),
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
}