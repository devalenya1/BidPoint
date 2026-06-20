import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ProductCard extends StatefulWidget {
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
  bool _isProcessing = false;
  
  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    // Fixed: Always start timer if auctionEndDate exists, regardless of isAuctionActive
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

    // Handle "Ended" string case
    if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
        });
      }
      _timer?.cancel();
      return;
    }

    // Handle "Upcoming" string case
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

    // Check if endDate is valid (greater than 0)
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

  // ============ PRICE HELPERS (Same pattern as Product model) ============
  
  /// Parse a price string to double (handles both "10.24" and "$10.24")
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // Remove any currency symbols or non-numeric characters except dot
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Format price with currency symbol
  String _formatPrice(dynamic price) {
    final doubleValue = _parsePrice(price);
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${doubleValue.toStringAsFixed(2)}';
  }

  /// Get the display bid value as double
  double _getDisplayBid() {
    // Try highest bid first, then starting bid
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

  @override
  Widget build(BuildContext context) {
    final displayBid = _getDisplayBid();
    // Fixed: Show timer for all statuses except "No Timer"
    // Show "Upcoming" in orange, "Ended" in red, timer in green
    final showTimer = _timeLeft != "No Timer";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Fixed: Changed to white like other cards
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: widget.image != null && widget.image!.isNotEmpty
                        ? Image.network(
                            widget.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              // Fixed: Timer shows for all statuses with appropriate colors
              if (showTimer)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _timeLeft == "Ended" 
                          ? Colors.red 
                          : (_timeLeft == "Upcoming" 
                              ? Colors.orange 
                              : const Color(0xFF009572)),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
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
                              : (_timeLeft == "Upcoming"
                                  ? Icons.schedule
                                  : Icons.access_time),
                          size: 10, 
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timeLeft,
                          style: const TextStyle(
                            fontSize: 9,
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name - Larger
                GestureDetector(
                  onTap: _navigateToProduct,
                  child: Text(
                    widget.name ?? 'Product',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                
                // Description - Below title
                GestureDetector(
                  onTap: _navigateToProduct,
                  child: Text(
                    widget.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8F9AA7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Current Bid and Points Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Current Bid - Larger
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _timeLeft == "Upcoming" ? 'Starting Bid' : 'Current Bid',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF80818B),
                          ),
                        ),
                        Text(
                          _formatPrice(displayBid),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    // Points Badge with USD icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E7F5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Color(0xFF0092AC),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '1 Bid = ${widget.pointPerBid ?? 0}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: MyTheme.accent_color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // View Product Button - Rectangle with border-radius 7px
                GestureDetector(
                  onTap: _navigateToProduct,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _timeLeft == "Upcoming" ? 'View Product' : 'View Product',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 12,
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