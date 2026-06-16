import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/auction_products_details.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/auction_products_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

class ProductCard extends StatefulWidget {
  final int id;
  final String slug;
  final String? image;
  final String? name;
  final String? description;
  final int? pointPerBid;
  final dynamic auctionEndDate;
  final double? currentBid;
  final double? startingBid;
  final bool isAuctionActive;

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
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
  bool _isSwiping = false;
  double _swipeAmount = 0;
  double _startX = 0;
  double _startY = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAuctionActive && widget.auctionEndDate != null) {
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
    if (widget.auctionEndDate == null) return;

    int endDate;
    if (widget.auctionEndDate is int) {
      endDate = widget.auctionEndDate;
    } else if (widget.auctionEndDate is String) {
      endDate = int.tryParse(widget.auctionEndDate) ?? 0;
    } else {
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

  String _formatPrice(double? price) {
    if (price == null) return '\$0.00';
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
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
      final currentBid = widget.currentBid ?? widget.startingBid ?? 0;
      final minBid = currentBid + 0.01;
      
      final response = await AuctionProductsRepository().quickBid(
        widget.id.toString(),
        minBid.toString(),
        type: 'quick',
      );
      
      if (response.success == true) {
        ToastComponent.showDialog(
          'Quick bid placed! Amount: ${_formatPrice(minBid)}',
        );
        GoRouter.of(context).go('/auction-product/${widget.slug}');
      } else {
        ToastComponent.showDialog(
          response.message ?? 'Failed to place bid',
        );
      }
    } catch (e) {
      ToastComponent.showDialog('Error placing bid');
    } finally {
      _isProcessing = false;
      setState(() {});
    }
  }
  
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to place a bid'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
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
    
    if (deltaX > 5 && deltaY.abs() < 30) {
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

  @override
  Widget build(BuildContext context) {
    final displayBid = widget.currentBid ?? widget.startingBid ?? 0;
    final showTimer = widget.isAuctionActive && _timeLeft != "Ended";

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F3),
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
                  onTap: () {
                    GoRouter.of(context).go('/auction-product/${widget.slug}');
                  },
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
                if (showTimer)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009572),
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
                          const Icon(Icons.access_time, size: 10, color: Colors.white),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  GestureDetector(
                    onTap: () {
                      GoRouter.of(context).go('/auction-product/${widget.slug}');
                    },
                    child: Text(
                      widget.name ?? 'Product',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Description
                  Text(
                    widget.description ?? '',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8F9AA7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Current Bid and Points Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current Bid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'current Bid',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF80818B),
                            ),
                          ),
                          Text(
                            _formatPrice(displayBid),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Points Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '1 Bid = ${widget.pointPerBid ?? 0}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Swipe to Bid Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: MyTheme.accent_color, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          width: 28 + (_swipeAmount),
                          height: 35,
                          decoration: BoxDecoration(
                            color: _swipeAmount > 20 ? Colors.green : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: _swipeAmount > 20 ? Colors.white : const Color(0xFF009572),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_swipeAmount < 20) ...[
                              const SizedBox(width: 30),
                              const Text(
                                'Swipe to Bid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF009572),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 10, color: Color(0xFF009572)),
                            ] else ...[
                              const Text(
                                'Quick Bid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}