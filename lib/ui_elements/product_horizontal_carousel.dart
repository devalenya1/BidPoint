import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class ProductHorizontalCarousel extends StatelessWidget {
  final List<dynamic> products;
  final ScrollController? scrollController;

  const ProductHorizontalCarousel({
    Key? key,
    required this.products,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card width based on screen size
    // 2 on mobile, 4 on tablet, 6 on desktop
    double getCardWidth() {
      if (screenWidth > 1200) {
        // Desktop: 6 items visible
        return (screenWidth - 48) / 6; // 48 = padding (16*2) + spacing
      } else if (screenWidth > 768) {
        // Tablet: 4 items visible
        return (screenWidth - 40) / 4; // 40 = padding (16*2) + spacing
      } else {
        // Mobile: 2 items visible
        return (screenWidth - 32) / 2; // 32 = padding (16*2)
      }
    }

    return SizedBox(
      height: 280, // Fixed height for horizontal cards
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: getCardWidth(),
            margin: const EdgeInsets.only(right: 12),
            child: ProductCard(
              id: product.id,
              slug: product.slug,
              image: product.thumbnail_image,
              name: product.name,
              main_price: product.main_price,
              stroked_price: product.stroked_price,
              has_discount: product.has_discount,
              discount: product.discount,
              is_wholesale: product.isWholesale,
            ),
          );
        },
      ),
    );
  }
}