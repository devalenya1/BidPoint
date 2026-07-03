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
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  bool _isListening = false;
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
    
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    _setupLoginStateListener();
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
        _isInWishlist = false;
        _endingSeconds = _product!.swipeLeft ?? 10;

        _minNextBidNow = _currentHighestBid + 0.01;
        _minNextBid = _currentHighestBid + 1;

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
      await _fetchWishlistStatus();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching data: $e');
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_product_details);
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
        if (response.startingBid != null) {
          setState(() { _startingBid = response.startingBid!; });
        }

        if (response.highestBid != null) {
          final oldHighestBid = _currentHighestBid;
          setState(() { _currentHighestBid = response.highestBid!; });
          
          if (_currentHighestBid > oldHighestBid && response.lastBidderName != null) {
            _playBidSound();
            ToastComponent.showInfo(
              '${response.lastBidderName} ${AppLocalizations.of(context)!.placed_a_bid_of} ${_formatPrice(_currentHighestBid)}',
            );
          }
        }

        if (response.totalBids != null) {
          setState(() { _totalBids = response.totalBids!; });
        }

        if (response.lastBidderName != null && response.lastBidderName!.isNotEmpty) {
          setState(() { _highestBidder = response.lastBidderName!; });
        }

        if (response.pointPerBid != null) {
          setState(() { _pointPerBid = response.pointPerBid!; });
        }
        if (response.pointPerBidCustom != null) {
          setState(() { _pointPerBidCustom = response.pointPerBidCustom!; });
        }

        _minNextBidNow = _currentHighestBid + 0.01;
        _minNextBid = _currentHighestBid + 1;
        setState(() {});

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

        if (response.auctionEnded == true &&
            response.winner != null &&
            !_winnerModalShown) {
          _winnerData = response.winner;
          _winnerModalShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWinnerModalDialog();
          });
        }

        if (response.isEndingSoon == true &&
            response.remainingSeconds != null) {
          if (!_isEndingSoon &&
              response.remainingSeconds! <= _endingSeconds &&
              response.remainingSeconds! > 0) {
            setState(() => _isEndingSoon = true);
            _playTickSound();
            ToastComponent.showWarning(
              '⚠️ ${AppLocalizations.of(context)!.auction_ending_in} $_endingSeconds ${AppLocalizations.of(context)!.seconds}! ⚠️'
            );
          }
        } else {
          if (_isEndingSoon) setState(() => _isEndingSoon = false);
        }

        if (response.rating != null) {
          setState(() { _rating = response.rating!; });
        }
        if (response.reviewsCount != null) {
          setState(() { _reviewsCount = response.reviewsCount!; });
        }

        if (response.comments != null && response.comments!.isNotEmpty) {
          setState(() => _comments = response.comments!);
        }

        if (response.reviews != null && response.reviews!.isNotEmpty) {
          setState(() => _reviews = response.reviews!);
          _reviewsCount = _reviews.length;
        }

        if (response.bidHistory != null && response.bidHistory!.isNotEmpty) {
          final List<BidHistory> convertedBids = response.bidHistory!.map((item) {
            return BidHistory(
              userId: item.userId,
              userName: item.userName,
              amount: item.amount,
              createdAt: item.createdAt,
            );
          }).toList();
          setState(() => _bidHistory = convertedBids);
        }
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  void _checkAndRefreshWishlist() {
    if (_product != null && is_logged_in.$ && !_isLoading && !_isProcessing) {
      print('✅ Checking wishlist status on page focus...');
      _fetchWishlistStatus();
    } else {
      print('⏭️ Skipping wishlist refresh: product=${_product != null}, loggedIn=${is_logged_in.$}, loading=$_isLoading, processing=$_isProcessing');
    }
  }

  void _setupLoginStateListener() {
    if (!_isListening) {
      _isListening = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRefreshWishlist();
    });
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
        ToastComponent.showWarning(
          '⚠️ ${AppLocalizations.of(context)!.auction_ending_in} $_endingSeconds ${AppLocalizations.of(context)!.seconds}! ⚠️'
        );
      } else if (totalSeconds > _endingSeconds && _isEndingSoon) {
        setState(() => _isEndingSoon = false);
      }

      setState(() => _timeLeft = remaining);
    });
  }

  Future<void> _likeComment(int commentId) async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    
    try {
      final response = await _productRepository.likeProductComment(commentId);
      if (response['success'] == true) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == commentId);
          if (index != -1) {
            _comments[index].likes = response['data']['likes'].toString();
          }
        });
        ToastComponent.showSuccess(AppLocalizations.of(context)!.comment_liked);
      }
    } catch (e) {
      print('Error liking comment: $e');
    }
  }

  void _replyToComment(String userName) {
    _commentController.text = '@$userName ';
    FocusScope.of(context).requestFocus(FocusNode());
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
          ToastComponent.showSuccess(response.message ?? AppLocalizations.of(context)!.auction_time_extended);
          if (response.newEndDate != null) {
            try {
              final newEndTime = DateTime.parse(response.newEndDate!);
              _startCountdown(newEndTime);
            } catch (e) {
              print('Error parsing new end date: $e');
            }
          }
        } else {
          ToastComponent.showSuccess(
              response.message ?? '${AppLocalizations.of(context)!.bid_placed} ${AppLocalizations.of(context)!.amount_ucf}: ${_formatPrice(amount)}');
        }

        await _pollData();
      } else {
        ToastComponent.showError(response.message ?? AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      ToastComponent.showError(AppLocalizations.of(context)!.error_placing_bid);
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
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_valid_amount);
      return;
    }
    if (amount < _minNextBidNow) {
      ToastComponent.showWarning('${AppLocalizations.of(context)!.bid_must_be_at_least} ${_formatPrice(_minNextBidNow)}');
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
          ToastComponent.showSuccess(response.message ?? AppLocalizations.of(context)!.auction_time_extended);
        } else {
          ToastComponent.showSuccess('${AppLocalizations.of(context)!.bid_placed} ${AppLocalizations.of(context)!.amount_ucf}: ${_formatPrice(amount)}');
        }
        await _pollData();
      } else {
        ToastComponent.showError(response.message ?? AppLocalizations.of(context)!.error_placing_bid);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      ToastComponent.showError(AppLocalizations.of(context)!.error_placing_bid);
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
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_enter_comment);
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
        ToastComponent.showSuccess(AppLocalizations.of(context)!.comment_added);
      } else {
        ToastComponent.showError(response.message ?? AppLocalizations.of(context)!.error_adding_comment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      ToastComponent.showError(AppLocalizations.of(context)!.error_adding_comment);
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
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_select_rating);
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.please_write_review);
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
        ToastComponent.showSuccess(AppLocalizations.of(context)!.review_submitted);
        _showAddReviewModal = false;
        _selectedRating = 0;
        _reviewController.clear();
        await _fetchReviews();
        await _pollData();
        setState(() {});
      } else {
        ToastComponent.showError(response.message ?? AppLocalizations.of(context)!.error_submitting_review);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      ToastComponent.showError(AppLocalizations.of(context)!.error_submitting_review);
    }
  }

  // ============================================
  // WISHLIST STATUS - DEDICATED ENDPOINT
  // ============================================

  Future<void> _fetchWishlistStatus() async {
    if (!is_logged_in.$) {
      setState(() { _isInWishlist = false; });
      return;
    }
    
    if (_product == null) {
      return;
    }
    
    try {
      print('🔄 Fetching wishlist status from dedicated endpoint...');
      final result = await _productRepository.getWishlistStatus(_product!.id ?? 0);
      
      print('📡 Wishlist status response: $result');
      
      if (result['success'] == true) {
        final newState = result['isInWishlist'] ?? false;
        if (_isInWishlist != newState) {
          setState(() { _isInWishlist = newState; });
          print('✅ Updated wishlist to: $_isInWishlist');
        }
      } else {
        print('❌ Failed to get wishlist status: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error fetching wishlist status: $e');
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

    final wasInWishlist = _isInWishlist;
    
    setState(() {
      _isProcessing = true;
      _isInWishlist = !wasInWishlist;
    });

    try {
      late WishlistResponse response;
      
      if (wasInWishlist) {
        print('🗑️ Removing from wishlist...');
        response = await _productRepository.removeFromWishlist(_product!.id ?? 0);
      } else {
        print('❤️ Adding to wishlist...');
        response = await _productRepository.addToWishlist(_product!.id ?? 0);
      }

      print('📡 Response success: ${response.success}');
      print('📡 Response message: ${response.message}');

      if (response.success == true) {
        if (wasInWishlist) {
          _playCommentSound();
          ToastComponent.showSuccess(AppLocalizations.of(context)!.removed_from_wishlist);
        } else {
          _playBidSound();
          ToastComponent.showSuccess(AppLocalizations.of(context)!.added_to_wishlist);
        }
        
        await _fetchWishlistStatus();
      } else {
        setState(() { _isInWishlist = wasInWishlist; });
        
        print('❌ Wishlist operation failed: ${response.message}');
        ToastComponent.showError(AppLocalizations.of(context)!.wishlist_update_failed);
        
        await _fetchWishlistStatus();
      }
    } catch (e) {
      print('❌ Wishlist error: $e');
      setState(() { _isInWishlist = wasInWishlist; });
      ToastComponent.showError(AppLocalizations.of(context)!.wishlist_update_failed);
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  Future<void> _refreshWishlistStatus() async {
    if (_product == null) {
      print('⏭️ Cannot refresh wishlist: product is null');
      return;
    }
    
    if (!is_logged_in.$) {
      print('⏭️ Cannot refresh wishlist: user not logged in');
      return;
    }
    
    try {
      print('🔄 Refreshing wishlist status for product ${_product!.id}...');
      final response = await _productRepository.pollProductData(_product!.id ?? 0);
      print('📡 Poll response success: ${response.success}');
      print('📡 Poll response isInWishlist: ${response.isInWishlist}');
      
      if (response.success == true && response.isInWishlist != null) {
        final newState = response.isInWishlist!;
        if (_isInWishlist != newState) {
          setState(() { _isInWishlist = newState; });
          print('✅ Updated _isInWishlist to: $_isInWishlist');
        } else {
          print('✅ _isInWishlist already set to: $_isInWishlist');
        }
      } else {
        print('❌ Failed to refresh wishlist status');
      }
    } catch (e) {
      print('❌ Error refreshing wishlist status: $e');
    }
  }

  // ============================================
  // CONTACT SELLER - Redirect to Messenger List on Success
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
        ToastComponent.showSuccess(response['message'] ?? AppLocalizations.of(context)!.message_sent_to_seller);
        
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => MessengerList())
              );
            }
          });
        }
      } else {
        ToastComponent.showError(response['message'] ?? AppLocalizations.of(context)!.failed_to_contact_seller);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      ToastComponent.showError(AppLocalizations.of(context)!.error_contacting_seller);
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

  void _showLoginRequired() {
    ToastComponent.showWarning(AppLocalizations.of(context)!.please_login_to_continue);
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }

  Widget _buildButtonLoader() {
    return SizedBox(
      height: 16.w,
      width: 16.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.w,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.enter_your_bid,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              '${AppLocalizations.of(context)!.one_bid_equals} $_pointPerBidCustom',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '${AppLocalizations.of(context)!.min_ucf}: ${_formatPrice(_minNextBidNow)}',
                hintStyle: TextStyle(fontSize: 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel_ucf,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            Navigator.pop(context);
                            _submitCustomBid();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            AppLocalizations.of(context)!.place_bid,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.product_details,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 1.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product?.name ?? '',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12.h),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.all_reviews} ($_reviewsCount)',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 24.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _reviews.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context)!.no_reviews_yet, style: TextStyle(fontSize: 14.sp)))
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (starIndex) {
                                            return Icon(
                                              starIndex < (review.rating ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 14.sp,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          _formatDate(review.createdAt),
                                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      review.comment ?? '',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      review.userName ?? AppLocalizations.of(context)!.user_ucf,
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.w)),
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
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              AppLocalizations.of(context)!.write_a_review,
                              style: TextStyle(fontSize: 14.sp, color: Colors.white),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.write_a_review,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 24.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(AppLocalizations.of(context)!.rating_ucf, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.h),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 30.w,
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      tempRating = rating;
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(AppLocalizations.of(context)!.review_ucf, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: tempController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.share_experience_hint,
                      hintStyle: TextStyle(fontSize: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (tempRating == 0) {
                              ToastComponent.showWarning(AppLocalizations.of(context)!.please_select_rating);
                              return;
                            }
                            if (tempController.text.trim().isEmpty) {
                              ToastComponent.showWarning(AppLocalizations.of(context)!.please_write_review);
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
                                ToastComponent.showSuccess(AppLocalizations.of(context)!.review_submitted);
                                await _fetchReviews();
                                await _pollData();
                                setState(() {});
                              } else {
                                ToastComponent.showError(response.message ?? AppLocalizations.of(context)!.error_submitting_review);
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                              ToastComponent.showError(AppLocalizations.of(context)!.error_submitting_review);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      minimumSize: Size(double.infinity, 0),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            AppLocalizations.of(context)!.submit_review,
                            style: TextStyle(fontSize: 14.sp, color: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.bid_history,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(
                          AppLocalizations.of(context)!.bidder_ucf,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                        )),
                    Expanded(
                        flex: 1,
                        child: Text(
                          AppLocalizations.of(context)!.amount_ucf,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                        )),
                    Expanded(
                        flex: 1,
                        child: Text(
                          AppLocalizations.of(context)!.date_time_ucf,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                          textAlign: TextAlign.end,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: _bidHistory.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.no_bids_yet, style: TextStyle(fontSize: 14.sp)))
                    : ListView.builder(
                        itemCount: _bidHistory.length,
                        itemBuilder: (context, index) {
                          final bid = _bidHistory[index];
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                      bid.userName ?? AppLocalizations.of(context)!.user_ucf,
                                      style: TextStyle(fontSize: 13.sp),
                                    )),
                                Expanded(
                                    flex: 1,
                                    child: Text(
                                      _formatPrice(bid.amount ?? 0),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: MyTheme.accent_color,
                                      ),
                                    )),
                                Expanded(
                                    flex: 1,
                                    child: Text(
                                      _formatDateTime(bid.createdAt),
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                                      textAlign: TextAlign.end,
                                    )),
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
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.auction_ended_exclamation,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              CircleAvatar(
                radius: 50.w,
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null
                    ? Icon(Icons.person, size: 40.sp)
                    : null,
              ),
              SizedBox(height: 12.h),
              Text(
                _winnerData!.userName ?? AppLocalizations.of(context)!.winner_ucf,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatPrice(_winnerData!.amount ?? 0),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                AppLocalizations.of(context)!.congratulations_to_winner,
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.close_ucf,
                  style: TextStyle(fontSize: 14.sp, color: MyTheme.accent_color),
                ),
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
                top: 40.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.white),
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
    return dateTime;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
          ShimmerHelper().buildBasicShimmer(height: 375.h),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                ShimmerHelper().buildBasicShimmer(
                    height: 30.h, width: double.infinity),
                SizedBox(height: 10.h),
                ShimmerHelper().buildBasicShimmer(height: 20.h, width: 150.w),
                SizedBox(height: 10.h),
                ShimmerHelper().buildBasicShimmer(height: 50.h),
                SizedBox(height: 10.h),
                ShimmerHelper().buildBasicShimmer(height: 50.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // // ============================================
  // // MOBILE LAYOUT
  // // ============================================

  // Widget _buildMobileLayout() {
  //   final timeComponents = _getTimeComponents();
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   final imageHeight = screenHeight * 0.65;

  //   return Stack(
  //     children: [
  //       CustomScrollView(
  //         controller: _mainScrollController,
  //         physics: BouncingScrollPhysics(),
  //         slivers: [
  //           // Image Sliver
  //           SliverAppBar(
  //             expandedHeight: imageHeight,
  //             pinned: true,
  //             backgroundColor: Colors.black,
  //             flexibleSpace: FlexibleSpaceBar(
  //               background: Stack(
  //                 children: [
  //                   CarouselSlider(
  //                     options: CarouselOptions(
  //                       height: imageHeight,
  //                       viewportFraction: 1,
  //                       autoPlay: true,
  //                       onPageChanged: (index, reason) {
  //                         setState(() => _currentImageIndex = index);
  //                       },
  //                     ),
  //                     items: _productImages.map((image) {
  //                       return Builder(
  //                         builder: (context) => GestureDetector(
  //                           onTap: () => _showFullImage(image),
  //                           child: Container(
  //                             width: double.infinity,
  //                             decoration: BoxDecoration(
  //                               image: DecorationImage(
  //                                 image: NetworkImage(image),
  //                                 fit: BoxFit.cover,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       );
  //                     }).toList(),
  //                   ),
  //                   Container(
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         begin: Alignment.topCenter,
  //                         end: Alignment.bottomCenter,
  //                         stops: [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
  //                         colors: [
  //                           Colors.black.withOpacity(0.9),
  //                           Colors.black.withOpacity(0.5),
  //                           Colors.black.withOpacity(0.2),
  //                           Colors.black.withOpacity(0.1),
  //                           Colors.black.withOpacity(0.3),
  //                           Colors.black.withOpacity(0.7),
  //                           Colors.black.withOpacity(0.95),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   // TOP RIGHT ICONS
  //                   Positioned(
  //                     top: MediaQuery.of(context).padding.top + 8.h,
  //                     right: 16.w,
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Builder(
  //                           builder: (context) {
  //                             return GestureDetector(
  //                               onTap: () {
  //                                 setState(() {
  //                                   _showMoreMenu = !_showMoreMenu;
  //                                 });
  //                               },
  //                               child: Container(
  //                                 width: 48.w,
  //                                 height: 48.w,
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.white,
  //                                   shape: BoxShape.circle,
  //                                   boxShadow: [
  //                                     BoxShadow(
  //                                       color: Colors.black.withOpacity(0.1),
  //                                       blurRadius: 8.r,
  //                                       offset: Offset(0, 2.h),
  //                                     ),
  //                                   ],
  //                                 ),
  //                                 child: _isProcessing
  //                                     ? SizedBox(
  //                                         height: 20.w,
  //                                         width: 20.w,
  //                                         child: CircularProgressIndicator(
  //                                           strokeWidth: 2.w,
  //                                           color: MyTheme.accent_color,
  //                                         ),
  //                                       )
  //                                     : Icon(
  //                                         Icons.more_vert,
  //                                         color: Colors.black87,
  //                                         size: 22.sp,
  //                                       ),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                         SizedBox(height: 12.h),
  //                         _buildIconCircleWithImage(
  //                           imagePath: 'assets/bid_history.png',
  //                           onTap: _openBidHistoryModal,
  //                           isLoading: _isProcessing,
  //                           fallbackIcon: Icons.history,
  //                         ),
  //                         SizedBox(height: 12.h),
  //                         _buildIconCircleWithImage(
  //                           imagePath: 'assets/product_details.png',
  //                           onTap: _openTitleModal,
  //                           isLoading: _isProcessing,
  //                           fallbackIcon: Icons.info_outline,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   // Left Icons - Back Button
  //                   Positioned(
  //                     top: MediaQuery.of(context).padding.top + 8.h,
  //                     left: 16.w,
  //                     child: _buildIconCircle(
  //                       icon: Icons.arrow_back,
  //                       onTap: () => Navigator.pop(context),
  //                       isLoading: false,
  //                     ),
  //                   ),
  //                   // Bottom Content Overlay
  //                   Positioned(
  //                     bottom: 0,
  //                     left: 0,
  //                     right: 0,
  //                     child: Padding(
  //                       padding: EdgeInsets.all(16.w),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Container(
  //                             width: MediaQuery.of(context).size.width * 0.75,
  //                             decoration: BoxDecoration(
  //                               color: Colors.black.withOpacity(0.1),
  //                               borderRadius: BorderRadius.circular(20.r),
  //                               border: Border.all(
  //                                   color: Colors.white.withOpacity(0.15), width: 1.w),
  //                             ),
  //                             padding: EdgeInsets.all(12.w),
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 SizedBox(height: 6.h),
  //                                 Container(
  //                                   height: imageHeight * 0.4,
  //                                   child: _comments.isEmpty
  //                                       ? Center(
  //                                           child: Text(
  //                                             AppLocalizations.of(context)!.no_comments_yet,
  //                                             style: TextStyle(
  //                                               color: Colors.white54,
  //                                               fontSize: 11.sp,
  //                                             ),
  //                                           ),
  //                                         )
  //                                       : ListView.builder(
  //                                           shrinkWrap: true,
  //                                           itemCount: _comments.length,
  //                                           itemBuilder: (context, index) {
  //                                             final comment = _comments[index];
  //                                             return Padding(
  //                                               padding: EdgeInsets.only(bottom: 8.h),
  //                                               child: Row(
  //                                                 crossAxisAlignment:
  //                                                     CrossAxisAlignment.start,
  //                                                 children: [
  //                                                   CircleAvatar(
  //                                                     radius: 18.w,
  //                                                     backgroundImage:
  //                                                         NetworkImage(comment
  //                                                                 .userAvatar ??
  //                                                             ''),
  //                                                     child: comment
  //                                                             .userAvatar ==
  //                                                         null
  //                                                         ? Icon(Icons.person,
  //                                                             size: 16.sp,
  //                                                             color: Colors
  //                                                                 .white54)
  //                                                         : null,
  //                                                   ),
  //                                                   SizedBox(width: 10.w),
  //                                                   Expanded(
  //                                                     child: Column(
  //                                                       crossAxisAlignment:
  //                                                           CrossAxisAlignment
  //                                                               .start,
  //                                                       children: [
  //                                                         Text(
  //                                                           comment.userName ??
  //                                                               AppLocalizations.of(context)!.user_ucf,
  //                                                           style: TextStyle(
  //                                                             color: Colors
  //                                                                 .white,
  //                                                             fontSize: 13.sp,
  //                                                             fontWeight:
  //                                                                 FontWeight
  //                                                                     .w600,
  //                                                           ),
  //                                                         ),
  //                                                         Text(
  //                                                           comment.comment ??
  //                                                               '',
  //                                                           style: TextStyle(
  //                                                             color: Colors
  //                                                                 .white70,
  //                                                             fontSize: 12.sp,
  //                                                           ),
  //                                                         ),
  //                                                         Row(
  //                                                           children: [
  //                                                             GestureDetector(
  //                                                               onTap: () =>
  //                                                                   _likeComment(
  //                                                                       comment
  //                                                                           .id ??
  //                                                                           0),
  //                                                               child: Text(
  //                                                                 '${comment.likesCount} ${AppLocalizations.of(context)!.likes_ucf}',
  //                                                                 style: TextStyle(
  //                                                                   color: Colors
  //                                                                       .white54,
  //                                                                   fontSize: 11.sp,
  //                                                                 ),
  //                                                               ),
  //                                                             ),
  //                                                             SizedBox(width: 12.w),
  //                                                             GestureDetector(
  //                                                               onTap: () =>
  //                                                                   _replyToComment(
  //                                                                       comment
  //                                                                           .userName ??
  //                                                                       AppLocalizations.of(context)!.user_ucf),
  //                                                               child: Text(
  //                                                                 AppLocalizations.of(context)!.reply_ucf,
  //                                                                 style: TextStyle(
  //                                                                   color: Colors
  //                                                                       .white54,
  //                                                                   fontSize: 11.sp,
  //                                                                 ),
  //                                                               ),
  //                                                             ),
  //                                                           ],
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             );
  //                                           },
  //                                         ),
  //                                 ),
  //                                 SizedBox(height: 4.h),
  //                                 Row(
  //                                   children: [
  //                                     Expanded(
  //                                       child: Container(
  //                                         decoration: BoxDecoration(
  //                                           color: Colors.white
  //                                               .withOpacity(0.15),
  //                                           borderRadius:
  //                                               BorderRadius.circular(12.r),
  //                                         ),
  //                                         child: TextField(
  //                                           controller: _commentController,
  //                                           style: TextStyle(
  //                                               color: Colors.white,
  //                                               fontSize: 11.sp),
  //                                           decoration: InputDecoration(
  //                                             hintText: AppLocalizations.of(context)!.add_comment_hint,
  //                                             hintStyle: TextStyle(
  //                                                 color: Colors.white54,
  //                                                 fontSize: 11.sp),
  //                                             border: InputBorder.none,
  //                                             contentPadding:
  //                                                 EdgeInsets.symmetric(
  //                                                     horizontal: 10.w,
  //                                                     vertical: 6.h),
  //                                           ),
  //                                           onSubmitted: (value) =>
  //                                               _sendComment(),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     SizedBox(width: 6.w),
  //                                     GestureDetector(
  //                                       onTap: _isProcessing ? null : _sendComment,
  //                                       child: Container(
  //                                         width: 28.w,
  //                                         height: 28.w,
  //                                         decoration: BoxDecoration(
  //                                           color: MyTheme.accent_color,
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: _isProcessing
  //                                             ? SizedBox(
  //                                                 height: 12.w,
  //                                                 width: 12.w,
  //                                                 child: CircularProgressIndicator(
  //                                                   strokeWidth: 2.w,
  //                                                   color: Colors.white,
  //                                                 ),
  //                                               )
  //                                             : Icon(Icons.send,
  //                                                 size: 14.sp,
  //                                                 color: Colors.white),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           SizedBox(height: 12.h),
  //                           GestureDetector(
  //                             onTap: _openTitleModal,
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(_product?.name ?? '',
  //                                     style: TextStyle(
  //                                         color: Colors.white,
  //                                         fontSize: 22.sp,
  //                                         fontWeight: FontWeight.bold)),
  //                                 SizedBox(height: 4.h),
  //                                 Text(
  //                                     _product?.description
  //                                         ?.replaceAll(RegExp(r'<[^>]*>'),
  //                                             '') ??
  //                                         '',
  //                                     style: TextStyle(
  //                                         color: Colors.white70, fontSize: 14.sp),
  //                                     maxLines: 2,
  //                                     overflow: TextOverflow.ellipsis),
  //                               ],
  //                             ),
  //                           ),
  //                           SizedBox(height: 16.h),
  //                           Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Text(AppLocalizations.of(context)!.time_left,
  //                                       style: TextStyle(
  //                                           color: Colors.white70,
  //                                           fontSize: 12.sp)),
  //                                   SizedBox(height: 4.h),
  //                                   Row(
  //                                     children: [
  //                                       _buildTimerUnitBig(
  //                                           timeComponents['days']!, AppLocalizations.of(context)!.days_short),
  //                                       _buildTimerUnitBig(
  //                                           timeComponents['hours']!, AppLocalizations.of(context)!.hours_short),
  //                                       _buildTimerUnitBig(
  //                                           timeComponents['minutes']!,
  //                                           AppLocalizations.of(context)!.minutes_short),
  //                                       _buildTimerUnitBig(
  //                                           timeComponents['seconds']!,
  //                                           AppLocalizations.of(context)!.seconds_short),
  //                                     ],
  //                                   ),
  //                                 ],
  //                               ),
  //                               Container(
  //                                 padding: EdgeInsets.symmetric(
  //                                     horizontal: 20.w, vertical: 16.h),
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.black.withOpacity(0.6),
  //                                   borderRadius: BorderRadius.circular(16.r),
  //                                   border: Border.all(
  //                                       color: Colors.white.withOpacity(0.2), width: 1.w),
  //                                 ),
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.end,
  //                                   children: [
  //                                     Text(AppLocalizations.of(context)!.current_bid,
  //                                         style: TextStyle(
  //                                             color: Colors.white70,
  //                                             fontSize: 12.sp)),
  //                                     Text(_formatPrice(_currentHighestBid),
  //                                         style: TextStyle(
  //                                             color: Colors.white,
  //                                             fontSize: 24.sp,
  //                                             fontWeight: FontWeight.bold)),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           // Bid Info Section
  //           SliverToBoxAdapter(
  //             child: Material(
  //               borderRadius: BorderRadius.circular(16.r),
  //               child: Container(
  //                 margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
  //                 padding: EdgeInsets.all(16.w),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(16.r),
  //                   border: Border.all(color: Colors.grey.shade200, width: 1.w),
  //                 ),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(AppLocalizations.of(context)!.bid_information,
  //                         style: TextStyle(
  //                             fontWeight: FontWeight.bold, fontSize: 16.sp)),
  //                     SizedBox(height: 12.h),
  //                     GridView.count(
  //                       shrinkWrap: true,
  //                       physics: NeverScrollableScrollPhysics(),
  //                       crossAxisCount: 2,
  //                       crossAxisSpacing: 12.w,
  //                       mainAxisSpacing: 12.h,
  //                       childAspectRatio: 3,
  //                       children: [
  //                         _buildInfoItem(AppLocalizations.of(context)!.starting_bid,
  //                             _formatPrice(_startingBid)),
  //                         _buildInfoItem(AppLocalizations.of(context)!.total_bidders, '$_totalBids'),
  //                         _buildInfoItem(
  //                             AppLocalizations.of(context)!.highest_bidder,
  //                             _highestBidder.isNotEmpty
  //                                 ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
  //                                 : AppLocalizations.of(context)!.no_bids),
  //                         _buildInfoItem(AppLocalizations.of(context)!.bid_now_at, '$_pointPerBid'),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //           // Reviews Section
  //           SliverToBoxAdapter(
  //             child: GestureDetector(
  //               onTap: _openReviewsModal,
  //               child: Container(
  //                 margin: EdgeInsets.symmetric(horizontal: 16.w),
  //                 padding: EdgeInsets.all(16.w),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(16.r),
  //                   border: Border.all(color: Colors.grey.shade200, width: 1.w),
  //                   boxShadow: [
  //                     BoxShadow(
  //                         color: Colors.black.withOpacity(0.05),
  //                         blurRadius: 4.r,
  //                         offset: Offset(0, 2.h)),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Row(
  //                           children: List.generate(5, (index) {
  //                             return Icon(
  //                               index < _rating.round()
  //                                   ? Icons.star
  //                                   : Icons.star_border,
  //                               size: 16.sp,
  //                               color: Colors.amber,
  //                             );
  //                           }),
  //                         ),
  //                         SizedBox(width: 8.w),
  //                         Text(_rating.toStringAsFixed(1),
  //                             style: TextStyle(
  //                                 fontSize: 18.sp, fontWeight: FontWeight.bold)),
  //                         SizedBox(width: 8.w),
  //                         Container(
  //                           padding: EdgeInsets.symmetric(
  //                               horizontal: 8.w, vertical: 4.h),
  //                           decoration: BoxDecoration(
  //                             color: Colors.grey.shade100,
  //                             borderRadius: BorderRadius.circular(20.r),
  //                           ),
  //                           child: Text('$_reviewsCount ${AppLocalizations.of(context)!.reviews_ucf}',
  //                               style: TextStyle(
  //                                   fontSize: 12.sp, color: Colors.grey)),
  //                         ),
  //                       ],
  //                     ),
  //                     Icon(Icons.arrow_forward_ios,
  //                         size: 16.sp, color: Colors.grey),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //           // Thumbnails
  //           SliverToBoxAdapter(
  //             child: Container(
  //               height: 70.h,
  //               margin: EdgeInsets.all(16.w),
  //               child: ListView.builder(
  //                 scrollDirection: Axis.horizontal,
  //                 itemCount: _productImages.length,
  //                 itemBuilder: (context, index) {
  //                   return GestureDetector(
  //                     onTap: () {
  //                       setState(() => _currentImageIndex = index);
  //                     },
  //                     child: Container(
  //                       width: 60.w,
  //                       height: 60.w,
  //                       margin: EdgeInsets.only(right: 8.w),
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         border: Border.all(
  //                           color: _currentImageIndex == index
  //                               ? MyTheme.accent_color
  //                               : Colors.grey.shade300,
  //                           width: 2.w,
  //                         ),
  //                       ),
  //                       child: ClipRRect(
  //                         borderRadius: BorderRadius.circular(10.r),
  //                         child: Image.network(
  //                           _productImages[index],
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) =>
  //                               Icon(Icons.broken_image, color: Colors.grey),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //           SliverToBoxAdapter(child: SizedBox(height: 80.h)),
  //         ],
  //       ),
  //       // More Menu
  //       if (_showMoreMenu)
  //         Positioned(
  //           top: MediaQuery.of(context).padding.top + 80.h,
  //           right: 16.w,
  //           child: Material(
  //             elevation: 20,
  //             borderRadius: BorderRadius.circular(16.r),
  //             child: Container(
  //               width: 180.w,
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(16.r),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.black.withOpacity(0.25),
  //                     blurRadius: 15.r,
  //                     offset: Offset(0, 5.h),
  //                   ),
  //                 ],
  //               ),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   _buildMoreMenuItem(
  //                     icon: Icons.share,
  //                     text: AppLocalizations.of(context)!.share_ucf,
  //                     onTap: () {
  //                       setState(() => _showMoreMenu = false);
  //                       _shareProduct();
  //                     },
  //                   ),
  //                   _buildMoreMenuItem(
  //                     icon: _isInWishlist
  //                         ? Icons.favorite
  //                         : Icons.favorite_border,
  //                     text: _isInWishlist ? AppLocalizations.of(context)!.saved_ucf : AppLocalizations.of(context)!.save_ucf,
  //                     onTap: () {
  //                       setState(() => _showMoreMenu = false);
  //                       _toggleWishlist();
  //                     },
  //                   ),
  //                   _buildMoreMenuItem(
  //                     icon: Icons.contact_mail,
  //                     text: _isProcessing ? AppLocalizations.of(context)!.contacting : AppLocalizations.of(context)!.contact_seller,
  //                     onTap: _isProcessing ? null : () {
  //                       setState(() => _showMoreMenu = false);
  //                       _contactSeller();
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       // Bottom Bar
  //       Positioned(
  //         bottom: 0,
  //         left: 0,
  //         right: 0,
  //         child: Container(
  //           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             boxShadow: [
  //               BoxShadow(
  //                   color: Colors.black12,
  //                   blurRadius: 8.r,
  //                   offset: Offset(0, -2.h))
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: OutlinedButton(
  //                   onPressed: _showBidInputDialog,
  //                   style: OutlinedButton.styleFrom(
  //                     padding: EdgeInsets.symmetric(vertical: 14.h),
  //                     shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8.r)),
  //                   ),
  //                   child: Text(AppLocalizations.of(context)!.custom_ucf, style: TextStyle(fontSize: 14.sp)),
  //                 ),
  //               ),
  //               SizedBox(width: 12.w),
  //               Expanded(
  //                 flex: 2,
  //                 child: ElevatedButton(
  //                   onPressed: _isProcessing ? null : _placeBidNow,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: MyTheme.accent_color,
  //                     padding: EdgeInsets.symmetric(vertical: 14.h),
  //                     shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8.r)),
  //                   ),
  //                   child: _isProcessing
  //                       ? _buildButtonLoader()
  //                       : Text(
  //                           '${AppLocalizations.of(context)!.bid_now} - ${_formatPrice(_minNextBidNow)}',
  //                           style: TextStyle(fontSize: 14.sp, color: Colors.white),
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

// ============================================
// MOBILE LAYOUT - UNIFIED SINGLE SCROLL VIEW
// ============================================

  Widget _buildMobileLayout() {
    final timeComponents = _getTimeComponents();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _fetchAllData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              // IMAGE CAROUSEL WITH OVERLAY CONTENT
              // ============================================
              Stack(
                children: [
                  // Carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 500.h,
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
                    height: 500.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
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
                  // TOP RIGHT ICONS
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8.h,
                    right: 16.w,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showMoreMenu = !_showMoreMenu;
                                });
                              },
                              child: Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: _isProcessing
                                    ? SizedBox(
                                        height: 20.w,
                                        width: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          color: MyTheme.accent_color,
                                        ),
                                      )
                                    : Icon(
                                        Icons.more_vert,
                                        color: Colors.black87,
                                        size: 22.sp,
                                      ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildIconCircleWithImage(
                          imagePath: 'assets/bid_history.png',
                          onTap: _openBidHistoryModal,
                          isLoading: _isProcessing,
                          fallbackIcon: Icons.history,
                        ),
                        SizedBox(height: 12.h),
                        _buildIconCircleWithImage(
                          imagePath: 'assets/product_details.png',
                          onTap: _openTitleModal,
                          isLoading: _isProcessing,
                          fallbackIcon: Icons.info_outline,
                        ),
                      ],
                    ),
                  ),
                  // LEFT ICON - Back Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8.h,
                    left: 16.w,
                    child: _buildIconCircle(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                      isLoading: false,
                    ),
                  ),
                  // ============================================
                  // COMMENTS SECTION - ON THE IMAGE (OVERLAY)
                  // ============================================
                  Positioned(
                    bottom: 180.h, // Positioned above the product name
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15), width: 1.w),
                      ),
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Comments List
                          Container(
                            height: 150.h,
                            child: _comments.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(context)!.no_comments_yet,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = _comments[index];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 8.h),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18.w,
                                              backgroundImage:
                                                  NetworkImage(comment
                                                          .userAvatar ??
                                                      ''),
                                              child: comment
                                                      .userAvatar ==
                                                  null
                                                  ? Icon(Icons.person,
                                                      size: 16.sp,
                                                      color: Colors
                                                          .white54)
                                                  : null,
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    comment.userName ??
                                                        AppLocalizations.of(context)!.user_ucf,
                                                    style: TextStyle(
                                                      color: Colors
                                                          .white,
                                                      fontSize: 13.sp,
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
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _likeComment(
                                                                comment
                                                                    .id ??
                                                                    0),
                                                        child: Text(
                                                          '${comment.likesCount} ${AppLocalizations.of(context)!.likes_ucf}',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .white54,
                                                            fontSize: 11.sp,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12.w),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _replyToComment(
                                                                comment
                                                                    .userName ??
                                                                AppLocalizations.of(context)!.user_ucf),
                                                        child: Text(
                                                          AppLocalizations.of(context)!.reply_ucf,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .white54,
                                                            fontSize: 11.sp,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
                          SizedBox(height: 4.h),
                          // Comment Input
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(12.r),
                                  ),
                                  child: TextField(
                                    controller: _commentController,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.add_comment_hint,
                                      hintStyle: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11.sp),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 6.h),
                                    ),
                                    onSubmitted: (value) =>
                                        _sendComment(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              GestureDetector(
                                onTap: _isProcessing ? null : _sendComment,
                                child: Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: MyTheme.accent_color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isProcessing
                                      ? SizedBox(
                                          height: 12.w,
                                          width: 12.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(Icons.send,
                                          size: 14.sp,
                                          color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ============================================
                  // PRODUCT NAME & DESCRIPTION - ON THE IMAGE
                  // ============================================
                  Positioned(
                    bottom: 100.h,
                    left: 16.w,
                    right: 16.w,
                    child: GestureDetector(
                      onTap: _openTitleModal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_product?.name ?? '',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4.h),
                          Text(
                              _product?.description
                                      ?.replaceAll(RegExp(r'<[^>]*>'),
                                          '') ??
                                  '',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14.sp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  // ============================================
                  // TIMER & CURRENT BID - ON THE IMAGE
                  // ============================================
                  Positioned(
                    bottom: 16.h,
                    left: 16.w,
                    right: 16.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.time_left,
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp)),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                _buildTimerUnitBig(
                                    timeComponents['days']!, AppLocalizations.of(context)!.days_short),
                                _buildTimerUnitBig(
                                    timeComponents['hours']!, AppLocalizations.of(context)!.hours_short),
                                _buildTimerUnitBig(
                                    timeComponents['minutes']!,
                                    AppLocalizations.of(context)!.minutes_short),
                                _buildTimerUnitBig(
                                    timeComponents['seconds']!,
                                    AppLocalizations.of(context)!.seconds_short),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1.w),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppLocalizations.of(context)!.current_bid,
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.sp)),
                              Text(_formatPrice(_currentHighestBid),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // ============================================
              // BID INFORMATION SECTION
              // ============================================
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200, width: 1.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.bid_information,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    SizedBox(height: 12.h),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 3,
                      children: [
                        _buildInfoItem(AppLocalizations.of(context)!.starting_bid,
                            _formatPrice(_startingBid)),
                        _buildInfoItem(AppLocalizations.of(context)!.total_bidders, '$_totalBids'),
                        _buildInfoItem(
                            AppLocalizations.of(context)!.highest_bidder,
                            _highestBidder.isNotEmpty
                                ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                : AppLocalizations.of(context)!.no_bids),
                        _buildInfoItem(AppLocalizations.of(context)!.bid_now_at, '$_pointPerBid'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ============================================
              // CUSTOM BID INPUT
              // ============================================
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${AppLocalizations.of(context)!.enter_bid_amount} (${AppLocalizations.of(context)!.one_bid_equals} $_pointPerBidCustom)',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bidController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.enter_amount_hint,
                              hintStyle: TextStyle(fontSize: 14.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _submitCustomBid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyTheme.accent_color,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                          ),
                          child: _isProcessing
                              ? _buildButtonLoader()
                              : Text(AppLocalizations.of(context)!.place_bid,
                                  style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              
              // ============================================
              // BID NOW BUTTON
              // ============================================
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeBidNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyTheme.accent_color,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    minimumSize: Size(double.infinity, 0),
                  ),
                  child: _isProcessing
                      ? _buildButtonLoader()
                      : Text(
                          '${AppLocalizations.of(context)!.bid_now} - ${_formatPrice(_minNextBidNow)}',
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 12.h),
              
              // ============================================
              // REVIEWS SECTION
              // ============================================
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: GestureDetector(
                  onTap: _openReviewsModal,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey.shade200, width: 1.w),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h))
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
                                  size: 16.sp,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            SizedBox(width: 8.w),
                            Text(_rating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text('$_reviewsCount ${AppLocalizations.of(context)!.reviews_ucf}',
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey)),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 16.sp, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              
              // ============================================
              // THUMBNAILS
              // ============================================
              Container(
                height: 70.h,
                margin: EdgeInsets.all(16.w),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentImageIndex = index);
                      },
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _currentImageIndex == index
                                ? MyTheme.accent_color
                                : Colors.grey.shade300,
                            width: 2.w,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
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
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================
  // Icon Circle with Custom Image
  // ============================================

  Widget _buildIconCircleWithImage({
    required String imagePath,
    required VoidCallback onTap,
    bool isLoading = false,
    IconData? fallbackIcon,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                height: 20.w,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: MyTheme.accent_color,
                ),
              )
            : Padding(
                padding: EdgeInsets.all(10.w),
                child: Image.asset(
                  imagePath,
                  height: 28.w,
                  width: 28.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (imagePath.contains('product_details')) {
                      return Icon(
                        Icons.info_outline,
                        size: 26.sp,
                        color: Colors.black87,
                      );
                    } else if (imagePath.contains('bid_history')) {
                      return Icon(
                        Icons.history,
                        size: 26.sp,
                        color: Colors.black87,
                      );
                    }
                    return Icon(
                      Icons.image_not_supported,
                      size: 26.sp,
                      color: Colors.black87,
                    );
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return frame == null
                        ? SizedBox(
                            height: 24.w,
                            width: 24.w,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          )
                        : child;
                  },
                ),
              ),
      ),
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
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                height: 20.w,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: MyTheme.accent_color,
                ),
              )
            : Icon(
                icon,
                color: isActive ? MyTheme.accent_color : Colors.black87,
                size: 22.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: Colors.grey.shade700),
            SizedBox(width: 12.w),
            Text(text,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerUnitBig(String value, String label) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
          SizedBox(height: 4.h),
          Text(value,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Image Gallery
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 400.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: Colors.grey.shade100,
                      ),
                      child: GestureDetector(
                        onTap: () => _showFullImage(
                            _productImages[_currentImageIndex]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            _productImages[_currentImageIndex],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image,
                                    size: 80.sp, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 80.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _productImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currentImageIndex = index),
                            child: Container(
                              width: 70.w,
                              height: 70.w,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: _currentImageIndex == index
                                      ? MyTheme.accent_color
                                      : Colors.grey.shade300,
                                  width: 2.w,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
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
            SizedBox(width: 16.w),
            // Column 2: Chat Section
            Expanded(
              flex: 2,
              child: Container(
                height: MediaQuery.of(context).size.height - 120.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.grey.shade200, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.comments_ucf,
                              style: TextStyle(
                                  fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          Text(AppLocalizations.of(context)!.ask_about_product,
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final userIdStr = user_id.$?.toString() ?? '0';
                          final isOwn =
                              comment.userId == int.tryParse(userIdStr);

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Row(
                              mainAxisAlignment: isOwn
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOwn) ...[
                                  CircleAvatar(
                                    radius: 16.w,
                                    backgroundImage: NetworkImage(
                                        comment.userAvatar ?? ''),
                                    child: comment.userAvatar == null
                                        ? Icon(Icons.person, size: 16.sp,
                                            color: Colors.grey)
                                        : null,
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: isOwn
                                          ? MyTheme.accent_color
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12.r),
                                        topRight: Radius.circular(12.r),
                                        bottomLeft: isOwn
                                            ? Radius.circular(12.r)
                                            : Radius.circular(4.r),
                                        bottomRight: isOwn
                                            ? Radius.circular(4.r)
                                            : Radius.circular(12.r),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwn)
                                          Text(comment.userName ?? AppLocalizations.of(context)!.user_ucf,
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey
                                                      .shade600)),
                                        Text(comment.comment ?? '',
                                            style: TextStyle(
                                                color: isOwn
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 13.sp)),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            _formatTime(comment.createdAt),
                                            style: TextStyle(
                                                fontSize: 9.sp,
                                                color: isOwn
                                                    ? Colors.white70
                                                    : Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isOwn) SizedBox(width: 8.w),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 1.w),
                              ),
                              child: TextField(
                                controller: _commentController,
                                maxLines: null,
                                style: TextStyle(fontSize: 14.sp),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.type_message_hint,
                                  hintStyle:
                                      TextStyle(fontSize: 14.sp, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 12.h),
                                ),
                                onSubmitted: (value) => _sendComment(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: _isProcessing ? null : _sendComment,
                            child: Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                shape: BoxShape.circle,
                              ),
                              child: _isProcessing
                                  ? SizedBox(
                                      height: 16.w,
                                      width: 16.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.send,
                                      color: Colors.white, size: 20.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Column 3: Bidding & Details
            Expanded(
              flex: 1,
              child: Container(
                width: 320.w,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _openTitleModal,
                            child: Text(_product?.name ?? '',
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _openTitleModal,
                            child: Text(
                              _product?.description
                                      ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                                  '',
                              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Wrap(
                            spacing: 8.w,
                            children: [
                              _buildDesktopIconButton(
                                icon: Icons.share,
                                label: AppLocalizations.of(context)!.share_ucf,
                                onTap: _shareProduct,
                              ),
                              _buildDesktopIconButton(
                                icon: _isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: _isInWishlist ? AppLocalizations.of(context)!.saved_ucf : AppLocalizations.of(context)!.wishlist_ucf,
                                onTap: _toggleWishlist,
                                isActive: _isInWishlist,
                              ),
                              _buildDesktopIconButton(
                                icon: Icons.more_horiz,
                                label: AppLocalizations.of(context)!.more_ucf,
                                onTap: () => setState(() =>
                                    _showDesktopMoreMenu =
                                        !_showDesktopMoreMenu),
                              ),
                            ],
                          ),
                          if (_showDesktopMoreMenu)
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h))
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDesktopMenuItem(
                                    icon: Icons.history,
                                    text: AppLocalizations.of(context)!.bid_history,
                                    onTap: () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _openBidHistoryModal();
                                    },
                                  ),
                                  _buildDesktopMenuItem(
                                    icon: Icons.info_outline,
                                    text: AppLocalizations.of(context)!.product_details,
                                    onTap: () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _openTitleModal();
                                    },
                                  ),
                                  _buildDesktopMenuItem(
                                    icon: Icons.contact_mail,
                                    text: _isProcessing ? AppLocalizations.of(context)!.contacting : AppLocalizations.of(context)!.contact_seller,
                                    onTap: _isProcessing ? null : () {
                                      setState(() => _showDesktopMoreMenu =
                                          false);
                                      _contactSeller();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 16.h),
                          // Timer & Price
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppLocalizations.of(context)!.time_left,
                                        style: TextStyle(
                                            fontSize: 10.sp,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500)),
                                    Row(
                                      children: [
                                        _buildDesktopTimerUnit(
                                            timeComponents['days']!, AppLocalizations.of(context)!.days_short),
                                        _buildDesktopTimerUnit(
                                            timeComponents['hours']!, AppLocalizations.of(context)!.hours_short),
                                        _buildDesktopTimerUnit(
                                            timeComponents['minutes']!, AppLocalizations.of(context)!.minutes_short),
                                        _buildDesktopTimerUnit(
                                            timeComponents['seconds']!, AppLocalizations.of(context)!.seconds_short),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppLocalizations.of(context)!.current_bid,
                                        style: TextStyle(
                                            fontSize: 11.sp, color: Colors.grey)),
                                    Text(_formatPrice(_currentHighestBid),
                                        style: TextStyle(
                                            fontSize: 24.sp,
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
                    SizedBox(height: 12.h),
                    // Bid Information Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.bid_information,
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12.h),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: 2.5,
                            children: [
                              _buildDesktopInfoItem(AppLocalizations.of(context)!.starting_bid,
                                  _formatPrice(_startingBid)),
                              _buildDesktopInfoItem(AppLocalizations.of(context)!.total_bidders,
                                  '$_totalBids'),
                              _buildDesktopInfoItem(
                                  AppLocalizations.of(context)!.highest_bidder,
                                  _highestBidder.isNotEmpty
                                      ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                      : AppLocalizations.of(context)!.no_bids),
                              _buildDesktopInfoItem(AppLocalizations.of(context)!.bid_now_at,
                                  '$_pointPerBid'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Custom Bid Input
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${AppLocalizations.of(context)!.enter_bid_amount} (${AppLocalizations.of(context)!.one_bid_equals} $_pointPerBidCustom)',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bidController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.enter_amount_hint,
                                    hintStyle: TextStyle(fontSize: 14.sp),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              ElevatedButton(
                                onPressed: _isProcessing ? null : _submitCustomBid,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyTheme.accent_color,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 12.h),
                                ),
                                child: _isProcessing
                                    ? _buildButtonLoader()
                                    : Text(AppLocalizations.of(context)!.place_bid,
                                        style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Bid Now Button
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _placeBidNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              '${AppLocalizations.of(context)!.bid_now} - ${_formatPrice(_minNextBidNow)}',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    SizedBox(height: 12.h),
                    // Reviews Section
                    GestureDetector(
                      onTap: _openReviewsModal,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade200, width: 1.w),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h))
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
                                      size: 14.sp,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                SizedBox(width: 8.w),
                                Text(_rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 4.w),
                                Text('($_reviewsCount ${AppLocalizations.of(context)!.reviews_ucf})',
                                    style: TextStyle(
                                        fontSize: 12.sp, color: Colors.grey)),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 14.sp, color: Colors.grey),
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? MyTheme.accent_color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200, width: 1.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14.sp,
                color: isActive ? Colors.white : Colors.grey.shade600),
            SizedBox(width: 4.w),
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: Colors.grey.shade600),
            SizedBox(width: 12.w),
            Text(text,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTimerUnit(String value, String label) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          SizedBox(height: 4.h),
          Text(value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}