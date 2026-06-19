import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/text_styles.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/chat_repository.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../data_model/product_details_response.dart';
import '../data_model/comment_response.dart';
import '../data_model/review_response.dart';
import '../data_model/bid_history_response.dart';
import '../helpers/main_helpers.dart';

class ProductDetails extends StatefulWidget {
  String slug;

  ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late ScrollController _mainScrollController;
  TextEditingController _commentController = TextEditingController();
  TextEditingController _bidController = TextEditingController();
  TextEditingController _reviewController = TextEditingController();

  // Data
  bool _isLoading = true;
  DetailedProduct? _product;
  List<String> _productImages = [];
  List<Comment> _comments = [];
  List<Review> _reviews = [];
  List<BidHistory> _bidHistory = [];
  int _currentImageIndex = 0;
  double _selectedRating = 0;
  
  // UI State
  bool _isWishlisted = false;
  bool _isInWishlist = false;
  bool _showMoreMenu = false;
  bool _showDesktopMoreMenu = false;
  bool _showReviewsModal = false;
  bool _showAddReviewModal = false;
  bool _showBidHistoryModal = false;
  bool _showTitleModal = false;
  bool _showWinnerModal = false;
  bool _winnerModalShown = false;
  
  // Timer
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Duration _timeLeft = Duration.zero;
  bool _isEndingSoon = false;
  int _endingSeconds = 10; // Default, will be updated from API
  
  // Bid Data
  double _currentHighestBid = 0;
  double _minNextBidNow = 0;
  double _minNextBid = 0;
  int _totalBids = 0;
  String _highestBidder = '';
  double _startingBid = 0;
  double _pointPerBid = 0;
  double _pointPerBidCustom = 0;
  int _reviewsCount = 0;
  double _rating = 0;
  
  // Winner Data
  Winner? _winnerData;
  
  // Sound
  bool _soundEnabled = true;
  
