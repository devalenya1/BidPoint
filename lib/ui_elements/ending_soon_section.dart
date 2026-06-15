import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/auction_products_details.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class EndingSoonSection extends StatefulWidget {
  final List<dynamic> products;
  final String title;
  final String viewAllRoute;

  const EndingSoonSection({
    Key? key,
    required this.products,
    required this.title,
    required this.viewAllRoute,
  }) : super(key: key);

  @override
  State<EndingSoonSection> createState() => _EndingSoonSectionState();
}

class _EndingSoonSectionState extends State<EndingSoonSection> {
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};

  @override
  void initState() {
    super.initState();
    _initializeTimers();
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _initializeTimers() {
    for (var product in widget.products) {
      final endDate = product.auctionEndDate;
      if (endDate != null && endDate is int && endDate > 0) {
        _startTimer(product.id, endDate);
      }
    }
  }

  void _startTimer(int id, int endDate) {
    _updateTimeLeft(id, endDate);
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft(id, endDate);
    });
    _timers[id] = timer;
  }

  void _updateTimeLeft(int id, int endDate) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = endDate - now;

    if (distance < 0) {
      if (mounted) {
        setState(() {
          _timeLeft[id] = "Ended";
        });
      }
      _timers[id]?.cancel();
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
        _timeLeft[id] = timeString;
      });
    }
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return '\$0.00';
    if (SystemConfig.systemCurrency != null) {
      return price.replaceAll(
        SystemConfig.systemCurrency!.code ?? '',
        SystemConfig.systemCurrency!.symbol ?? '\$',
      );
    }
    return price;
  }

  String _getProductName(String? name) {
    if (name == null) return '';
    if (name.length > 30) {
      return '${name.substring(0, 27)}...';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split products into grids of 3
    final List<List<dynamic>> grids = [];
    for (int i = 0; i < widget.products.length; i += 3) {
      final end = (i + 3 < widget.products.length) ? i + 3 : widget.products.length;
      grids.add(widget.products.sublist(i, end));
    }

    // Only show first 2 grids on desktop, first grid on mobile
    final desktopGrids = grids.length > 2 ? grids.sublist(0, 2) : grids;
    final mobileGrid = grids.isNotEmpty ? grids[0] : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to view all
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF2F2F3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF80818B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Desktop View (2 grids side by side)
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 768) {
              return _buildDesktopView(desktopGrids);
            } else {
              return _buildMobileView(mobileGrid);
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDesktopView(List<List<dynamic>> grids) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grids.asMap().entries.map((entry) {
          final gridIndex = entry.key;
          final gridProducts = entry.value;
          
          final leftProducts = gridProducts.length >= 2 
              ? gridProducts.sublist(0, 2) 
              : gridProducts;
          final rightProduct = gridProducts.length >= 3 ? gridProducts[2] : null;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: gridIndex == 0 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - 2 Products Stacked
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: leftProducts.asMap().entries.map((leftEntry) {
                        final product = leftEntry.value;
                        return _buildLeftCard(product);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Right Column - 1 Product
                  if (rightProduct != null)
                    Expanded(
                      flex: 1,
                      child: _buildRightCard(rightProduct),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileView(List<dynamic> gridProducts) {
    final leftProducts = gridProducts.length >= 2 
        ? gridProducts.sublist(0, 2) 
        : gridProducts;
    final rightProduct = gridProducts.length >= 3 ? gridProducts[2] : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - 2 Products Stacked
          Expanded(
            flex: 2,
            child: Column(
              children: leftProducts.asMap().entries.map((entry) {
                final product = entry.value;
                return _buildLeftCard(product);
              }).toList(),
            ),
          ),
          const SizedBox(width: 4),
          // Right Column - 1 Product
          if (rightProduct != null)
            Expanded(
              flex: 1,
              child: _buildRightCard(rightProduct),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftCard(dynamic product) {
    final isActive = product.auctionEndDate != null && 
        product.auctionEndDate is int && 
        product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final currentBid = (product.highestBid != null && product.highestBid!.isNotEmpty)
        ? product.highestBid
        : product.startingBid;
    
    final timeLeft = _timeLeft[product.id] ?? "Loading...";
    final showTimer = isActive && timeLeft != "Ended";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Row(
        children: [
          // Product Image with Timer
          Stack(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionProductsDetails(slug: product.slug),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                    child: product.thumbnailImage != null && product.thumbnailImage!.isNotEmpty
                        ? Image.network(
                            product.thumbnailImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 30, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 30, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              if (showTimer)
                Positioned(
                  top: 4,
                  left: 60,
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
            ],
          ),
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuctionProductsDetails(slug: product.slug),
                        ),
                      );
                    },
                    child: Text(
                      _getProductName(product.name),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Bid Info Row
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
                            _formatPrice(currentBid),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Points Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '1 Bid = ${product.pointPerBid ?? 0}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bid Button
                  GestureDetector(
                    onTap: () {
                      if (is_logged_in.$ == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuctionProductsDetails(slug: product.slug),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: MyTheme.accent_color, width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Color(0xFF009572),
                            ),
                          ),
                          const Text(
                            'Bid Now',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF009572),
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

  Widget _buildRightCard(dynamic product) {
    final isActive = product.auctionEndDate != null && 
        product.auctionEndDate is int && 
        product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final currentBid = (product.highestBid != null && product.highestBid!.isNotEmpty)
        ? product.highestBid
        : product.startingBid;
    
    final timeLeft = _timeLeft[product.id] ?? "Loading...";
    final showTimer = isActive && timeLeft != "Ended";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          // Product Image with Timer
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuctionProductsDetails(slug: product.slug),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.thumbnailImage != null && product.thumbnailImage!.isNotEmpty
                        ? Image.network(
                            product.thumbnailImage!,
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
            ],
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionProductsDetails(slug: product.slug),
                      ),
                    );
                  },
                  child: Text(
                    _getProductName(product.name),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // Points text
                Text(
                  '1 Bid = ${product.pointPerBid ?? 0}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
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
                      _formatPrice(currentBid),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bid Button
                GestureDetector(
                  onTap: () {
                    if (is_logged_in.$ == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuctionProductsDetails(slug: product.slug),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Login(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: MyTheme.accent_color, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xFF009572),
                          ),
                        ),
                        const Text(
                          'Bid Now',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF009572),
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
    );
  }
}