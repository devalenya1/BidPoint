import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/auction_products_details.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

class UpcomingSection extends StatefulWidget {
  final List<dynamic> products;
  final String title;
  final String viewAllRoute;

  const UpcomingSection({
    Key? key,
    required this.products,
    required this.title,
    required this.viewAllRoute,
  }) : super(key: key);

  @override
  State<UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends State<UpcomingSection> {
  final Map<int, Timer> _timers = {};
  final Map<int, String> _timeLeft = {};
  final Map<int, bool> _notifying = {};
  final Map<int, bool> _notified = {};

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
      _notifying[product.id] = false;
      _notified[product.id] = false;
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

  String _formatPrice(double? price) {
    if (price == null) return '\$0.00';
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
  }

  String _getProductName(String? name) {
    if (name == null) return '';
    if (name.length > 20) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  String _getProductDescription(String? description) {
    if (description == null) return '';
    final stripped = description.replaceAll(RegExp(r'<[^>]*>'), '');
    if (stripped.length > 35) {
      return '${stripped.substring(0, 32)}...';
    }
    return stripped;
  }

  Future<void> _notifyMe(int productId, String slug) async {
    if (_notifying[productId] == true) return;
    
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    
    if (_notified[productId] == true) {
      ToastComponent.showDialog(
        'You will be notified when this auction starts!',
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
      return;
    }

    setState(() {
      _notifying[productId] = true;
    });

    try {
      final response = await ProductRepository().notifyMeForAuction(productId);
      
      if (response['success'] == true) {
        setState(() {
          _notified[productId] = true;
        });
        ToastComponent.showDialog(
          response['message'] ?? 'You will be notified when this auction starts!',
          gravity: Toast.center,
          duration: Toast.lengthShort,
        );
      } else {
        ToastComponent.showDialog(
          response['message'] ?? 'Failed to set notification. Please try again.',
          gravity: Toast.center,
          duration: Toast.lengthShort,
        );
      }
    } catch (e) {
      print("Error notifying for auction: $e");
      ToastComponent.showDialog(
        'Network error. Please check your connection and try again.',
        gravity: Toast.center,
        duration: Toast.lengthShort,
      );
    } finally {
      if (mounted) {
        setState(() {
          _notifying[productId] = false;
        });
      }
    }
  }
  
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to set notification'),
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

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  GoRouter.of(context).go(widget.viewAllRoute);
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
        
        // Horizontal Scrollable Carousel
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.7,
                margin: const EdgeInsets.only(right: 12),
                child: _buildUpcomingCard(product),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUpcomingCard(dynamic product) {
    final isActive = product.auctionEndDate != null && 
        product.auctionEndDate is int && 
        product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final currentBid = (product.highestBid != null && product.highestBid > 0)
        ? (product.highestBid is double ? product.highestBid : double.tryParse(product.highestBid.toString()) ?? 0)
        : (product.startingBid is double ? product.startingBid : double.tryParse(product.startingBid.toString()) ?? 0);
    
    final timeLeft = _timeLeft[product.id] ?? "Loading...";
    final showTimer = isActive && timeLeft != "Ended";
    final isNotifying = _notifying[product.id] == true;
    final isNotified = _notified[product.id] == true;

    return Container(
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
                  GoRouter.of(context).go('/auction-product/${product.slug}');
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
          
          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                GestureDetector(
                  onTap: () {
                    GoRouter.of(context).go('/auction-product/${product.slug}');
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
                const SizedBox(height: 2),
                
                // Description
                Text(
                  _getProductDescription(product.name),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E7F5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '1 Bid = ${product.pointPerBid ?? 0}',
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
                
                // Notify Me Button
                GestureDetector(
                  onTap: isNotified ? null : () => _notifyMe(product.id, product.slug),
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      color: isNotified ? Colors.grey : MyTheme.accent_color,
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: isNotifying
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isNotified ? 'Notified' : 'Notify Me',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (!isNotified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 10,
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