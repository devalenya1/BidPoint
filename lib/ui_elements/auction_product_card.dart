// import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
// import 'package:active_ecommerce_flutter/helpers/system_config.dart';
// import 'package:active_ecommerce_flutter/my_theme.dart';
// import 'package:active_ecommerce_flutter/screens/product_details.dart';
// import 'package:active_ecommerce_flutter/screens/login.dart';
// import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
// import 'package:active_ecommerce_flutter/custom/toast_component.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:go_router/go_router.dart';

// class AuctionProductCard extends StatefulWidget {
//   final int id;
//   final String slug;
//   final String? image;
//   final String? name;
//   final String? description;
//   final int? pointPerBid;
//   final dynamic auctionEndDate;
//   final dynamic currentBid;
//   final dynamic startingBid;
//   final bool isAuctionActive;
//   final String? cardType; // 'hot', 'ending_left', 'ending_right', 'upcoming'

//   const AuctionProductCard({
//     Key? key,
//     required this.id,
//     required this.slug,
//     this.image,
//     this.name,
//     this.description,
//     this.pointPerBid,
//     this.auctionEndDate,
//     this.currentBid,
//     this.startingBid,
//     this.isAuctionActive = true,
//     this.cardType,
//   }) : super(key: key);

//   @override
//   State<AuctionProductCard> createState() => _AuctionProductCardState();
// }

// class _AuctionProductCardState extends State<AuctionProductCard> {
//   Timer? _timer;
//   String _timeLeft = "Loading...";
//   bool _isProcessing = false;
//   double _swipeAmount = 0.0;
//   bool _isSwiping = false;
//   double _startX = 0;
//   double _startY = 0;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   void _startTimer() {
//     _updateTimer();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateTimer();
//     });
//   }

//   void _updateTimer() {
//     if (widget.auctionEndDate == null) {
//       if (widget.cardType == 'upcoming') {
//         if (mounted) {
//           setState(() {
//             _timeLeft = "Coming Soon";
//           });
//         }
//       }
//       return;
//     }

//     // Handle "Ended" string case
//     if (widget.auctionEndDate is String && widget.auctionEndDate == "Ended") {
//       if (mounted) {
//         setState(() {
//           _timeLeft = "Ended";
//         });
//       }
//       _timer?.cancel();
//       return;
//     }

//     int endDate;
//     if (widget.auctionEndDate is int) {
//       endDate = widget.auctionEndDate;
//     } else if (widget.auctionEndDate is String) {
//       endDate = int.tryParse(widget.auctionEndDate) ?? 0;
//     } else {
//       return;
//     }

//     if (endDate <= 0) {
//       if (mounted) {
//         setState(() {
//           _timeLeft = "Ended";
//         });
//       }
//       _timer?.cancel();
//       return;
//     }

//     final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//     final distance = endDate - now;

//     if (distance < 0) {
//       if (mounted) {
//         setState(() {
//           _timeLeft = "Ended";
//         });
//       }
//       _timer?.cancel();
//       return;
//     }

//     final days = distance ~/ (24 * 3600);
//     final hours = (distance % (24 * 3600)) ~/ 3600;
//     final minutes = (distance % 3600) ~/ 60;
//     final seconds = distance % 60;

//     String timeString;
//     if (days > 0) {
//       timeString = "${days}d ${hours}h";
//     } else if (hours > 0) {
//       timeString = "${hours}h ${minutes}m";
//     } else if (minutes > 0) {
//       timeString = "${minutes}m ${seconds}s";
//     } else {
//       timeString = "${seconds}s";
//     }

//     if (mounted) {
//       setState(() {
//         _timeLeft = timeString;
//       });
//     }
//   }

//   // ============ PRICE HELPERS ============
//   double _parsePrice(dynamic price) {
//     if (price == null) return 0.0;
//     if (price is double) return price;
//     if (price is int) return price.toDouble();
//     if (price is String) {
//       final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
//       return double.tryParse(cleaned) ?? 0.0;
//     }
//     return 0.0;
//   }

//   String _formatPrice(dynamic price) {
//     final doubleValue = _parsePrice(price);
//     final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
//     return '$symbol${doubleValue.toStringAsFixed(2)}';
//   }

//   double _getDisplayBid() {
//     if (widget.currentBid != null) {
//       final parsed = _parsePrice(widget.currentBid);
//       if (parsed > 0) return parsed;
//     }
//     if (widget.startingBid != null) {
//       final parsed = _parsePrice(widget.startingBid);
//       if (parsed > 0) return parsed;
//     }
//     return 0.0;
//   }

//   // ============ SWIPE TO BID ============
//   void _onPanStart(DragStartDetails details) {
//     _startX = details.localPosition.dx;
//     _startY = details.localPosition.dy;
//     _isSwiping = true;
//   }