  // Repository
  final ProductRepository _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mainScrollController = ScrollController();
    _fetchAllData();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainScrollController.dispose();
    _commentController.dispose();
    _bidController.dispose();
    _reviewController.dispose();
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ============================================
  // API CALLS
  // ============================================
  
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    
    try {
      final productData = await _productRepository.getProductDetails(slug: widget.slug);
      
      if (productData.detailedProducts != null && productData.detailedProducts!.isNotEmpty) {
        _product = productData.detailedProducts![0];
        _productImages = _product!.getAllImageUrls();
        
        _startingBid = _product!.startingBid != null ? double.tryParse(_product!.startingBid!) ?? 0 : 0;
        _currentHighestBid = _product!.highestBid != null ? double.tryParse(_product!.highestBid!) ?? 0 : 0;
        _totalBids = 0;
        _highestBidder = '';
        _pointPerBid = (_product!.pointPerBid ?? 0).toDouble();
        _pointPerBidCustom = (_product!.pointPerBidCustom ?? 0).toDouble();
        _reviewsCount = _product!.ratingCount ?? 0;
        _rating = (_product!.rating ?? 0).toDouble();
        _isWishlisted = false;
        _isInWishlist = false;
        _endingSeconds = _product!.swipeLeft ?? 10;
        
        _minNextBidNow = _currentHighestBid + 0.01;
        _minNextBid = _currentHighestBid + 1;
        
        // Parse time left
        if (_product!.getAuctionEndDateTime() != null) {
          final endTime = _product!.getAuctionEndDateTime()!;
          final now = DateTime.now();
          _timeLeft = endTime.difference(now);
          if (_timeLeft.isNegative) _timeLeft = Duration.zero;
          _startCountdown(endTime);
        }
      }
      
      await _fetchComments();
      await _fetchReviews();
      await _fetchBidHistory();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchComments() async {
    try {
      final response = await _productRepository.getProductComments(_product?.id ?? 0);
      if (response.success == true && response.comments != null) {
        setState(() => _comments = response.comments!);
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }
  
  Future<void> _fetchReviews() async {
    try {
      final response = await _productRepository.getProductReviews(_product?.id ?? 0);
      if (response.success == true && response.reviews != null) {
        setState(() => _reviews = response.reviews!);
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }
  
  Future<void> _fetchBidHistory() async {
    try {
      final response = await _productRepository.getProductBidHistory(_product?.id ?? 0);
      if (response.success == true && response.bids != null) {
        setState(() => _bidHistory = response.bids!);
      }
    } catch (e) {
      print('Error fetching bid history: $e');
    }
  }
  
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _pollData();
    });
  }
  
  Future<void> _pollData() async {
    if (_product == null) return;
    
    try {
      final response = await _productRepository.pollProductData(_product!.id ?? 0);
      
      if (response.success == true) {
        // Update auction end date
        if (response.auction_end_date != null) {
          try {
            final newEndTime = DateTime.parse(response.auction_end_date!);
            final now = DateTime.now();
            final newTimeLeft = newEndTime.difference(now);
            if (_timeLeft != newTimeLeft && !newTimeLeft.isNegative) {
              setState(() => _timeLeft = newTimeLeft);
              _startCountdown(newEndTime);
            }
          } catch (e) {
            print('Error parsing auction end date: $e');
          }
        }
        
        // Update point per bid
        if (response.point_per_bid != null) {
          setState(() => _pointPerBid = response.point_per_bid!);
        }
        if (response.point_per_bid_custom != null) {
          setState(() => _pointPerBidCustom = response.point_per_bid_custom!);
        }
        
        // Check if auction ended and show winner popup
        if (response.auction_ended == true && response.winner != null && !_winnerModalShown) {
          _winnerData = response.winner;
          _winnerModalShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWinnerModalDialog();
          });
        }
        
        // Update ending soon status
        if (response.is_ending_soon == true && response.remaining_seconds != null) {
          if (!_isEndingSoon && response.remaining_seconds! <= _endingSeconds && response.remaining_seconds! > 0) {
            setState(() => _isEndingSoon = true);
            _playTickSound();
            _showToast('⚠️ Auction ending in $_endingSeconds seconds! ⚠️');
          }
        } else {
          if (_isEndingSoon) setState(() => _isEndingSoon = false);
        }
        
        // Update rating
        if (response.rating != null) {
          setState(() => _rating = response.rating!);
        }
        
        // Update review count
        if (response.reviews_count != null) {
          setState(() => _reviewsCount = response.reviews_count!);
        }
        
        // Update bid data
        if (response.bid_data != null) {
          final oldHighestBid = _currentHighestBid;
          final newHighestBid = response.highestBid ?? _currentHighestBid;
          final newTotalBids = response.totalBids ?? _totalBids;
          final newHighestBidder = response.lastBidderName ?? _highestBidder;

          setState(() {
            _currentHighestBid = newHighestBid;
            _totalBids = newTotalBids;
            _highestBidder = newHighestBidder;
          });

          if (_currentHighestBid > oldHighestBid) {
            _playBidSound();
            _showToast('${response.lastBidderName} placed a bid of ${_formatPrice(_currentHighestBid)}');
          }

          _minNextBidNow = _currentHighestBid + 0.01;
          _minNextBid = _currentHighestBid + 1;
          setState(() {});
        }
        
        // Update wishlist status
        if (response.is_in_wishlist != null) {
          if (_isInWishlist != response.is_in_wishlist!) {
            setState(() => _isInWishlist = response.is_in_wishlist!);
          }
        }
        
        // Refresh comments if HTML is provided
        if (response.comments_html != null && response.comments_html!.isNotEmpty) {
          await _fetchComments();
        }
        
        // Refresh reviews if HTML is provided
        if (response.reviews_html != null && response.reviews_html!.isNotEmpty) {
          await _fetchReviews();
        }
        
        // Refresh bid history if HTML is provided
        if (response.bid_history_html != null && response.bid_history_html!.isNotEmpty) {
          await _fetchBidHistory();
        }
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  
  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);
      
      if (remaining.isNegative) {
        timer.cancel();
        setState(() => _timeLeft = Duration.zero);
        return;
      }
      
      setState(() => _timeLeft = remaining);
    });
  }
  
  // ============================================
  // BID ACTIONS
  // ============================================
  
  Future<void> _placeBidNow() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    final amount = _minNextBidNow;
    _showLoadingDialog();
    
    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
      );
      
      if (mounted) Navigator.pop(context);
      
      if (response.success == true) {
        _playBidSound();
        if (response.time_extended == true) {
          _showToast(response.message ?? '⏰ Auction time extended!');
          if (response.new_end_date != null) {
            try {
              final newEndTime = DateTime.parse(response.new_end_date!);
              _startCountdown(newEndTime);
            } catch (e) {
              print('Error parsing new end date: $e');
            }
          }
        } else {
          _showToast(response.message ?? 'Bid placed! Amount: ${_formatPrice(amount)}');
        }
        
        await _pollData();
      } else {
        _showToast(response.message ?? 'Something went wrong');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showToast('Error placing bid: $e');
    }
  }

  Future<void> _submitCustomBid() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    final amount = double.tryParse(_bidController.text);
    if (amount == null) {
      _showToast('Please enter a valid amount');
      return;
    }
    if (amount < _minNextBidNow) {
      _showToast('Bid must be at least ${_formatPrice(_minNextBidNow)}');
      return;
    }
    
    _showLoadingDialog();
    
    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
      );
      
      Navigator.pop(context);
      
      if (response.success == true) {
        _playBidSound();
        _bidController.clear();
        if (response.time_extended == true) {
          _showToast(response.message ?? '⏰ Auction time extended!');
        } else {
          _showToast('Bid placed! Amount: ${_formatPrice(amount)}');
        }
        await _pollData();
      } else {
        _showToast(response.message ?? 'Error placing bid');
      }
    } catch (e) {
      Navigator.pop(context);
      _showToast('Error placing bid');
    }
  }
  
  // ============================================
  // COMMENT ACTIONS
  // ============================================
  
  Future<void> _sendComment() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      _showToast('Please enter a comment');
      return;
    }
    
    _showLoadingDialog();
    
    try {
      final response = await _productRepository.addProductComment(
        _product!.id ?? 0,
        comment,
      );
      
      Navigator.pop(context);
      
      if (response.success == true) {
        _playCommentSound();
        _commentController.clear();
        await _fetchComments();
        _showToast('Comment added!');
      } else {
        _showToast(response.message ?? 'Error adding comment');
      }
    } catch (e) {
      Navigator.pop(context);
      _showToast('Error adding comment');
    }
  }
  
  // ============================================
  // REVIEW ACTIONS
  // ============================================
  
  Future<void> _submitReview() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    if (_selectedRating == 0) {
      _showToast('Please select a rating');
      return;
    }
    
    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      _showToast('Please write a review');
      return;
    }
    
    _showLoadingDialog();
    
    try {
      final response = await _productRepository.addProductReview(
        _product!.id ?? 0,
        _selectedRating.toInt(),
        comment,
      );
      
      Navigator.pop(context);
      
      if (response.success == true) {
        _showToast('Review submitted!');
        _showAddReviewModal = false;
        _selectedRating = 0;
        _reviewController.clear();
        await _fetchReviews();
        await _pollData();
        setState(() {});
      } else {
        _showToast(response.message ?? 'Error submitting review');
      }
    } catch (e) {
      Navigator.pop(context);
      _showToast('Error submitting review');
    }
  }
  
  // ============================================
  // WISHLIST ACTIONS
  // ============================================
  
  Future<void> _toggleWishlist() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    try {
      if (_isInWishlist) {
        final response = await _productRepository.removeFromWishlist(_product!.id ?? 0);
        if (response.success == true) {
          setState(() => _isInWishlist = false);
          _showToast('Removed from wishlist');
        }
      } else {
        final response = await _productRepository.addToWishlist(_product!.id ?? 0);
        if (response.success == true) {
          setState(() => _isInWishlist = true);
          _showToast('Added to wishlist');
        }
      }
    } catch (e) {
      _showToast('Error updating wishlist');
    }
  }
  
  // ============================================
  // SOUND EFFECTS
  // ============================================
  
  void _playBidSound() {
    if (!_soundEnabled) return;
    // Play bid sound - can use AudioPlayers package
  }
  
  void _playCommentSound() {
    if (!_soundEnabled) return;
    // Play comment sound
  }
  
  void _playTickSound() {
    if (!_soundEnabled) return;
    // Play tick sound
  }
  
  // ============================================
  // UI HELPERS
  // ============================================
  
  String _formatPrice(double amount) {
    final symbol = _product?.currencySymbol ?? '\$';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
  String _formatTimeLeft() {
    if (_timeLeft.isNegative) return '00:00:00';
    
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);
    
    if (days > 0) {
      return '${days.toString().padLeft(2, '0')}d ${hours.toString().padLeft(2, '0')}h';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  Map<String, String> _getTimeComponents() {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);
    
    return {
      'days': days.toString().padLeft(2, '0'),
      'hours': hours.toString().padLeft(2, '0'),
      'minutes': minutes.toString().padLeft(2, '0'),
      'seconds': seconds.toString().padLeft(2, '0'),
    };
  }
  
  void _showToast(String message) {
    ToastComponent.showDialog(message);
  }
  
  void _showLoginRequired() {
    _showToast('Please login to continue');
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }
  
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Processing...'),
          ],
        ),
      ),
    );
  }
  
  void _shareProduct() {
    Share.share(_product?.link ?? AppConfig.RAW_BASE_URL);
  }
  
  void _showBidInputDialog() {
    _bidController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bid for Product', style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('Min bid amount: ${_formatPrice(_minNextBidNow)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitCustomBid();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: MyTheme.accent_color),
                  child: Text('Place Bid', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // ============================================
  // MODAL CONTROLS - keep same as before
  // ============================================
  
  void _openTitleModal() {
    setState(() => _showTitleModal = true);
  }
  
  void _closeTitleModal() {
    setState(() => _showTitleModal = false);
  }
  
  void _openReviewsModal() {
    setState(() => _showReviewsModal = true);
  }
  
  void _closeReviewsModal() {
    setState(() => _showReviewsModal = false);
  }
  
  void _openAddReviewModal() {
    _selectedRating = 0;
    _reviewController.clear();
    setState(() => _showAddReviewModal = true);
  }
  
  void _closeAddReviewModal() {
    setState(() => _showAddReviewModal = false);
  }
  
  void _openBidHistoryModal() {
    setState(() => _showBidHistoryModal = true);
  }
  
  void _closeBidHistoryModal() {
    setState(() => _showBidHistoryModal = false);
  }
  
  void _closeWinnerModal() {
    setState(() => _showWinnerModal = false);
  }
  
  // ============================================
  // BUILD METHODS - keep same as before
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 992;
    
    return Scaffold(
      backgroundColor: isDesktop ? Color(0xFFF5F7FA) : Colors.white,
      body: _isLoading
          ? _buildShimmerLoading()
          : isDesktop
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
    );
  }
  
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShimmerHelper().buildBasicShimmer(height: 375),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ShimmerHelper().buildBasicShimmer(height: 30, width: double.infinity),
                SizedBox(height: 10),
                ShimmerHelper().buildBasicShimmer(height: 20, width: 150),
                SizedBox(height: 10),
                ShimmerHelper().buildBasicShimmer(height: 50),
                SizedBox(height: 10),
                ShimmerHelper().buildBasicShimmer(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ============================================
  // MOBILE LAYOUT
  // ============================================
  
  Widget _buildMobileLayout() {
    final timeComponents = _getTimeComponents();
    
    return Stack(
      children: [
        CustomScrollView(
          controller: _mainScrollController,
          physics: BouncingScrollPhysics(),
          slivers: [
            // Image Sliver
            SliverAppBar(
              expandedHeight: 450,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 450,
                        viewportFraction: 1,
                        autoPlay: true,
                        onPageChanged: (index, reason) {
                          setState(() => _currentImageIndex = index);
                        },
                      ),
                      items: _productImages.map((image) {
                        return Builder(
                          builder: (context) => GestureDetector(
                            onTap: () => _showFullImage(image),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                    // Top Icons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left icons
                            Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.arrow_back,
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            // Right icons
                            Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.more_vert,
                                  onTap: () => setState(() => _showMoreMenu = !_showMoreMenu),
                                ),
                                SizedBox(width: 8),
                                _buildIconButton(
                                  icon: Icons.favorite_border,
                                  isActive: _isInWishlist,
                                  activeIcon: Icons.favorite,
                                  onTap: _toggleWishlist,
                                ),
                                SizedBox(width: 8),
                                _buildIconButton(
                                  icon: Icons.share,
                                  onTap: _shareProduct,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // More Menu
                    if (_showMoreMenu)
                      Positioned(
                        top: 70,
                        right: 16,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  icon: Icons.history,
                                  text: 'Bid History',
                                  onTap: () {
                                    setState(() => _showMoreMenu = false);
                                    _openBidHistoryModal();
                                  },
                                ),
                                _buildMenuItem(
                                  icon: Icons.info_outline,
                                  text: 'Product Details',
                                  onTap: () {
                                    setState(() => _showMoreMenu = false);
                                    _openTitleModal();
                                  },
                                ),
                                _buildMenuItem(
                                  icon: Icons.contact_mail,
                                  text: 'Contact Seller',
                                  onTap: () {
                                    setState(() => _showMoreMenu = false);
                                    // Navigate to contact seller
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Bottom Content Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Comments Section
                            Container(
                              width: MediaQuery.of(context).size.width * 0.75,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Comments (${_comments.length})', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text('Recent', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 80,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _comments.length > 3 ? 3 : _comments.length,
                                      itemBuilder: (context, index) {
                                        final comment = _comments[index];
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundImage: NetworkImage(comment.userAvatar ?? ''),
                                                child: comment.userAvatar == null ? Icon(Icons.person, size: 12) : null,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(comment.userName ?? 'User', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                                    Text(comment.comment ?? '', style: TextStyle(color: Colors.white70, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: TextField(
                                            controller: _commentController,
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                            decoration: InputDecoration(
                                              hintText: 'Add Comment...',
                                              hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _sendComment,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: MyTheme.accent_color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.send, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            // Title
                            GestureDetector(
                              onTap: _openTitleModal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_product?.name ?? '', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text(_product?.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '', style: TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Timer and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TIME LEFT', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildTimerUnit(timeComponents['days']!, 'd'),
                                        _buildTimerUnit(timeComponents['hours']!, 'h'),
                                        _buildTimerUnit(timeComponents['minutes']!, 'm'),
                                        _buildTimerUnit(timeComponents['seconds']!, 's'),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Current Bid', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      Text(_formatPrice(_currentHighestBid), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bid Info Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bid Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                      children: [
                        _buildInfoItem('Starting bid', _formatPrice(_startingBid)),
                        _buildInfoItem('Total bidders', '$_totalBids'),
                        _buildInfoItem('Highest bidder', _highestBidder.isNotEmpty ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***' : 'No bids'),
                        _buildInfoItem('Bid now at', '$_pointPerBid'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Reviews Section
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _openReviewsModal,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _rating.round() ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          SizedBox(width: 8),
                          Text(_rating.toStringAsFixed(1), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$_reviewsCount reviews', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            // Thumbnails
            SliverToBoxAdapter(
              child: Container(
                height: 70,
                margin: EdgeInsets.all(16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => _currentImageIndex = index),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentImageIndex == index ? MyTheme.accent_color : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_productImages[index], fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        // Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showBidInputDialog,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Custom'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _placeBidNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Bid Now - ${_formatPrice(_minNextBidNow)}', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimerUnit(String value, String label) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    IconData? activeIcon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(isActive ? activeIcon : icon, color: Colors.white, size: 20),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            SizedBox(width: 12),
            Text(text, style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
  
  // ============================================
  // DESKTOP LAYOUT (3-Column)
  // ============================================
  
  Widget _buildDesktopLayout() {
    final timeComponents = _getTimeComponents();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Image Gallery
        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Image
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100,
                  ),
                  child: GestureDetector(
                    onTap: () => _showFullImage(_productImages[_currentImageIndex]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _productImages[_currentImageIndex],
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Thumbnails
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _productImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _currentImageIndex = index),
                        child: Container(
                          width: 70,
                          height: 70,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _currentImageIndex == index ? MyTheme.accent_color : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(_productImages[index], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Column 2: Chat Section
        Expanded(
          child: Container(
            margin: EdgeInsets.only(top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Ask questions about this product', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // Messages List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final userIdStr = user_id.$?.toString() ?? '0';
                      final isOwn = comment.userId == int.tryParse(userIdStr);
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isOwn) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(comment.userAvatar ?? ''),
                                child: comment.userAvatar == null ? Icon(Icons.person, size: 16) : null,
                              ),
                              SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isOwn ? MyTheme.accent_color : Colors.grey.shade100,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                    bottomLeft: isOwn ? Radius.circular(12) : Radius.circular(4),
                                    bottomRight: isOwn ? Radius.circular(4) : Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isOwn)
                                      Text(comment.userName ?? 'User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                    Text(comment.comment ?? '', style: TextStyle(color: isOwn ? Colors.white : Colors.black87, fontSize: 13)),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        _formatTime(comment.createdAt),
                                        style: TextStyle(fontSize: 9, color: isOwn ? Colors.white70 : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isOwn) SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Input Area
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: null,
                            style: TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendComment,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MyTheme.accent_color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Column 3: Bidding & Details
          // Column 3: Bidding & Details
        Container(
          width: 320,
          margin: EdgeInsets.all(16),
          child: Column(
            children: [
              // Product Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _openTitleModal,
                      child: Text(_product?.name ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openTitleModal,
                      child: Text(
                        _product?.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Icons Row
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildDesktopIconButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: _shareProduct,
                        ),
                        _buildDesktopIconButton(
                          icon: _isInWishlist ? Icons.favorite : Icons.favorite_border,
                          label: _isInWishlist ? 'Saved' : 'Wishlist',
                          onTap: _toggleWishlist,
                          isActive: _isInWishlist,
                        ),
                        _buildDesktopIconButton(
                          icon: Icons.more_horiz,
                          label: 'More',
                          onTap: () => setState(() => _showDesktopMoreMenu = !_showDesktopMoreMenu),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Timer & Price
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TIME LEFT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                              Row(
                                children: [
                                  _buildDesktopTimerUnit(timeComponents['days']!, 'd'),
                                  _buildDesktopTimerUnit(timeComponents['hours']!, 'h'),
                                  _buildDesktopTimerUnit(timeComponents['minutes']!, 'm'),
                                  _buildDesktopTimerUnit(timeComponents['seconds']!, 's'),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Current Bid', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(_formatPrice(_currentHighestBid), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MyTheme.accent_color)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Bid Information Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bid Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _buildDesktopInfoItem('Starting bid', _formatPrice(_startingBid)),
                        _buildDesktopInfoItem('Total bidders', '$_totalBids'),
                        _buildDesktopInfoItem('Highest bidder', _highestBidder.isNotEmpty ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***' : 'No bids'),
                        _buildDesktopInfoItem('Bid now at', '$_pointPerBid'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Custom Bid Input
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter your bid amount (1 Bid = $_pointPerBidCustom)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bidController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submitCustomBid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyTheme.accent_color,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text('Place Bid', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Bid Now Button
              ElevatedButton(
                onPressed: _placeBidNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size(double.infinity, 0),
                ),
                child: Text('Bid Now - ${_formatPrice(_minNextBidNow)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              // Reviews Section
              GestureDetector(
                onTap: _openReviewsModal,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _rating.round() ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          SizedBox(width: 8),
                          Text(_rating.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Text('($_reviewsCount reviews)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? MyTheme.accent_color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey.shade600),
            SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDesktopTimerUnit(String value, String label) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }
  
  Widget _buildDesktopInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  // ============================================
  // MODAL DIALOGS
  // ============================================
  
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: BoxDecoration(color: Colors.black),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showProductDetailsModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_product?.name ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Html(data: _product?.description ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showReviewsModalDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('All Reviews ($_reviewsCount)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Reviews List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < (review.rating ?? 0) ? Icons.star : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                  SizedBox(width: 8),
                                  Text(_formatDate(review.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(review.comment ?? '', style: TextStyle(fontSize: 14)),
                              SizedBox(height: 4),
                              Text(review.userName ?? 'User', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Write Review Button
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddReviewModalDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: Text('Write a Review', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showAddReviewModalDialog() {
    double tempRating = 0;
    TextEditingController tempController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Rating', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 30,
                    itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      tempRating = rating;
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Review', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  TextField(
                    controller: tempController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this product...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (tempRating == 0) {
                        _showToast('Please select a rating');
                        return;
                      }
                      if (tempController.text.trim().isEmpty) {
                        _showToast('Please write a review');
                        return;
                      }
                      Navigator.pop(context);
                      _showLoadingDialog();
                      
                      try {
                        final response = await _productRepository.addProductReview(
                          _product!.id ?? 0,
                          tempRating.toInt(),
                          tempController.text,
                        );
                        Navigator.pop(context);
                        
                        if (response.success == true) {
                          _showToast('Review submitted!');
                          await _fetchReviews();
                          await _pollData();
                          setState(() {});
                        } else {
                          _showToast(response.message ?? 'Error submitting review');
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        _showToast('Error submitting review');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(double.infinity, 0),
                    ),
                    child: Text('Submit Review', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showBidHistoryModalDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bid History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Header Row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Bidder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.end)),
                  ],
                ),
              ),
              // Bid List
              Expanded(
                child: ListView.builder(
                  itemCount: _bidHistory.length,
                  itemBuilder: (context, index) {
                    final bid = _bidHistory[index];
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(bid.userName ?? 'User', style: TextStyle(fontSize: 13))),
                          Expanded(flex: 1, child: Text(_formatPrice(bid.amount ?? 0), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MyTheme.accent_color))),
                          Expanded(flex: 1, child: Text(_formatDateTime(bid.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.end)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showWinnerModalDialog() {
    if (_winnerData == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text('Auction Ended!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null ? Icon(Icons.person, size: 40) : null,
              ),
              SizedBox(height: 12),
              Text(_winnerData!.userName ?? 'Winner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 4),
              Text(_formatPrice(_winnerData!.amount ?? 0), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
              SizedBox(height: 12),
              Text('Congratulations to the winner!', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Close', style: TextStyle(color: MyTheme.accent_color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return '${diff.inSeconds}s ago';
    } catch (e) {
      return '';
    }
  }
  
  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return '';
    }
  }
  
  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return '';
    }
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}