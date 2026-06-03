import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/auction_products_details.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AuctionProductCard extends StatefulWidget {
  final int id;
  final String slug;
  final String? image;
  final String? name;
  final String? description;
  final String? startingBid;
  final String? currentBid;
  final String? mainPrice;
  final int? auctionEndDate; // timestamp
  final int? pointPerBid;
  final bool hasDiscount;
  final String? discount;

  const AuctionProductCard({
    Key? key,
    required this.id,
    required this.slug,
    this.image,
    this.name,
    this.description,
    this.startingBid,
    this.currentBid,
    this.mainPrice,
    this.auctionEndDate,
    this.pointPerBid,
    this.hasDiscount = false,
    this.discount,
  }) : super(key: key);

  @override
  _AuctionProductCardState createState() => _AuctionProductCardState();
}

class _AuctionProductCardState extends State<AuctionProductCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
  bool _isSwiping = false;
  double _swipeOffset = 0.0;
  bool _showQuickBid = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
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
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = widget.auctionEndDate! - now;

    if (distance < 0) {
      setState(() {
        _timeLeft = "Ended";
      });
      _timer?.cancel();
      return;
    }

    final days = distance ~/ (24 * 3600);
    final hours = (distance % (24 * 3600)) ~/ 3600;
    final minutes = (distance % 3600) ~/ 60;
    final seconds = distance % 60;

    setState(() {
      if (days > 0) {
        _timeLeft = "$days${_getLocalizedString('d')} $hours${_getLocalizedString('h')}";
      } else if (hours > 0) {
        _timeLeft = "$hours${_getLocalizedString('h')} $minutes${_getLocalizedString('m')}";
      } else if (minutes > 0) {
        _timeLeft = "$minutes${_getLocalizedString('m')} $seconds${_getLocalizedString('s')}";
      } else {
        _timeLeft = "${seconds}s";
      }
    });
  }

  String _getLocalizedString(String key) {
    // You can replace with your localization
    switch (key) {
      case 'd': return 'd';
      case 'h': return 'h';
      case 'm': return 'm';
      case 's': return 's';
      default: return '';
    }
  }

  String _formatPrice(String? price) {
    if (price == null) return '';
    // Replace currency code with symbol if needed
    if (SystemConfig.systemCurrency != null) {
      return price.replaceAll(
        SystemConfig.systemCurrency!.code!,
        SystemConfig.systemCurrency!.symbol!,
      );
    }
    return price;
  }

  void _handleQuickBid() {
    // Implement your bid logic here
    print("Quick bid for product: ${widget.id}");
    // Navigate to bid page or show bid modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionProductsDetails(slug: widget.slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card width based on screen size (responsive)
    double cardWidth;
    if (screenWidth > 1200) {
      cardWidth = (screenWidth - 48) / 6; // 6 items on desktop
    } else if (screenWidth > 768) {
      cardWidth = (screenWidth - 40) / 4; // 4 items on tablet
    } else {
      cardWidth = (screenWidth - 32) / 2; // 2 items on mobile
    }
    // Cap minimum width
    cardWidth = cardWidth.clamp(140.0, 250.0);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          setState(() {
            _isSwiping = true;
            _swipeOffset = 0;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (_isSwiping) {
            setState(() {
              // Only allow right swipe (positive delta)
              _swipeOffset = details.delta.dx.clamp(0.0, 60.0);
              _showQuickBid = _swipeOffset > 20;
            });
          }
        },
        onHorizontalDragEnd: (details) {
          if (_isSwiping && _swipeOffset >= 40) {
            _handleQuickBid();
          }
          setState(() {
            _isSwiping = false;
            _swipeOffset = 0;
            _showQuickBid = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F3), // #F2F2F3 background
            borderRadius: BorderRadius.circular(10), // 10px radius
            border: Border.all(color: const Color(0xFFEDF2F7)), // #edf2f7 border
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
              // Product Image with Timer at Top Right
              Stack(
                children: [
                  // Image Container (1:1 aspect ratio)
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image!,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF2F2F3),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color.fromRGBO(107, 115, 119, 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Timer Badge (Top Right) - Green background #009572
                  if (widget.auctionEndDate != null && _timeLeft != "Ended")
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009572), // #009572 green
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
                  
                  // Ended Badge (if auction ended)
                  if (widget.auctionEndDate != null && _timeLeft == "Ended")
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name (truncated to 20 chars)
                    Text(
                      widget.name!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Description (truncated to 35 chars)
                    if (widget.description != null)
                      Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 9,
                          color: const Color(0xFF8F9AA7), // #8f9aa7
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    
                    // Current Bid and Bid Increment Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Current Bid Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "current Bid",
                              style: TextStyle(
                                fontSize: 9,
                                color: const Color(0xFF80818B), // #80818B
                              ),
                            ),
                            Text(
                              _formatPrice(widget.currentBid ?? widget.startingBid),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        
                        // Bid Increment Badge
                        if (widget.pointPerBid != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB5E7F5), // #B5E7F5
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 9,
                                  color: Color(0xFF009572),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "1 Bid = ${widget.pointPerBid}",
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF009572),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Swipe to Bid Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: Matrix4.translationValues(_swipeOffset, 0, 0),
                      child: GestureDetector(
                        onTap: _handleQuickBid,
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
                                      color: Color(0xFF009572),
                                    ),
                                  ),
                                ),
                              ),
                              // Center text that fades on swipe
                              Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  opacity: _showQuickBid ? 0 : 1,
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
                              if (_showQuickBid)
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}