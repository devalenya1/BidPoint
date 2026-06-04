import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class HotAuctionsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final String title;
  final VoidCallback? onViewAll;

  const HotAuctionsCarousel({
    Key? key,
    required this.products,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<HotAuctionsCarousel> createState() => _HotAuctionsCarouselState();
}

class _HotAuctionsCarouselState extends State<HotAuctionsCarousel> {
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  final Map<int, double> _swipeOffsets = {};
  final Map<int, bool> _showQuickBid = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.products.length; i++) {
      final product = widget.products[i];
      if (!product['isAuctionEnded']) {
        _startTimer(i, product['endDate']);
      }
      _swipeOffsets[i] = 0.0;
      _showQuickBid[i] = false;
    }
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _startTimer(int index, DateTime endDate) {
    _updateTimeLeft(index, endDate);
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft(index, endDate);
    });
    _timers[index] = timer;
  }

  void _updateTimeLeft(int index, DateTime endDate) {
    final now = DateTime.now();
    final distance = endDate.difference(now);

    if (distance.isNegative) {
      if (mounted) {
        setState(() {
          _timeLeft[index] = "Ended";
        });
      }
      _timers[index]?.cancel();
      return;
    }

    final days = distance.inDays;
    final hours = distance.inHours % 24;
    final minutes = distance.inMinutes % 60;
    final seconds = distance.inSeconds % 60;

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
        _timeLeft[index] = timeString;
      });
    }
  }

  void _handleSwipeStart(int index) {
    setState(() {
      _swipeOffsets[index] = 0.0;
      _showQuickBid[index] = false;
    });
  }

  void _handleSwipeUpdate(int index, double delta) {
    setState(() {
      // Only allow right swipe (positive delta)
      if (delta > 0) {
        _swipeOffsets[index] = delta.clamp(0.0, 60.0);
        _showQuickBid[index] = _swipeOffsets[index] > 20;
      }
    });
  }

  void _handleSwipeEnd(int index, double delta, Map<String, dynamic> product) {
    setState(() {
      if (delta >= 40) {
        // Quick bid triggered
        _showQuickBidToast(product);
      }
      _swipeOffsets[index] = 0.0;
      _showQuickBid[index] = false;
    });
  }

  void _showQuickBidToast(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick bid placed on ${product['name']}!'),
        backgroundColor: const Color(0xFF009572),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 6; // Desktop: 6 items
    } else if (width > 768) {
      return 4; // Tablet: 4 items
    } else {
      return 2; // Mobile: 2 items
    }
  }

  double _getAspectRatio() {
    // Card height ~280, card width based on screen
    return 0.65;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              // View All Button
              if (widget.onViewAll != null)
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF2F2F3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'View All',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF80818B),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Grid View - Responsive columns
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _getAspectRatio(),
          ),
          itemCount: widget.products.length,
          itemBuilder: (context, index) {
            final product = widget.products[index];
            final isEnded = _timeLeft[index] == "Ended";
            final timeLeft = _timeLeft[index] ?? "Loading...";
            final swipeOffset = _swipeOffsets[index] ?? 0.0;
            final showQuickBid = _showQuickBid[index] ?? false;

            return _buildAuctionCard(
              product: product,
              index: index,
              timeLeft: timeLeft,
              isEnded: isEnded,
              swipeOffset: swipeOffset,
              showQuickBid: showQuickBid,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuctionCard({
    required Map<String, dynamic> product,
    required int index,
    required String timeLeft,
    required bool isEnded,
    required double swipeOffset,
    required bool showQuickBid,
  }) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _handleSwipeStart(index),
      onHorizontalDragUpdate: (details) => _handleSwipeUpdate(index, details.delta.dx),
      onHorizontalDragEnd: (details) => _handleSwipeEnd(index, details.primaryVelocity ?? 0, product),
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
            // Product Image Section (1:1 aspect ratio)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: const Color(0xFFE2E8F0),
                      child: product['image'] != null
                          ? Image.network(
                              product['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Color(0xFF94A3B8),
                                );
                              },
                            )
                          : const Icon(
                              Icons.inventory_2,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                    ),
                  ),
                ),
                // Timer Badge - Top Right
                if (!isEnded)
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
                          const Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeLeft,
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
                // Ended Badge
                if (isEnded)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC3545),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Ended",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name (truncated to 20 chars)
                  Text(
                    product['name'].length > 20 
                        ? '${product['name'].substring(0, 20)}...' 
                        : product['name'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description (truncated to 35 chars)
                  Text(
                    product['description'].length > 35
                        ? '${product['description'].substring(0, 35)}...'
                        : product['description'],
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8F9AA7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Current Bid and Bid Increment Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current Bid Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'current Bid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF80818B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(product['currentBid']),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Bid Increment Badge
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
                              size: 9,
                              color: Color(0xFF0092AC),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "1 Bid = ${product['pointsPerBid']}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0092AC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Swipe to Bid Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    transform: Matrix4.translationValues(swipeOffset, 0, 0),
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Stack(
                        children: [
                          // White box icon (left side)
                          Positioned(
                            left: 4,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              width: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFF0092AC),
                                ),
                              ),
                            ),
                          ),
                          // Center text that fades on swipe
                          Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 100),
                              opacity: showQuickBid ? 0 : 1,
                              child: const Text(
                                "Swipe to Bid",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Quick bid text that appears on swipe
                          if (showQuickBid)
                            Positioned(
                              right: 15,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Row(
                                  children: const [
                                    Text(
                                      "Quick Bid",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 10,
                                      color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }
}