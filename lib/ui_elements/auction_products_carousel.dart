import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/ui_elements/auction_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuctionProductsCarousel extends StatelessWidget {
  final List<dynamic> products; // Replace 'dynamic' with your actual product model
  final String title;
  final VoidCallback? onViewAll;

  const AuctionProductsCarousel({
    Key? key,
    required this.products,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine how many items to show based on screen width
    int getItemsPerView() {
      if (screenWidth > 1200) return 6;      // Desktop: 6 items
      if (screenWidth > 768) return 4;       // Tablet: 4 items
      return 2;                               // Mobile: 2 items
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section with Title and View All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // View All Button
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF2F2F3), // #F2F2F3
                        width: 1,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.view_all_ucf,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF80818B), // #80818B
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Horizontal Carousel
        SizedBox(
          height: 280, // Fixed height for the carousel
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return AuctionProductCard(
                id: product.id,
                slug: product.slug,
                image: product.thumbnail_image,
                name: product.name,
                description: product.description,
                startingBid: product.starting_bid,
                currentBid: product.current_bid,
                auctionEndDate: product.auction_end_date,
                pointPerBid: product.point_per_bid,
              );
            },
          ),
        ),
      ],
    );
  }
}