//   void _onPanUpdate(DragUpdateDetails details) {
//     if (!_isSwiping) return;
    
//     final deltaX = details.localPosition.dx - _startX;
//     final deltaY = details.localPosition.dy - _startY;
    
//     if (deltaX > 5 && deltaY.abs() < 30) {
//       setState(() {
//         _swipeAmount = deltaX.clamp(0.0, 60.0);
//       });
//     } else if (deltaX < -5) {
//       setState(() {
//         _swipeAmount = 0;
//       });
//     }
//   }

//   void _onPanEnd(DragEndDetails details) {
//     if (!_isSwiping) return;
    
//     final wasSwiped = _swipeAmount >= 40;
    
//     setState(() {
//       _isSwiping = false;
//       _swipeAmount = 0;
//     });
    
//     if (wasSwiped) {
//       _quickBid();
//     }
//   }

//   Future<void> _quickBid() async {
//     if (_isProcessing) return;
    
//     if (!is_logged_in.$) {
//       _showLoginDialog();
//       return;
//     }
    
//     _isProcessing = true;
//     setState(() {});
    
//     try {
//       final currentBid = _getDisplayBid();
//       final minBid = currentBid + 0.01;
      
//       final response = await ProductRepository().quickBid(
//         widget.id.toString(),
//         minBid.toString(),
//         type: 'quick',
//       );
      
//       if (response.success == true) {
//         ToastComponent.showDialog(
//           'Quick bid placed! Amount: ${_formatPrice(minBid)}',
//         );
//         GoRouter.of(context).go('/product/${widget.slug}');
//       } else {
//         ToastComponent.showDialog(
//           response.message ?? 'Failed to place bid',
//         );
//       }
//     } catch (e) {
//       ToastComponent.showDialog('Error placing bid');
//     } finally {
//       _isProcessing = false;
//       setState(() {});
//     }
//   }

//   void _showLoginDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Login Required'),
//         content: const Text('Please login to place a bid'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => Login()),
//               );
//             },
//             child: const Text('Login'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _notifyMe() async {
//     if (_isProcessing) return;
    
//     if (!is_logged_in.$) {
//       _showLoginDialog();
//       return;
//     }
    
//     _isProcessing = true;
//     setState(() {});
    
//     try {
//       final response = await ProductRepository().notifyMeForAuction(widget.id);
      
//       if (response['success'] == true) {
//         ToastComponent.showDialog(
//           response['message'] ?? 'You will be notified when this auction starts!',
//         );
//       } else {
//         ToastComponent.showDialog(
//           response['message'] ?? 'Failed to set notification',
//         );
//       }
//     } catch (e) {
//       ToastComponent.showDialog('Error setting notification');
//     } finally {
//       _isProcessing = false;
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final displayBid = _getDisplayBid();
//     final showTimer = _timeLeft != "Ended" && _timeLeft != "Coming Soon";
//     final isEndingLeft = widget.cardType == 'ending_left';
//     final isEndingRight = widget.cardType == 'ending_right';
//     final isUpcoming = widget.cardType == 'upcoming';
//     final isHot = widget.cardType == 'hot' || widget.cardType == null;

//     if (isEndingLeft) {
//       return _buildEndingLeftCard(displayBid, showTimer);
//     } else if (isEndingRight) {
//       return _buildEndingRightCard(displayBid, showTimer);
//     } else {
//       return _buildStandardCard(displayBid, showTimer, isUpcoming, isHot);
//     }
//   }

//   Widget _buildStandardCard(double displayBid, bool showTimer, bool isUpcoming, bool isHot) {
//     return GestureDetector(
//       onPanStart: isHot ? _onPanStart : null,
//       onPanUpdate: isHot ? _onPanUpdate : null,
//       onPanEnd: isHot ? _onPanEnd : null,
//       child: Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFFF2F2F3),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFEDF2F7)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 3,
//               offset: const Offset(0, 1),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Image with Timer
//             Stack(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     GoRouter.of(context).go('/product/${widget.slug}');
//                   },
//                   child: AspectRatio(
//                     aspectRatio: 1,
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//                       child: widget.image != null && widget.image!.isNotEmpty
//                           ? Image.network(
//                               widget.image!,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Container(
//                                   color: Colors.grey[200],
//                                   child: const Icon(Icons.image, size: 40, color: Colors.grey),
//                                 );
//                               },
//                             )
//                           : Container(
//                               color: Colors.grey[200],
//                               child: const Icon(Icons.image, size: 40, color: Colors.grey),
//                             ),
//                     ),
//                   ),
//                 ),
//                 // Timer - Green at top right for all cards
//                 Positioned(
//                   top: 6,
//                   right: 6,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF009572),
//                       borderRadius: BorderRadius.circular(30),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.access_time, size: 10, color: Colors.white),
//                         const SizedBox(width: 3),
//                         Text(
//                           _timeLeft,
//                           style: const TextStyle(
//                             fontSize: 9,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
            
