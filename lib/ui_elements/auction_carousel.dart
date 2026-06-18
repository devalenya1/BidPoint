// import 'package:flutter/material.dart';
// import 'package:active_ecommerce_flutter/my_theme.dart';
// import 'package:active_ecommerce_flutter/ui_elements/auction_product_card.dart';

// class AuctionCarousel extends StatelessWidget {
//   final List<dynamic> products;
//   final String title;
//   final String viewAllRoute;

//   const AuctionCarousel({
//     Key? key,
//     required this.products,
//     required this.title,
//     required this.viewAllRoute,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (products.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header Section
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to view all page
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: const Color(0xFFF2F2F3)),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Text(
//                     'View All',
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF80818B),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         // Horizontal Scrollable Products
//         SizedBox(
//           height: 320,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index];
//               final isAuctionActive = product.auctionEndDate != null && 
//                   product.auctionEndDate is int && 
//                   product.auctionEndDate > DateTime.now().millisecondsSinceEpoch ~/ 1000;
              
//               return Container(
//                 width: MediaQuery.of(context).size.width * 0.7,
//                 margin: const EdgeInsets.only(right: 12),
//                 child: AuctionProductCard(
//                   id: product.id ?? 0,
//                   slug: product.slug ?? '',
//                   image: product.thumbnailImage,
//                   name: product.name,
//                   description: product.name,
//                   pointPerBid: product.pointPerBid ?? 0,
//                   auctionEndDate: product.auctionEndDate,
//                   currentBid: product.highestBid,
//                   startingBid: product.startingBid,
//                   isAuctionActive: isAuctionActive,
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
// }