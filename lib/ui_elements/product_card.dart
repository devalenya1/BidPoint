import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../helpers/shared_value_helper.dart';
import '../screens/auction_products_details.dart';

class ProductCard extends StatefulWidget {
  var identifier;
  int? id;
  String slug;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;
  bool? is_wholesale;
  var discount;
  // New auction-specific fields
  String? description;
  String? currentBid;
  int? pointsPerBid;
  int? auctionEndDate;

  ProductCard({
    Key? key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.is_wholesale = false,
    this.stroked_price,
    this.has_discount,
    this.discount,
    this.description,
    this.currentBid,
    this.pointsPerBid,
    this.auctionEndDate,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  String _timeLeft = "Loading...";
  double _swipeOffset = 0.0;
  bool _showQuickBid = false;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    if (widget.identifier == 'auction' && widget.auctionEndDate != null) {
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
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final distance = widget.auctionEndDate! - now;

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

    if (mounted) {
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
  }

  String _getLocalizedString(String key) {
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
    if (SystemConfig.systemCurrency != null) {
      return price.replaceAll(
        SystemConfig.systemCurrency!.code!,
        SystemConfig.systemCurrency!.symbol!,
      );
    }
    return price;
  }

  void _handleQuickBid() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick bid placed on ${widget.name}!'),
        backgroundColor: const Color(0xFF009572),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an auction product
    final bool isAuction = widget.identifier == 'auction';
    final bool isEnded = _timeLeft == "Ended";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return widget.identifier == 'auction'
                  ? AuctionProductsDetails(slug: widget.slug)
                  : ProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F3), // HTML background color
          borderRadius: BorderRadius.circular(10), // HTML border radius
          border: Border.all(color: const Color(0xFFEDF2F7)), // HTML border color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isAuction ? _buildAuctionCard() : _buildRegularCard(),
      ),
    );
  }

  Widget _buildRegularCard() {
    return Stack(
      children: [
        Column(children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              child: ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10), bottom: Radius.zero),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png',
                  image: widget.image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    widget.name!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                widget.has_discount!
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          _formatPrice(widget.stroked_price),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.medium_grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                      )
                    : Container(height: 8.0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    _formatPrice(widget.main_price),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ]),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.has_discount!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xffe62e04),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(-1, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.discount ?? "",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xffffffff),
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                      ),
                      textHeightBehavior:
                          const TextHeightBehavior(applyHeightToFirstAscent: false),
                      softWrap: false,
                    ),
                  ),
                Visibility(
                  visible: whole_sale_addon_installed.$,
                  child: widget.is_wholesale != null && widget.is_wholesale!
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x14000000),
                                offset: Offset(-1, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            "Wholesale",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xffffffff),
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                            textHeightBehavior:
                                TextHeightBehavior(applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        )
                      : const SizedBox.shrink(),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionCard() {
    final bool isEnded = _timeLeft == "Ended";
    final String displayName = _truncateText(widget.name ?? '', 20);
    final String displayDescription = _truncateText(widget.description ?? '', 35);
    final String displayCurrentBid = widget.currentBid ?? widget.main_price ?? '\$0.00';
    final int displayPointsPerBid = widget.pointsPerBid ?? 10;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        setState(() {
          _isSwiping = true;
          _swipeOffset = 0;
          _showQuickBid = false;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (_isSwiping && details.delta.dx > 0) {
          setState(() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with Timer
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: widget.image!,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF2F2F3),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Timer Badge (Top Right) - Green #009572
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
              // Ended Badge (Red)
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
          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name (11px, truncate to 20 chars)
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description (9px, truncate to 35 chars, color #8f9aa7)
                if (displayDescription.isNotEmpty)
                  Text(
                    displayDescription,
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
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF80818B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPrice(displayCurrentBid),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    // Bid Increment Badge (#B5E7F5)
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
                            "1 Bid = $displayPointsPerBid",
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
                  transform: Matrix4.translationValues(_swipeOffset, 0, 0),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}