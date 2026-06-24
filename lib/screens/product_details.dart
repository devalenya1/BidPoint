// product_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
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
import 'package:audioplayers/audioplayers.dart';
import '../data_model/auction_models.dart';

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/data_model/product_details_response.dart';
import 'package:active_ecommerce_flutter/helpers/main_helpers.dart';

class ProductDetails extends StatefulWidget {
  String slug;

  ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin, SingleTickerProviderStateMixin {
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
  int _endingSeconds = 10;

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Repository
  final ProductRepository _productRepository = ProductRepository();

  // Refresh indicator key
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Loading state for buttons
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mainScrollController = ScrollController();
    _fetchAllData();
    _startPolling();
    
    // Initialize audio player
    _audioPlayer.setReleaseMode(ReleaseMode.release);
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
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================
  // API CALLS
  // ============================================

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      final productData =
          await _productRepository.getProductDetails(slug: widget.slug);

      if (productData.detailedProducts != null &&
          productData.detailedProducts!.isNotEmpty) {
        _product = productData.detailedProducts![0];
        _productImages = _product!.getAllImageUrls();

        _startingBid = _product!.startingBid != null
            ? double.tryParse(_product!.startingBid!) ?? 0
            : 0;
        _currentHighestBid = _product!.highestBid != null
            ? double.tryParse(_product!.highestBid!) ?? 0
            : 0;
        
        _totalBids = _product!.totalBids ?? 0;
        _highestBidder = _product!.lastBidderName ?? '';
        
        _pointPerBid = (_product!.pointPerBid ?? 0).toDouble();
        _pointPerBidCustom = (_product!.pointPerBidCustom ?? 0).toDouble();
        _reviewsCount = _product!.ratingCount ?? 0;
        _rating = (_product!.rating ?? 0).toDouble();
        _isWishlisted = false;
        
        // FIX: Set _isInWishlist from the product data
        // The product data from API should contain isInWishlist field
        _isInWishlist = _product!.isInWishlist ?? false;
        
        // DEBUG: Print to verify
        print('Product: ${_product!.name}, isInWishlist: ${_product!.isInWishlist}');
        
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
      final response =
          await _productRepository.getProductComments(_product?.id ?? 0);
      if (response.success == true && response.comments != null) {
        setState(() => _comments = response.comments!);
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final response =
          await _productRepository.getProductReviews(_product?.id ?? 0);
      if (response.success == true && response.reviews != null) {
        setState(() => _reviews = response.reviews!);
        _reviewsCount = _reviews.length;
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> _fetchBidHistory() async {
    try {
      final response =
          await _productRepository.getProductBidHistory(_product?.id ?? 0);
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
      final response =
          await _productRepository.pollProductData(_product!.id ?? 0);

      if (response.success == true) {
        // ============================================
        // UPDATE BID DATA FROM POLL RESPONSE
        // ============================================
        
        // 1. Starting bid
        if (response.startingBid != null) {
          setState(() {
            _startingBid = response.startingBid!;
          });
        }

        // 2. Current highest bid
        if (response.highestBid != null) {
          final oldHighestBid = _currentHighestBid;
          setState(() {
            _currentHighestBid = response.highestBid!;
          });
          
          // Play sound if new bid is higher
          if (_currentHighestBid > oldHighestBid && response.lastBidderName != null) {
            _playBidSound();
            _showToast('${response.lastBidderName} placed a bid of ${_formatPrice(_currentHighestBid)}');
          }
        }

        // 3. Total bidders
        if (response.totalBids != null) {
          setState(() {
            _totalBids = response.totalBids!;
          });
        }

        // 4. Highest bidder (last_bidder_name)
        if (response.lastBidderName != null && response.lastBidderName!.isNotEmpty) {
          setState(() {
            _highestBidder = response.lastBidderName!;
          });
        }

        // 5. Point per bid
        if (response.pointPerBid != null) {
          setState(() {
            _pointPerBid = response.pointPerBid!;
          });
        }
        if (response.pointPerBidCustom != null) {
          setState(() {
            _pointPerBidCustom = response.pointPerBidCustom!;
          });
        }

        // Calculate min next bid
        _minNextBidNow = _currentHighestBid + 0.01;
        _minNextBid = _currentHighestBid + 1;
        setState(() {});

        // ============================================
        // UPDATE AUCTION END DATE
        // ============================================
        if (response.auctionEndDate != null) {
          try {
            final newEndTime = DateTime.parse(response.auctionEndDate!);
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

        // ============================================
        // CHECK AUCTION ENDED & SHOW WINNER
        // ============================================
        if (response.auctionEnded == true &&
            response.winner != null &&
            !_winnerModalShown) {
          _winnerData = response.winner;
          _winnerModalShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWinnerModalDialog();
          });
        }

        // ============================================
        // UPDATE ENDING SOON STATUS
        // ============================================
        if (response.isEndingSoon == true &&
            response.remainingSeconds != null) {
          if (!_isEndingSoon &&
              response.remainingSeconds! <= _endingSeconds &&
              response.remainingSeconds! > 0) {
            setState(() => _isEndingSoon = true);
            _playTickSound();
            _showToast('⚠️ Auction ending in $_endingSeconds seconds! ⚠️');
          }
        } else {
          if (_isEndingSoon) setState(() => _isEndingSoon = false);
        }

        // ============================================
        // UPDATE RATING & REVIEWS COUNT
        // ============================================
        if (response.rating != null) {
          setState(() => _rating = response.rating!);
        }
        if (response.reviewsCount != null) {
          setState(() => _reviewsCount = response.reviewsCount!);
        }

        // ============================================
        // UPDATE WISHLIST STATUS
        // ============================================
        if (response.isInWishlist != null) {
          final newWishlistState = response.isInWishlist!;
          if (_isInWishlist != newWishlistState) {
            setState(() {
              _isInWishlist = newWishlistState;
            });
          }
        }

        // ============================================
        // UPDATE COMMENTS (ALL COMMENTS)
        // ============================================
        if (response.comments != null && response.comments!.isNotEmpty) {
          setState(() => _comments = response.comments!);
        }

        // ============================================
        // UPDATE REVIEWS
        // ============================================
        if (response.reviews != null && response.reviews!.isNotEmpty) {
          setState(() => _reviews = response.reviews!);
          _reviewsCount = _reviews.length;
        }

        // ============================================
        // UPDATE BID HISTORY
        // ============================================
        if (response.bidHistory != null && response.bidHistory!.isNotEmpty) {
          // Convert BidHistoryItem to BidHistory for display
          final List<BidHistory> convertedBids = response.bidHistory!.map((item) {
            return BidHistory(
              userId: item.userId,
              userName: item.userName,
              amount: item.amount,
              createdAt: item.createdAt, // Keep the original format from API
            );
          }).toList();
          setState(() => _bidHistory = convertedBids);
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

      final totalSeconds = remaining.inSeconds;
      if (totalSeconds <= _endingSeconds && totalSeconds > 0 && !_isEndingSoon) {
        setState(() => _isEndingSoon = true);
        _playTickSound();
        _showToast('⚠️ Auction ending in $_endingSeconds seconds! ⚠️');
      } else if (totalSeconds > _endingSeconds && _isEndingSoon) {
        setState(() => _isEndingSoon = false);
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

    if (_isProcessing) return;

    final amount = _minNextBidNow;

    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (response.success == true) {
        _playBidSound();
        if (response.timeExtended == true) {
          _showToast(response.message ?? '⏰ Auction time extended!');
          if (response.newEndDate != null) {
            try {
              final newEndTime = DateTime.parse(response.newEndDate!);
              _startCountdown(newEndTime);
            } catch (e) {
              print('Error parsing new end date: $e');
            }
          }
        } else {
          _showToast(
              response.message ?? 'Bid placed! Amount: ${_formatPrice(amount)}');
        }

        await _pollData();
      } else {
        _showToast(response.message ?? 'Something went wrong');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _showToast('Error placing bid: $e');
    }
  }

  Future<void> _submitCustomBid() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }

    if (_isProcessing) return;

    final amount = double.tryParse(_bidController.text);
    if (amount == null) {
      _showToast('Please enter a valid amount');
      return;
    }
    if (amount < _minNextBidNow) {
      _showToast('Bid must be at least ${_formatPrice(_minNextBidNow)}');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (response.success == true) {
        _playBidSound();
        _bidController.clear();
        if (response.timeExtended == true) {
          _showToast(response.message ?? '⏰ Auction time extended!');
        } else {
          _showToast('Bid placed! Amount: ${_formatPrice(amount)}');
        }
        await _pollData();
      } else {
        _showToast(response.message ?? 'Error placing bid');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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

    if (_isProcessing) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      _showToast('Please enter a comment');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.addProductComment(
        _product!.id ?? 0,
        comment,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (response.success == true) {
        _playCommentSound();
        _commentController.clear();
        await _fetchComments();
        _showToast('Comment added!');
      } else {
        _showToast(response.message ?? 'Error adding comment');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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

    if (_isProcessing) return;

    if (_selectedRating == 0) {
      _showToast('Please select a rating');
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      _showToast('Please write a review');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.addProductReview(
        _product!.id ?? 0,
        _selectedRating.toInt(),
        comment,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _showToast('Error submitting review');
    }
  }

  // ============================================
  // WISHLIST ACTIONS - WITH SOUND
  // ============================================

  Future<void> _toggleWishlist() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_isInWishlist) {
        // PRODUCT IS IN WISHLIST - REMOVE IT
        final response = await _productRepository.removeFromWishlist(_product!.id ?? 0);
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        if (response.success == true) {
          setState(() => _isInWishlist = false);
          _playCommentSound();
          _showToast('Removed from wishlist');
          // Refresh wishlist status from server
          await _refreshWishlistStatus();
        } else {
          _showToast(response.message ?? 'Failed to remove from wishlist');
        }
      } else {
        // PRODUCT IS NOT IN WISHLIST - ADD IT
        final response = await _productRepository.addToWishlist(_product!.id ?? 0);
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        if (response.success == true) {
          setState(() => _isInWishlist = true);
          _playBidSound();
          _showToast('Added to wishlist');
          // Refresh wishlist status from server
          await _refreshWishlistStatus();
        } else {
          _showToast(response.message ?? 'Failed to add to wishlist');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _showToast('Error updating wishlist');
    }
  }

  // FIX: Add this method to refresh wishlist status
  Future<void> _refreshWishlistStatus() async {
    try {
      final response = await _productRepository.pollProductData(_product!.id ?? 0);
      if (response.success == true && response.isInWishlist != null) {
        setState(() {
          _isInWishlist = response.isInWishlist!;
        });
      }
    } catch (e) {
      print('Error refreshing wishlist status: $e');
    }
  }

  // ============================================
  // CONTACT SELLER
  // ============================================

  Future<void> _contactSeller() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.contactSeller(
        _product!.id ?? 0,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (response['success'] == true) {
        _showToast(response['message'] ?? 'Message sent to seller!');
      } else {
        _showToast(response['message'] ?? 'Failed to contact seller');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _showToast('Error contacting seller');
    }
  }

  // ============================================
  // SOUND EFFECTS
  // ============================================

  void _playBidSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/bid_notification.wav'));
    } catch (e) {
      print('Error playing bid sound: $e');
    }
  }

  void _playCommentSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/comment_sound.wav'));
    } catch (e) {
      print('Error playing comment sound: $e');
    }
  }

  void _playTickSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/tick_clock.mp3'));
    } catch (e) {
      print('Error playing tick sound: $e');
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================

  String _formatPrice(double amount) {
    return FormatHelper.formatPrice(amount);
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

  // Button loader widget matching HotAuctionCard style
  Widget _buildButtonLoader() {
    return const SizedBox(
      height: 16,
      width: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }

  void _shareProduct() {
    Share.share(_product?.link ?? AppConfig.RAW_BASE_URL);
  }

  // ============================================
  // CUSTOM BID POPUP
  // ============================================

  void _showBidInputDialog() {
    _bidController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bid for Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Min bid amount: ${_formatPrice(_minNextBidNow)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text('1 Bid = $_pointPerBidCustom',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          Navigator.pop(context);
                          _submitCustomBid();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyTheme.accent_color,
                    minimumSize: const Size(80, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? _buildButtonLoader()
                      : Text(
                          'Place Bid',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MODAL CONTROLS
  // ============================================

  void _openTitleModal() {
    setState(() => _showTitleModal = true);
    _showProductDetailsModal();
  }

  void _openReviewsModal() {
    setState(() => _showReviewsModal = true);
    _showReviewsModalDialog();
  }

  void _openAddReviewModal() {
    _selectedRating = 0;
    _reviewController.clear();
    setState(() => _showAddReviewModal = true);
    _showAddReviewModalDialog();
  }

  void _openBidHistoryModal() {
    setState(() => _showBidHistoryModal = true);
    _showBidHistoryModalDialog();
  }

  void _closeWinnerModal() {
    setState(() => _showWinnerModal = false);
  }

  // ============================================
  // MODAL DIALOGS
  // ============================================

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
                  Text('Product Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Text(_product?.name ?? '',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
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
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('All Reviews ($_reviewsCount)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _reviews.isEmpty
                        ? Center(child: Text('No reviews yet'))
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade100)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5,
                                              (starIndex) {
                                            return Icon(
                                              starIndex < (review.rating ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 14,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                        SizedBox(width: 8),
                                        Text(_formatDate(review.createdAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(review.comment ?? '',
                                        style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text(review.userName ?? 'User',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              Navigator.pop(context);
                              _showAddReviewModalDialog();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              'Write a Review',
                              style: TextStyle(color: Colors.white),
                            ),
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
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Write a Review',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
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
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (tempRating == 0) {
                              _showToast('Please select a rating');
                              return;
                            }
                            if (tempController.text.trim().isEmpty) {
                              _showToast('Please write a review');
                              return;
                            }
                            Navigator.pop(context);
                            setState(() => _isProcessing = true);

                            try {
                              final response =
                                  await _productRepository.addProductReview(
                                _product!.id ?? 0,
                                tempRating.toInt(),
                                tempController.text,
                              );

                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }

                              if (response.success == true) {
                                _showToast('Review submitted!');
                                await _fetchReviews();
                                await _pollData();
                                setState(() {});
                              } else {
                                _showToast(response.message ?? 'Error submitting review');
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                              _showToast('Error submitting review');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(double.infinity, 0),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            'Submit Review',
                            style: TextStyle(color: Colors.white),
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

  void _showBidHistoryModalDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
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
                    Text('Bid History',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('Bidder',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(
                        flex: 1,
                        child: Text('Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(
                        flex: 1,
                        child: Text('Date & Time',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.end)),
                  ],
                ),
              ),
              Expanded(
                child: _bidHistory.isEmpty
                    ? Center(child: Text('No bids yet'))
                    : ListView.builder(
                        itemCount: _bidHistory.length,
                        itemBuilder: (context, index) {
                          final bid = _bidHistory[index];
                          return Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(bid.userName ?? 'User',
                                        style: TextStyle(fontSize: 13))),
                                Expanded(
                                    flex: 1,
                                    child: Text(_formatPrice(bid.amount ?? 0),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: MyTheme.accent_color))),
                                Expanded(
                                    flex: 1,
                                    child: Text(
                                        _formatDateTime(bid.createdAt),
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                        textAlign: TextAlign.end)),
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
              Text('Auction Ended!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null
                    ? Icon(Icons.person, size: 40)
                    : null,
              ),
              SizedBox(height: 12),
              Text(_winnerData!.userName ?? 'Winner',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 4),
              Text(_formatPrice(_winnerData!.amount ?? 0),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
              SizedBox(height: 12),
              Text('Congratulations to the winner!',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Close',
                    style: TextStyle(color: MyTheme.accent_color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    if (dateTime == null || dateTime.isEmpty) return '';
    // The API already returns formatted dates like "01 Jun 2026, 06:12 AM"
    // Just return it as-is
    return dateTime;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 992;

    return Scaffold(
      backgroundColor: isDesktop ? Color(0xFFF5F7FA) : Colors.white,
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _fetchAllData,
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
    );
  }

  // ============================================
  // SHIMMER LOADING
  // ============================================

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
                ShimmerHelper().buildBasicShimmer(
                    height: 30, width: double.infinity),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.65;

    return Stack(
      children: [
        CustomScrollView(
          controller: _mainScrollController,
          physics: BouncingScrollPhysics(),
          slivers: [
            // Image Sliver - 65% of screen height
            SliverAppBar(
              expandedHeight: imageHeight,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: imageHeight,
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
                          stops: [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    // Top Icons - Vertical Right Icons
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconCircle(
                            icon: Icons.more_vert,
                            onTap: () =>
                                setState(() => _showMoreMenu = !_showMoreMenu),
                            isLoading: _isProcessing,
                          ),
                          SizedBox(height: 12),
                          // FIX 4 & 5: Wishlist icon with sound
                          _buildIconCircle(
                            icon: _isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            isActive: _isInWishlist,
                            onTap: _toggleWishlist,
                            isLoading: _isProcessing,
                          ),
                          SizedBox(height: 12),
                          _buildIconCircle(
                            icon: Icons.share,
                            onTap: _shareProduct,
                            isLoading: false,
                          ),
                        ],
                      ),
                    ),
                    // Left Icons - Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: _buildIconCircle(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                        isLoading: false,
                      ),
                    ),
                    // More Menu
                    if (_showMoreMenu)
                      Positioned(
                        top: 80,
                        right: 16,
                        child: Material(
                          elevation: 10,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMoreMenuItem(
                                  icon: Icons.history,
                                  text: 'Bid History',
                                  onTap: () {
                                    setState(() => _showMoreMenu = false);
                                    _openBidHistoryModal();
                                  },
                                ),
                                _buildMoreMenuItem(
                                  icon: Icons.info_outline,
                                  text: 'Product Details',
                                  onTap: () {
                                    setState(() => _showMoreMenu = false);
                                    _openTitleModal();
                                  },
                                ),
                                _buildMoreMenuItem(
                                  icon: Icons.contact_mail,
                                  text: _isProcessing ? 'Contacting...' : 'Contact Seller',
                                  onTap: _isProcessing ? null : () {
                                    setState(() => _showMoreMenu = false);
                                    _contactSeller();
                                  },
                                ),
                                // _buildMoreMenuItem(
                                //   icon: Icons.share,
                                //   text: 'Share',
                                //   onTap: () {
                                //     setState(() => _showMoreMenu = false);
                                //     _shareProduct();
                                //   },
                                // ),
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
                            // Comments Section - SHOW ALL COMMENTS
                            Container(
                              width: MediaQuery.of(context).size.width * 0.75,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Comment count header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Text(
                                      //   'Comments (${_comments.length})',
                                      //   style: TextStyle(
                                      //     color: Colors.white,
                                      //     fontSize: 12,
                                      //     fontWeight: FontWeight.w600,
                                      //   ),
                                      // ),
                                      // Text(
                                      //   'Recent',
                                      //   style: TextStyle(
                                      //     color: Colors.white70,
                                      //     fontSize: 10,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  // Reduced height comments list - from imageHeight * 0.5 to imageHeight * 0.3
                                  Container(
                                    height: imageHeight * 0.4, // Reduced from 0.5 to 0.3
                                    child: _comments.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No comments yet',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _comments.length,
                                            itemBuilder: (context, index) {
                                              final comment = _comments[index];
                                              return Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 6), // Reduced from 8 to 6
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12, // Reduced from 12 to 10
                                                      backgroundImage:
                                                          NetworkImage(comment
                                                                  .userAvatar ??
                                                              ''),
                                                      child: comment
                                                              .userAvatar ==
                                                          null
                                                          ? Icon(Icons.person,
                                                              size: 12, // Reduced from 12 to 10
                                                              color: Colors
                                                                  .white54)
                                                          : null,
                                                    ),
                                                    SizedBox(width: 8), // Reduced from 8 to 6
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            comment.userName ??
                                                                'User',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 11, // Reduced from 11 to 10
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          Text(
                                                            comment.comment ??
                                                                '',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 10, // Reduced from 10 to 9
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  SizedBox(height: 4), // Reduced from 8 to 4
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: TextField(
                                            controller: _commentController,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11), // Reduced from 12 to 11
                                            decoration: InputDecoration(
                                              hintText: 'Add Comment...',
                                              hintStyle: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11), // Reduced from 12 to 11
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10, // Reduced from 12 to 10
                                                      vertical: 6), // Reduced from 8 to 6
                                            ),
                                            onSubmitted: (value) =>
                                                _sendComment(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6), // Reduced from 8 to 6
                                      GestureDetector(
                                        onTap: _isProcessing ? null : _sendComment,
                                        child: Container(
                                          width: 28, // Reduced from 32 to 28
                                          height: 28, // Reduced from 32 to 28
                                          decoration: BoxDecoration(
                                            color: MyTheme.accent_color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: _isProcessing
                                              ? const SizedBox(
                                                  height: 12, // Reduced from 14 to 12
                                                  width: 12, // Reduced from 14 to 12
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Icon(Icons.send,
                                                  size: 14, // Reduced from 16 to 14
                                                  color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            // Product name and description
                            GestureDetector(
                              onTap: _openTitleModal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_product?.name ?? '',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text(
                                      _product?.description
                                              ?.replaceAll(RegExp(r'<[^>]*>'),
                                                  '') ??
                                          '',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
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
                                    Text('TIME LEFT',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildTimerUnitBig(
                                            timeComponents['days']!, 'd'),
                                        _buildTimerUnitBig(
                                            timeComponents['hours']!, 'h'),
                                        _buildTimerUnitBig(
                                            timeComponents['minutes']!, 'm'),
                                        _buildTimerUnitBig(
                                            timeComponents['seconds']!, 's'),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Current Bid',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      Text(_formatPrice(_currentHighestBid),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
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
            // Bid Info Section - Updated from polling data
            SliverToBoxAdapter(
              child: Material(
                
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    // elevation: 40, // Creates shadow and lifts above other elements
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bid Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3,
                        children: [
                          _buildInfoItem('Starting bid',
                              _formatPrice(_startingBid)),
                          _buildInfoItem('Total bidders', '$_totalBids'),
                          _buildInfoItem(
                              'Highest bidder',
                              _highestBidder.isNotEmpty
                                  ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                  : 'No bids'),
                          _buildInfoItem('Bid now at', '$_pointPerBid'),
                        ],
                      ),
                    ],
                  ),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          SizedBox(width: 8),
                          Text(_rating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$_reviewsCount reviews',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
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
                      onTap: () {
                        setState(() => _currentImageIndex = index);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentImageIndex == index
                                ? MyTheme.accent_color
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _productImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image, color: Colors.grey),
                          ),
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showBidInputDialog,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Custom'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _placeBidNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            'Bid Now - ${_formatPrice(_minNextBidNow)}',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // MOBILE WIDGETS
  // ============================================

  Widget _buildIconCircle({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MyTheme.accent_color,
                ),
              )
            : Icon(
                icon,
                color: isActive ? MyTheme.accent_color : Colors.black87,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
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
            Icon(icon, size: 18, color: Colors.grey.shade700),
            SizedBox(width: 12),
            Text(text,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerUnitBig(String value, String label) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
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
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.white70, fontSize: 10)),
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
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================
  // DESKTOP LAYOUT
  // ============================================

  Widget _buildDesktopLayout() {
    final timeComponents = _getTimeComponents();

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Image Gallery
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade100,
                      ),
                      child: GestureDetector(
                        onTap: () => _showFullImage(
                            _productImages[_currentImageIndex]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _productImages[_currentImageIndex],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image,
                                    size: 80, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _productImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currentImageIndex = index),
                            child: Container(
                              width: 70,
                              height: 70,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _currentImageIndex == index
                                      ? MyTheme.accent_color
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _productImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.broken_image,
                                          color: Colors.grey),
                                ),
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
            SizedBox(width: 16),
            // Column 2: Chat Section
            Expanded(
              flex: 2,
              child: Container(
                height: MediaQuery.of(context).size.height - 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comments',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Ask questions about this product',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final userIdStr = user_id.$?.toString() ?? '0';
                          final isOwn =
                              comment.userId == int.tryParse(userIdStr);

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isOwn
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOwn) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(
                                        comment.userAvatar ?? ''),
                                    child: comment.userAvatar == null
                                        ? Icon(Icons.person, size: 16,
                                            color: Colors.grey)
                                        : null,
                                  ),
                                  SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isOwn
                                          ? MyTheme.accent_color
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                        bottomLeft: isOwn
                                            ? Radius.circular(12)
                                            : Radius.circular(4),
                                        bottomRight: isOwn
                                            ? Radius.circular(4)
                                            : Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwn)
                                          Text(comment.userName ?? 'User',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey
                                                      .shade600)),
                                        Text(comment.comment ?? '',
                                            style: TextStyle(
                                                color: isOwn
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 13)),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            _formatTime(comment.createdAt),
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: isOwn
                                                    ? Colors.white70
                                                    : Colors.grey),
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
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _commentController,
                                maxLines: null,
                                style: TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle:
                                      TextStyle(fontSize: 14, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (value) => _sendComment(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: _isProcessing ? null : _sendComment,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                shape: BoxShape.circle,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.send,
                                      color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            // Column 3: Bidding & Details
            Expanded(
              flex: 1,
              child: Container(
                width: 320,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _openTitleModal,
                            child: Text(_product?.name ?? '',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: _openTitleModal,
                            child: Text(
                              _product?.description
                                      ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                                  '',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildDesktopIconButton(
                                icon: Icons.share,
                                label: 'Share',
                                onTap: _shareProduct,
                              ),
                              _buildDesktopIconButton(
                                icon: _isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: _isInWishlist ? 'Saved' : 'Wishlist',
                                onTap: _toggleWishlist,
                                isActive: _isInWishlist,
                              ),
                              _buildDesktopIconButton(
                                icon: Icons.more_horiz,
                                label: 'More',
                                onTap: () => setState(() =>
                                    _showDesktopMoreMenu =
                                        !_showDesktopMoreMenu),
                              ),
                            ],
                          ),
                          if (_showDesktopMoreMenu)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDesktopMenuItem(
                                    icon: Icons.history,
                                    text: 'Bid History',
                                    onTap: () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _openBidHistoryModal();
                                    },
                                  ),
                                  _buildDesktopMenuItem(
                                    icon: Icons.info_outline,
                                    text: 'Product Details',
                                    onTap: () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _openTitleModal();
                                    },
                                  ),
                                  _buildDesktopMenuItem(
                                    icon: Icons.contact_mail,
                                    text: _isProcessing ? 'Contacting...' : 'Contact Seller',
                                    onTap: _isProcessing ? null : () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _contactSeller();
                                    },
                                  ),
                                ],
                              ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('TIME LEFT',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500)),
                                    Row(
                                      children: [
                                        _buildDesktopTimerUnit(
                                            timeComponents['days']!, 'd'),
                                        _buildDesktopTimerUnit(
                                            timeComponents['hours']!, 'h'),
                                        _buildDesktopTimerUnit(
                                            timeComponents['minutes']!, 'm'),
                                        _buildDesktopTimerUnit(
                                            timeComponents['seconds']!, 's'),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Current Bid',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text(_formatPrice(_currentHighestBid),
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: MyTheme.accent_color)),
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
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bid Information',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                            children: [
                              _buildDesktopInfoItem('Starting bid',
                                  _formatPrice(_startingBid)),
                              _buildDesktopInfoItem('Total bidders',
                                  '$_totalBids'),
                              _buildDesktopInfoItem(
                                  'Highest bidder',
                                  _highestBidder.isNotEmpty
                                      ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                      : 'No bids'),
                              _buildDesktopInfoItem('Bid now at',
                                  '$_pointPerBid'),
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
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Enter your bid amount (1 Bid = $_pointPerBidCustom)',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isProcessing ? null : _submitCustomBid,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyTheme.accent_color,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                child: _isProcessing
                                    ? _buildButtonLoader()
                                    : Text('Place Bid',
                                        style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Bid Now Button
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _placeBidNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              'Bid Now - ${_formatPrice(_minNextBidNow)}',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
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
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < _rating.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 14,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                SizedBox(width: 8),
                                Text(_rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Text('($_reviewsCount reviews)',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
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
    );
  }

  // ============================================
  // DESKTOP WIDGETS
  // ============================================

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
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : Colors.grey.shade600),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            SizedBox(width: 12),
            Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
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
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey)),
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
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}