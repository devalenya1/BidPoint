import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';

class ListProductCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;

  ListProductCard({
    Key? key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
  }) : super(key: key);

  @override
  _ListProductCardState createState() => _ListProductCardState();
}

class _ListProductCardState extends State<ListProductCard> {
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
  // NEW - Uses FormatHelper
  String _formatPrice(dynamic price) {
    final doubleValue = _parsePrice(price);
    return FormatHelper.formatPrice(doubleValue);
  }
  
  /// Get the display price with proper formatting
  String _getDisplayPrice(String? price) {
    if (price == null || price.isEmpty) {
      return _formatPrice(0.0);
    }
    return _formatPrice(price);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            slug: widget.slug,
          );
        }));
      },
      child: Container(
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(6),
                  right: Radius.zero,
                ),
                child: widget.image != null && widget.image!.isNotEmpty
                    ? FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image!,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
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
            Flexible(
              child: Container(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 14),
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        widget.name ?? 'Product',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          // Main Price (formatted)
                          Text(
                            _getDisplayPrice(widget.main_price),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            style: TextStyle(
                              color: MyTheme.accent_color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Stroked Price (if has discount)
                          if (widget.has_discount == true && 
                              widget.stroked_price != null && 
                              widget.stroked_price!.isNotEmpty)
                            Text(
                              _getDisplayPrice(widget.stroked_price),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: MyTheme.medium_grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}