//             // Product Details
//             Padding(
//               padding: const EdgeInsets.all(10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Name - Larger
//                   GestureDetector(
//                     onTap: () {
//                       GoRouter.of(context).go('/product/${widget.slug}');
//                     },
//                     child: Text(
//                       widget.name ?? 'Product',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
                  
//                   // Description - Below title
//                   Text(
//                     widget.description ?? '',
//                     style: const TextStyle(
//                       fontSize: 10,
//                       color: Color(0xFF8F9AA7),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 10),
                  
//                   // Current Bid and Points Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Current Bid - Larger
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Current Bid',
//                             style: TextStyle(
//                               fontSize: 9,
//                               color: Color(0xFF80818B),
//                             ),
//                           ),
//                           Text(
//                             _formatPrice(displayBid),
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ],
//                       ),
//                       // Points Badge with USD icon
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFB5E7F5),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(
//                               Icons.access_time,,
//                               size: 12,
//                               color: Color(0xFF0092AC),
//                             ),
//                             const SizedBox(width: 2),
//                             Text(
//                               '1 Bid = ${widget.pointPerBid ?? 0}',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: MyTheme.accent_color,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
                  
//                   // Action Button
//                   if (isUpcoming)
//                     _buildNotifyMeButton()
//                   else
//                     _buildBidButton(isHot),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBidButton(bool isHot) {
//     if (isHot) {
//       // Hot Auction: Primary color with "Swipe to Bid" and > icon
//       return Container(
//         width: double.infinity,
//         height: 40,
//         decoration: BoxDecoration(
//           color: MyTheme.accent_color,
//           borderRadius: BorderRadius.circular(7),
//         ),
//         child: Stack(
//           children: [
//             // Swipe indicator (white box with >)
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 50),
//               width: 28 + (_swipeAmount),
//               height: 40,
//               decoration: BoxDecoration(
//                 color: _swipeAmount > 20 ? Colors.green : Colors.white,
//                 borderRadius: BorderRadius.circular(7),
//               ),
//               child: Center(
//                 child: Icon(
//                   Icons.arrow_forward_ios,
//                   size: 14,
//                   color: _swipeAmount > 20 ? Colors.white : MyTheme.accent_color,
//                 ),
//               ),
//             ),
//             // Center text
//             Center(
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (_swipeAmount < 20) ...[
//                     const SizedBox(width: 30),
//                     Text(
//                       'Swipe to Bid',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ] else ...[
//                     const Text(
//                       'Quick Bid',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // Ending Soon: White background with accent border
//       return Container(
//         width: double.infinity,
//         height: 40,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: MyTheme.accent_color, width: 1),
//           borderRadius: BorderRadius.circular(7),
//         ),
//         child: Center(
//           child: _isProcessing
//               ? const SizedBox(
//                   height: 16,
//                   width: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: MyTheme.accent_color,
//                   ),
//                 )
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       'Bid Now',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                         color: MyTheme.accent_color,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.arrow_forward,
//                       size: 12,
//                       color: MyTheme.accent_color,
//                     ),
//                   ],
//                 ),
//         ),
//       );
//     }
//   }

//   Widget _buildNotifyMeButton() {
//     return Container(
//       width: double.infinity,
//       height: 40,
//       decoration: BoxDecoration(
//         color: MyTheme.accent_color,
//         borderRadius: BorderRadius.circular(7),
//       ),
//       child: Center(
//         child: _isProcessing
//             ? const SizedBox(
//                 height: 16,
//                 width: 16,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     'Notify Me',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   const Icon(
//                     Icons.arrow_forward,
//                     size: 12,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _buildEndingLeftCard(double displayBid, bool showTimer) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F2F3),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFEDF2F7)),
//       ),
//       child: Row(
//         children: [
//           // Product Image with Timer
//           Stack(
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   GoRouter.of(context).go('/product/${widget.slug}');
//                 },
//                 child: SizedBox(
//                   width: 100,
//                   height: 100,
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
//                     child: widget.image != null && widget.image!.isNotEmpty
//                         ? Image.network(
//                             widget.image!,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 color: Colors.grey[200],
//                                 child: const Icon(Icons.image, size: 30, color: Colors.grey),
//                               );
//                             },
//                           )
//                         : Container(
//                             color: Colors.grey[200],
//                             child: const Icon(Icons.image, size: 30, color: Colors.grey),
//                           ),
//                   ),
//                 ),
//               ),
//               // Timer - Green at top right
//               Positioned(
//                 top: 4,
//                 right: 4,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF009572),
//                     borderRadius: BorderRadius.circular(30),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.access_time, size: 10, color: Colors.white),
//                       const SizedBox(width: 3),
//                       Text(
//                         _timeLeft,
//                         style: const TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
          
//           // Product Info
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Name - Larger
//                   GestureDetector(
//                     onTap: () {
//                       GoRouter.of(context).go('/product/${widget.slug}');
//                     },
//                     child: Text(
//                       widget.name ?? 'Product',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
                  
//                   // Description
//                   Text(
//                     widget.description ?? '',
//                     style: const TextStyle(
//                       fontSize: 9,
//                       color: Color(0xFF8F9AA7),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const Spacer(),
                  
//                   // Bid Info Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Current Bid
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Current Bid',
//                             style: TextStyle(
//                               fontSize: 8,
//                               color: Color(0xFF80818B),
//                             ),
//                           ),
//                           Text(
//                             _formatPrice(displayBid),
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ],
//                       ),
//                       // Points Badge with USD icon
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFB5E7F5),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(
//                               Icons.access_time,,
//                               size: 10,
//                               color: Color(0xFF0092AC),
//                             ),
//                             const SizedBox(width: 2),
//                             Text(
//                               '1 Bid = ${widget.pointPerBid ?? 0}',
//                               style: TextStyle(
//                                 fontSize: 8,
//                                 fontWeight: FontWeight.w600,
//                                 color: MyTheme.accent_color,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Bid Button (white with accent border)
//                   Container(
//                     width: double.infinity,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border.all(color: MyTheme.accent_color, width: 1),
//                       borderRadius: BorderRadius.circular(7),
//                     ),
//                     child: Center(
//                       child: _isProcessing
//                           ? const SizedBox(
//                               height: 14,
//                               width: 14,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: MyTheme.accent_color,
//                               ),
//                             )
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text(
//                                   'Bid Now',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w600,
//                                     color: MyTheme.accent_color,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Icon(
//                                   Icons.arrow_forward,
//                                   size: 10,
//                                   color: MyTheme.accent_color,
//                                 ),
//                               ],
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEndingRightCard(double displayBid, bool showTimer) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F2F3),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFEDF2F7)),
//       ),
//       child: Column(
//         children: [
//           // Product Image with Timer
//           Stack(
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   GoRouter.of(context).go('/product/${widget.slug}');
//                 },
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//                   child: AspectRatio(
//                     aspectRatio: 1,
//                     child: widget.image != null && widget.image!.isNotEmpty
//                         ? Image.network(
//                             widget.image!,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 color: Colors.grey[200],
//                                 child: const Icon(Icons.image, size: 40, color: Colors.grey),
//                               );
//                             },
//                           )
//                         : Container(
//                             color: Colors.grey[200],
//                             child: const Icon(Icons.image, size: 40, color: Colors.grey),
//                           ),
//                   ),
//                 ),
//               ),
//               // Timer - Green at top right
//               Positioned(
//                 top: 6,
//                 right: 6,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF009572),
//                     borderRadius: BorderRadius.circular(30),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.access_time, size: 10, color: Colors.white),
//                       const SizedBox(width: 3),
//                       Text(
//                         _timeLeft,
//                         style: const TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
          
