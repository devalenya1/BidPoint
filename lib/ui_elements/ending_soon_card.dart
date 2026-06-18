import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

class EndingSoonCard extends StatefulWidget {
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
  final String? cardType; // 'left' or 'right'

  const EndingSoonCard({
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
    this.cardType,
  }) : super(key: key);

  @override
  State<EndingSoonCard> createState() => _EndingSoonCardState();
}

class _EndingSoonCardState extends State<EndingSoonCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
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

    if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
      if (mounted) {
        setState(() {
          _timeLeft = "Ended";
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
    final doubleValue = _parsePrice(price);
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${doubleValue.toStringAsFixed(2)}';
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

  Future<void> _quickBid() async {
    if (_isProcessing) return;
    
    if (!is_logged_in.$) {
      _showLoginDialog();
      return;
    }
    
    _isProcessing = true;
    setState(() {});
    
    try {
      final currentBid = _getDisplayBid();
      final minBid = currentBid + 0.01;
      
      final response = await ProductRepository().quickBid(
        widget.id.toString(),
        minBid.toString(),
        type: 'quick',
      );
      
      if (response.success == true) {
        ToastComponent.showDialog(
          'Quick bid placed! Amount: ${_formatPrice(minBid)}',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(slug: widget.slug),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final displayBid = _getDisplayBid();
    final showTimer = widget.isAuctionActive && _timeLeft != "Ended";
    final isLeft = widget.cardType == 'left';

    if (isLeft) {
      return _buildLeftCard(displayBid, showTimer);
    } else {
      return _buildRightCard(displayBid, showTimer);
    }
  }

  Widget _buildLeftCard(double displayBid, bool showTimer) {
    return Container(
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(slug: widget.slug),
                    ),
                  );
                },
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    child: widget.image != null && widget.image!.isNotEmpty
                        ? Image.network(
                            widget.image!,
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
                  right: 4,
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
          
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetails(slug: widget.slug),
                        ),
                      );
                    },
                    child: Text(
                      widget.name ?? 'Product',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.description ?? '',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8F9AA7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Bid',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF80818B),
                            ),
                          ),
                          Text(
                            _formatPrice(displayBid),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E7F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 10,
                              color: Color(0xFF0092AC),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '1 Bid = ${widget.pointPerBid ?? 0}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bid Now Button
                  GestureDetector(
                    onTap: _quickBid,
                    child: Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: MyTheme.accent_color, width: 1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MyTheme.accent_color,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Bid Now',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: MyTheme.accent_color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 10,
                                    color: MyTheme.accent_color,
                                  ),
                                ],
                              ),
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

  Widget _buildRightCard(double displayBid, bool showTimer) {
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
                      builder: (context) => ProductDetails(slug: widget.slug),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: AspectRatio(
                    aspectRatio: 1,
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
          
          // Product Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetails(slug: widget.slug),
                      ),
                    );
                  },
                  child: Text(
                    widget.name ?? 'Product',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8F9AA7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 12,
                      color: Color(0xFF718096),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '1 Bid = ${widget.pointPerBid ?? 0}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Bid',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF80818B),
                      ),
                    ),
                    Text(
                      _formatPrice(displayBid),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _quickBid,
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: MyTheme.accent_color, width: 1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MyTheme.accent_color,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Bid Now',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: MyTheme.accent_color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 10,
                                  color: MyTheme.accent_color,
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