//           // Product Info
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Product Name - Larger
//                 GestureDetector(
//                   onTap: () {
//                     GoRouter.of(context).go('/product/${widget.slug}');
//                   },
//                   child: Text(
//                     widget.name ?? 'Product',
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
                
//                 // Description
//                 Text(
//                   widget.description ?? '',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: Color(0xFF8F9AA7),
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
                
//                 // Points text with USD icon
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.access_time,,
//                       size: 12,
//                       color: Color(0xFF718096),
//                     ),
//                     const SizedBox(width: 2),
//                     Text(
//                       '1 Bid = ${widget.pointPerBid ?? 0}',
//                       style: const TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF718096),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
                
//                 // Current Bid
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Current Bid',
//                       style: TextStyle(
//                         fontSize: 9,
//                         color: Color(0xFF80818B),
//                       ),
//                     ),
//                     Text(
//                       _formatPrice(displayBid),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w800,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
                
//                 // Bid Button (white with accent border)
//                 Container(
//                   width: double.infinity,
//                   height: 35,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: MyTheme.accent_color, width: 1),
//                     borderRadius: BorderRadius.circular(7),
//                   ),
//                   child: Center(
//                     child: _isProcessing
//                         ? const SizedBox(
//                             height: 14,
//                             width: 14,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: MyTheme.accent_color,
//                             ),
//                           )
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Text(
//                                 'Bid Now',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w600,
//                                   color: MyTheme.accent_color,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Icon(
//                                 Icons.arrow_forward,
//                                 size: 10,
//                                 color: MyTheme.accent_color,
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }