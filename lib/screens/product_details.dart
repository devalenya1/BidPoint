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

  // Screen width for responsive sizing
  double _screenWidth = 0;

  // Scroll controller for comments to auto-scroll to bottom
  final ScrollController _commentsScrollController = ScrollController();

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
    _commentsScrollController.dispose();
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
      
      // Auto-scroll to bottom after comments load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error fetching data: $e');
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_product_details);
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_commentsScrollController.hasClients) {
      _commentsScrollController.animateTo(
        _commentsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response =
          await _productRepository.getProductComments(_product?.id ?? 0);
      if (response.success == true && response.comments != null) {
        // Reverse comments so latest appears at bottom
        setState(() => _comments = response.comments!.reversed.toList());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
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
          setState(() => _comments = response.comments!.reversed.toList());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
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
    _screenWidth = MediaQuery.of(context).size.width;
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
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
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
      return '${days}d ${hours}h ${minutes}m';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> _getTimeComponents() {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    bool showDays = days > 0;
    bool showSeconds = !showDays;

    return {
      'days': days.toString().padLeft(2, '0'),
      'hours': hours.toString().padLeft(2, '0'),
      'minutes': minutes.toString().padLeft(2, '0'),
      'seconds': seconds.toString().padLeft(2, '0'),
      'showDays': showDays,
      'showSeconds': showSeconds,
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
    final isSmallScreen = _screenWidth < 400;
    final modalWidth = _screenWidth * 0.9;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          width: modalWidth,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.product_details,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16.sp : 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: isSmallScreen ? 20.sp : 24.sp),
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
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Html(
                        data: _product?.description ?? '',
                        style: {
                          'body': Style(
                            fontSize: FontSize(isSmallScreen ? 12.0 : 14.0),
                          ),
                        },
                      ),
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

  void _showBidHistoryModalDialog() {
    final isSmallScreen = _screenWidth < 400;
    final modalWidth = _screenWidth * 0.9;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          width: modalWidth,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.bid_history,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.sp : 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isSmallScreen ? 20.sp : 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppLocalizations.of(context)!.bidder_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 10.sp : 12.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        AppLocalizations.of(context)!.amount_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 10.sp : 12.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        AppLocalizations.of(context)!.date_time_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 10.sp : 12.sp,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _bidHistory.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.no_bids_yet,
                          style: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _bidHistory.length,
                        itemBuilder: (context, index) {
                          final bid = _bidHistory[index];
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    bid.userName ?? AppLocalizations.of(context)!.user_ucf,
                                    style: TextStyle(fontSize: isSmallScreen ? 11.sp : 13.sp),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _formatPrice(bid.amount ?? 0),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11.sp : 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: MyTheme.accent_color,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _formatDateTime(bid.createdAt),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 9.sp : 11.sp,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
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

  void _showReviewsModalDialog() {
    final isSmallScreen = _screenWidth < 400;
    final modalWidth = _screenWidth * 0.9;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            child: Container(
              width: modalWidth,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.w)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.all_reviews} ($_reviewsCount)',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.sp : 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: isSmallScreen ? 20.sp : 24.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _reviews.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.no_reviews_yet,
                              style: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
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
                                              size: isSmallScreen ? 12.sp : 14.sp,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          _formatDate(review.createdAt),
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 9.sp : 11.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      review.comment ?? '',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12.sp : 14.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      review.userName ?? AppLocalizations.of(context)!.user_ucf,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10.sp : 12.sp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
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
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                color: Colors.white,
                              ),
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
    final isSmallScreen = _screenWidth < 400;
    final modalWidth = _screenWidth * 0.9;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            child: Container(
              width: modalWidth,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(isSmallScreen ? 16.w : 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.write_a_review,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16.sp : 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: isSmallScreen ? 20.sp : 24.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppLocalizations.of(context)!.rating_ucf,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12.sp : 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: isSmallScreen ? 24.w : 30.w,
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      tempRating = rating;
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppLocalizations.of(context)!.review_ucf,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12.sp : 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: tempController,
                    maxLines: 4,
                    style: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.share_experience_hint,
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                              color: Colors.white,
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

  void _showWinnerModalDialog() {
    if (_winnerData == null) return;
    final isSmallScreen = _screenWidth < 400;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.w : 24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: isSmallScreen ? 40.sp : 48.sp)),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.auction_ended_exclamation,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              CircleAvatar(
                radius: isSmallScreen ? 40.w : 50.w,
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null
                    ? Icon(Icons.person, size: isSmallScreen ? 32.sp : 40.sp)
                    : null,
              ),
              SizedBox(height: 10.h),
              Text(
                _winnerData!.userName ?? AppLocalizations.of(context)!.winner_ucf,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16.sp : 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatPrice(_winnerData!.amount ?? 0),
                style: TextStyle(
                  fontSize: isSmallScreen ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppLocalizations.of(context)!.congratulations_to_winner,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12.sp : 14.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 16.h),
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
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12.sp : 14.sp,
                    color: MyTheme.accent_color,
                  ),
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
    _screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = _screenWidth >= 992;

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

  // ============================================
  // TIMER WIDGETS - FIXED
  // ============================================

  Widget _buildTimerUnitWithLabel(String value, String label, {bool isEndingSoon = false}) {
    if (label == 's' && _timeLeft.inDays > 0) {
      return const SizedBox.shrink(); 
    }
    
    final isSmallScreen = _screenWidth < 400;
    final fontSize = isSmallScreen ? 18.sp : 22.sp;
    final labelSize = isSmallScreen ? 8.sp : 10.sp;
    final padding = isSmallScreen ? 6.w : 8.w;
    
    return Container(
      margin: EdgeInsets.only(right: 4.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4.h),
            decoration: BoxDecoration(
              color: isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRowWithLabels() {
    final components = _getTimeComponents();
    final days = components['days'] as String;
    final hours = components['hours'] as String;
    final minutes = components['minutes'] as String;
    final seconds = components['seconds'] as String;
    final showDays = components['showDays'] as bool;
    final showSeconds = components['showSeconds'] as bool;

    List<Widget> timerUnits = [];

    if (showDays) {
      timerUnits.add(_buildTimerUnitWithLabel(days, 'd', isEndingSoon: _isEndingSoon));
    }
    
    timerUnits.add(_buildTimerUnitWithLabel(hours, 'h', isEndingSoon: _isEndingSoon));
    timerUnits.add(_buildTimerUnitWithLabel(minutes, 'm', isEndingSoon: _isEndingSoon));
    
    if (showSeconds) {
      timerUnits.add(_buildTimerUnitWithLabel(seconds, 's', isEndingSoon: _isEndingSoon));
    }

    return Row(
      children: timerUnits,
    );
  }

  // ============================================
  // MOBILE LAYOUT - UPDATED
  // ============================================

  // Widget _buildMobileLayout() {
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   final imageHeight = screenHeight * 0.85; // 85% of screen height
  //   final isSmallScreen = _screenWidth < 380;
  //   final isMediumScreen = _screenWidth >= 380 && _screenWidth < 480;
    
  //   // Responsive font sizes - dynamically scale
  //   final double nameFontSize = isSmallScreen ? 16.sp : (isMediumScreen ? 18.sp : 20.sp);
  //   final double descFontSize = isSmallScreen ? 10.sp : (isMediumScreen ? 11.sp : 12.sp);
  //   final double commentFontSize = isSmallScreen ? 8.sp : (isMediumScreen ? 9.sp : 10.sp);
  //   final double commentNameFontSize = isSmallScreen ? 9.sp : (isMediumScreen ? 10.sp : 11.sp);
  //   final double badgeFontSize = isSmallScreen ? 6.sp : (isMediumScreen ? 7.sp : 8.sp);
  //   final double timerTitleSize = isSmallScreen ? 10.sp : (isMediumScreen ? 11.sp : 12.sp);
  //   final double bidPriceSize = isSmallScreen ? 16.sp : (isMediumScreen ? 18.sp : 20.sp);
  //   final double bidLabelSize = isSmallScreen ? 9.sp : (isMediumScreen ? 10.sp : 11.sp);
  //   final double commentsHeight = isSmallScreen ? 200.h : 240.h; // Longer comment section
    
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     body: Stack(
  //       children: [
  //         // Main scrollable content
  //         RefreshIndicator(
  //           color: MyTheme.accent_color,
  //           backgroundColor: Colors.white,
  //           onRefresh: _fetchAllData,
  //           child: SingleChildScrollView(
  //             controller: _mainScrollController,
  //             physics: const BouncingScrollPhysics(),
  //             padding: EdgeInsets.only(bottom: 80.h),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // ============================================
  //                 // IMAGE CAROUSEL WITH OVERLAY
  //                 // ============================================
  //                 Stack(
  //                   children: [
  //                     CarouselSlider(
  //                       options: CarouselOptions(
  //                         height: imageHeight,
  //                         viewportFraction: 1,
  //                         autoPlay: true,
  //                         onPageChanged: (index, reason) {
  //                           setState(() => _currentImageIndex = index);
  //                         },
  //                       ),
  //                       items: _productImages.map((image) {
  //                         return Builder(
  //                           builder: (context) => GestureDetector(
  //                             onTap: () => _showFullImage(image),
  //                             child: Container(
  //                               width: double.infinity,
  //                               decoration: BoxDecoration(
  //                                 image: DecorationImage(
  //                                   image: NetworkImage(image),
  //                                   fit: BoxFit.cover,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         );
  //                       }).toList(),
  //                     ),
  //                     Container(
  //                       height: imageHeight,
  //                       decoration: BoxDecoration(
  //                         gradient: LinearGradient(
  //                           begin: Alignment.topCenter,
  //                           end: Alignment.bottomCenter,
  //                           stops: const [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
  //                           colors: [
  //                             Colors.black.withOpacity(0.9),
  //                             Colors.black.withOpacity(0.5),
  //                             Colors.black.withOpacity(0.2),
  //                             Colors.black.withOpacity(0.1),
  //                             Colors.black.withOpacity(0.3),
  //                             Colors.black.withOpacity(0.7),
  //                             Colors.black.withOpacity(0.95),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                     // TOP RIGHT ICONS
  //                     Positioned(
  //                       top: MediaQuery.of(context).padding.top + 8.h,
  //                       right: 16.w,
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Builder(
  //                             builder: (context) {
  //                               return GestureDetector(
  //                                 onTap: () {
  //                                   setState(() {
  //                                     _showMoreMenu = !_showMoreMenu;
  //                                   });
  //                                 },
  //                                 child: Container(
  //                                   width: isSmallScreen ? 40.w : 48.w,
  //                                   height: isSmallScreen ? 40.w : 48.w,
  //                                   decoration: BoxDecoration(
  //                                     color: Colors.white,
  //                                     shape: BoxShape.circle,
  //                                     boxShadow: [
  //                                       BoxShadow(
  //                                         color: Colors.black.withOpacity(0.1),
  //                                         blurRadius: 8.r,
  //                                         offset: Offset(0, 2.h),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                   child: _isProcessing
  //                                       ? SizedBox(
  //                                           height: 16.w,
  //                                           width: 16.w,
  //                                           child: CircularProgressIndicator(
  //                                             strokeWidth: 2.w,
  //                                             color: MyTheme.accent_color,
  //                                           ),
  //                                         )
  //                                       : Icon(
  //                                           Icons.more_vert,
  //                                           color: Colors.black87,
  //                                           size: isSmallScreen ? 18.sp : 22.sp,
  //                                         ),
  //                                 ),
  //                               );
  //                             },
  //                           ),
  //                           SizedBox(height: 8.h),
  //                           _buildIconCircleWithImage(
  //                             imagePath: 'assets/bid_history.png',
  //                             onTap: _openBidHistoryModal,
  //                             isLoading: _isProcessing,
  //                             fallbackIcon: Icons.history,
  //                             size: isSmallScreen ? 40.w : 48.w,
  //                           ),
  //                           SizedBox(height: 8.h),
  //                           _buildIconCircleWithImage(
  //                             imagePath: 'assets/product_details.png',
  //                             onTap: _openTitleModal,
  //                             isLoading: _isProcessing,
  //                             fallbackIcon: Icons.info_outline,
  //                             size: isSmallScreen ? 40.w : 48.w,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     // LEFT ICON - Back Button
  //                     Positioned(
  //                       top: MediaQuery.of(context).padding.top + 8.h,
  //                       left: 16.w,
  //                       child: _buildIconCircle(
  //                         icon: Icons.arrow_back,
  //                         onTap: () => Navigator.pop(context),
  //                         isLoading: false,
  //                         size: isSmallScreen ? 40.w : 48.w,
  //                       ),
  //                     ),
  //                     // ============================================
  //                     // COMMENTS SECTION - Updated: Longer height, latest at bottom
  //                     // ============================================
  //                     Positioned(
  //                       bottom: 100.h,
  //                       left: 12.w,
  //                       child: Container(
  //                         width: _screenWidth * 0.78,
  //                         decoration: BoxDecoration(
  //                           color: Colors.black.withOpacity(0.1),
  //                           borderRadius: BorderRadius.circular(16.r),
  //                           border: Border.all(
  //                               color: Colors.white.withOpacity(0.15), width: 1.w),
  //                         ),
  //                         padding: EdgeInsets.all(8.w),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // Comments List - SCROLLABLE - LONGER HEIGHT
  //                             Container(
  //                               height: commentsHeight,
  //                               child: _comments.isEmpty
  //                                   ? Center(
  //                                       child: Text(
  //                                         AppLocalizations.of(context)!.no_comments_yet,
  //                                         style: TextStyle(
  //                                           color: Colors.white54,
  //                                           fontSize: commentFontSize,
  //                                         ),
  //                                       ),
  //                                     )
  //                                   : ListView.builder(
  //                                       controller: _commentsScrollController,
  //                                       physics: const AlwaysScrollableScrollPhysics(),
  //                                       itemCount: _comments.length,
  //                                       itemBuilder: (context, index) {
  //                                         final comment = _comments[index];
  //                                         return Padding(
  //                                           padding: EdgeInsets.only(bottom: 4.h),
  //                                           child: Row(
  //                                             crossAxisAlignment:
  //                                                 CrossAxisAlignment.start,
  //                                             children: [
  //                                               CircleAvatar(
  //                                                 radius: isSmallScreen ? 10.w : 14.w,
  //                                                 backgroundImage:
  //                                                     NetworkImage(comment
  //                                                             .userAvatar ??
  //                                                         ''),
  //                                                 child: comment
  //                                                         .userAvatar ==
  //                                                     null
  //                                                     ? Icon(Icons.person,
  //                                                         size: isSmallScreen ? 8.sp : 12.sp,
  //                                                         color: Colors
  //                                                             .white54)
  //                                                     : null,
  //                                               ),
  //                                               SizedBox(width: 6.w),
  //                                               Expanded(
  //                                                 child: Column(
  //                                                   crossAxisAlignment:
  //                                                       CrossAxisAlignment
  //                                                           .start,
  //                                                   children: [
  //                                                     Text(
  //                                                       comment.userName ??
  //                                                           AppLocalizations.of(context)!.user_ucf,
  //                                                       style: TextStyle(
  //                                                         color: Colors
  //                                                             .white,
  //                                                         fontSize: commentNameFontSize,
  //                                                         fontWeight:
  //                                                             FontWeight
  //                                                                 .w600,
  //                                                       ),
  //                                                     ),
  //                                                     Text(
  //                                                       comment.comment ??
  //                                                           '',
  //                                                       style: TextStyle(
  //                                                         color: Colors
  //                                                             .white70,
  //                                                         fontSize: commentFontSize,
  //                                                       ),
  //                                                     ),
  //                                                     Row(
  //                                                       children: [
  //                                                         GestureDetector(
  //                                                           onTap: () =>
  //                                                               _likeComment(
  //                                                                   comment
  //                                                                       .id ??
  //                                                                       0),
  //                                                           child: Text(
  //                                                             '${comment.likesCount} ${AppLocalizations.of(context)!.likes_ucf}',
  //                                                             style: TextStyle(
  //                                                               color: Colors
  //                                                                   .white54,
  //                                                               fontSize: badgeFontSize,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                         SizedBox(width: 8.w),
  //                                                         GestureDetector(
  //                                                           onTap: () =>
  //                                                               _replyToComment(
  //                                                                   comment
  //                                                                       .userName ??
  //                                                                   AppLocalizations.of(context)!.user_ucf),
  //                                                           child: Text(
  //                                                             AppLocalizations.of(context)!.reply_ucf,
  //                                                             style: TextStyle(
  //                                                               color: Colors
  //                                                                   .white54,
  //                                                               fontSize: badgeFontSize,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         );
  //                                       },
  //                                     ),
  //                             ),
  //                             SizedBox(height: 4.h),
  //                             // Comment Input
  //                             Row(
  //                               children: [
  //                                 Expanded(
  //                                   child: Container(
  //                                     decoration: BoxDecoration(
  //                                       color: Colors.white
  //                                           .withOpacity(0.15),
  //                                       borderRadius:
  //                                           BorderRadius.circular(10.r),
  //                                     ),
  //                                     child: TextField(
  //                                       controller: _commentController,
  //                                       style: TextStyle(
  //                                           color: Colors.white,
  //                                           fontSize: commentFontSize),
  //                                       decoration: InputDecoration(
  //                                         hintText: AppLocalizations.of(context)!.add_comment_hint,
  //                                         hintStyle: TextStyle(
  //                                             color: Colors.white54,
  //                                             fontSize: commentFontSize),
  //                                         border: InputBorder.none,
  //                                         contentPadding:
  //                                             EdgeInsets.symmetric(
  //                                                 horizontal: 8.w,
  //                                                 vertical: 4.h),
  //                                       ),
  //                                       onSubmitted: (value) =>
  //                                           _sendComment(),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 SizedBox(width: 4.w),
  //                                 GestureDetector(
  //                                   onTap: _isProcessing ? null : _sendComment,
  //                                   child: Container(
  //                                     width: isSmallScreen ? 24.w : 28.w,
  //                                     height: isSmallScreen ? 24.w : 28.w,
  //                                     decoration: BoxDecoration(
  //                                       color: MyTheme.accent_color,
  //                                       shape: BoxShape.circle,
  //                                     ),
  //                                     child: _isProcessing
  //                                         ? SizedBox(
  //                                             height: 10.w,
  //                                             width: 10.w,
  //                                             child: CircularProgressIndicator(
  //                                               strokeWidth: 2.w,
  //                                               color: Colors.white,
  //                                             ),
  //                                           )
  //                                         : Icon(Icons.send,
  //                                             size: isSmallScreen ? 12.sp : 14.sp,
  //                                             color: Colors.white),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                     // ============================================
  //                     // PRODUCT NAME & DESCRIPTION
  //                     // ============================================
  //                     Positioned(
  //                       bottom: 90.h,
  //                       left: 12.w,
  //                       right: 12.w,
  //                       child: GestureDetector(
  //                         onTap: _openTitleModal,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(_product?.name ?? '',
  //                                 style: TextStyle(
  //                                     color: Colors.white,
  //                                     fontSize: nameFontSize,
  //                                     fontWeight: FontWeight.bold)),
  //                             SizedBox(height: 2.h),
  //                             Text(
  //                                 _product?.description
  //                                         ?.replaceAll(RegExp(r'<[^>]*>'),
  //                                             '') ??
  //                                     '',
  //                                 style: TextStyle(
  //                                     color: Colors.white70,
  //                                     fontSize: descFontSize),
  //                                 maxLines: 2,
  //                                 overflow: TextOverflow.ellipsis),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                     // ============================================
  //                     // TIMER & CURRENT BID - UPDATED DESIGN
  //                     // ============================================
  //                     Positioned(
  //                       bottom: 16.h,
  //                       left: 12.w,
  //                       right: 12.w,
  //                       child: Container(
  //                         padding: EdgeInsets.all(10.w),
  //                         decoration: BoxDecoration(
  //                           color: const Color(0xFFE8F4F8), // Sky blue background
  //                           borderRadius: BorderRadius.circular(16.r),
  //                           border: Border.all(
  //                             color: MyTheme.accent_color,
  //                             width: 1.5.w,
  //                           ),
  //                         ),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // TIME LEFT Title
  //                             Text(
  //                               AppLocalizations.of(context)!.time_left,
  //                               style: TextStyle(
  //                                 color: Colors.black87,
  //                                 fontSize: timerTitleSize,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                             SizedBox(height: 6.h),
  //                             Row(
  //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                               children: [
  //                                 // Timer with short labels (d, h, m, s) - Inside the box
  //                                 _buildTimerRowWithLabels(),
  //                                 // Current Bid - Centered
  //                                 Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     Text(
  //                                       AppLocalizations.of(context)!.current_bid,
  //                                       style: TextStyle(
  //                                         color: Colors.grey.shade700,
  //                                         fontSize: bidLabelSize,
  //                                         fontWeight: FontWeight.w500,
  //                                       ),
  //                                     ),
  //                                     Text(
  //                                       _formatPrice(_currentHighestBid),
  //                                       style: TextStyle(
  //                                         color: Colors.black87,
  //                                         fontSize: bidPriceSize,
  //                                         fontWeight: FontWeight.bold,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
                  
  //                 // ============================================
  //                 // BID INFORMATION SECTION
  //                 // ============================================
  //                 Transform.translate(
  //                   offset: Offset(0, -15.h),
  //                   child: Container(
  //                     margin: EdgeInsets.symmetric(horizontal: 16.w),
  //                     padding: EdgeInsets.all(16.w),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(16.r),
  //                       border: Border.all(color: Colors.grey.shade200, width: 1.w),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.black.withOpacity(0.08),
  //                           blurRadius: 10.r,
  //                           offset: Offset(0, 4.h),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(AppLocalizations.of(context)!.bid_information,
  //                             style: TextStyle(
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: isSmallScreen ? 14.sp : 16.sp)),
  //                         SizedBox(height: 10.h),
  //                         GridView.count(
  //                           shrinkWrap: true,
  //                           physics: NeverScrollableScrollPhysics(),
  //                           crossAxisCount: 2,
  //                           crossAxisSpacing: 10.w,
  //                           mainAxisSpacing: 10.h,
  //                           childAspectRatio: 3,
  //                           children: [
  //                             _buildInfoItem(
  //                               AppLocalizations.of(context)!.starting_bid,
  //                               _formatPrice(_startingBid),
  //                               isSmallScreen,
  //                             ),
  //                             _buildInfoItem(
  //                               AppLocalizations.of(context)!.total_bidders,
  //                               '$_totalBids',
  //                               isSmallScreen,
  //                             ),
  //                             _buildInfoItem(
  //                               AppLocalizations.of(context)!.highest_bidder,
  //                               _highestBidder.isNotEmpty
  //                                   ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
  //                                   : AppLocalizations.of(context)!.no_bids,
  //                               isSmallScreen,
  //                             ),
  //                             _buildInfoItem(
  //                               AppLocalizations.of(context)!.bid_now_at,
  //                               '$_pointPerBid',
  //                               isSmallScreen,
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
                  
  //                 // ============================================
  //                 // REVIEWS SECTION
  //                 // ============================================
  //                 Container(
  //                   margin: EdgeInsets.symmetric(horizontal: 16.w),
  //                   child: GestureDetector(
  //                     onTap: _openReviewsModal,
  //                     child: Container(
  //                       padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
  //                       decoration: BoxDecoration(
  //                         color: Colors.white,
  //                         borderRadius: BorderRadius.circular(16.r),
  //                         border: Border.all(color: Colors.grey.shade200, width: 1.w),
  //                         boxShadow: [
  //                           BoxShadow(
  //                               color: Colors.black.withOpacity(0.05),
  //                               blurRadius: 4.r,
  //                               offset: Offset(0, 2.h))
  //                         ],
  //                       ),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Row(
  //                                 children: List.generate(5, (index) {
  //                                   return Icon(
  //                                     index < _rating.round()
  //                                         ? Icons.star
  //                                         : Icons.star_border,
  //                                     size: isSmallScreen ? 14.sp : 16.sp,
  //                                     color: Colors.amber,
  //                                   );
  //                                 }),
  //                               ),
  //                               SizedBox(width: 6.w),
  //                               Text(_rating.toStringAsFixed(1),
  //                                   style: TextStyle(
  //                                       fontSize: isSmallScreen ? 14.sp : 16.sp,
  //                                       fontWeight: FontWeight.bold)),
  //                               SizedBox(width: 6.w),
  //                               Container(
  //                                 padding: EdgeInsets.symmetric(
  //                                     horizontal: 6.w, vertical: 2.h),
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.grey.shade100,
  //                                   borderRadius: BorderRadius.circular(20.r),
  //                                 ),
  //                                 child: Text('$_reviewsCount',
  //                                     style: TextStyle(
  //                                         fontSize: isSmallScreen ? 10.sp : 12.sp,
  //                                         color: Colors.grey)),
  //                               ),
  //                             ],
  //                           ),
  //                           Icon(Icons.arrow_forward_ios,
  //                               size: isSmallScreen ? 14.sp : 16.sp, color: Colors.grey),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: 10.h),
                  
  //                 // ============================================
  //                 // THUMBNAILS
  //                 // ============================================
  //                 Container(
  //                   height: isSmallScreen ? 50.h : 70.h,
  //                   margin: EdgeInsets.all(12.w),
  //                   child: ListView.builder(
  //                     scrollDirection: Axis.horizontal,
  //                     itemCount: _productImages.length,
  //                     itemBuilder: (context, index) {
  //                       return GestureDetector(
  //                         onTap: () {
  //                           setState(() => _currentImageIndex = index);
  //                         },
  //                         child: Container(
  //                           width: isSmallScreen ? 44.w : 60.w,
  //                           height: isSmallScreen ? 44.w : 60.w,
  //                           margin: EdgeInsets.only(right: 6.w),
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(10.r),
  //                             border: Border.all(
  //                               color: _currentImageIndex == index
  //                                   ? MyTheme.accent_color
  //                                   : Colors.grey.shade300,
  //                               width: 2.w,
  //                             ),
  //                           ),
  //                           child: ClipRRect(
  //                             borderRadius: BorderRadius.circular(8.r),
  //                             child: Image.network(
  //                               _productImages[index],
  //                               fit: BoxFit.cover,
  //                               errorBuilder: (context, error, stackTrace) =>
  //                                   Icon(Icons.broken_image, color: Colors.grey),
  //                             ),
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 SizedBox(height: 20.h),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // ============================================
  //         // FIXED BOTTOM BAR
  //         // ============================================
  //         Positioned(
  //           bottom: 0,
  //           left: 0,
  //           right: 0,
  //           child: Container(
  //             padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               boxShadow: [
  //                 BoxShadow(
  //                     color: Colors.black12,
  //                     blurRadius: 8.r,
  //                     offset: Offset(0, -2.h))
  //               ],
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton(
  //                     onPressed: _showBidInputDialog,
  //                     style: OutlinedButton.styleFrom(
  //                       padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 14.h),
  //                       shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8.r)),
  //                     ),
  //                     child: Text(
  //                       AppLocalizations.of(context)!.custom_ucf,
  //                       style: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(width: 10.w),
  //                 Expanded(
  //                   flex: 2,
  //                   child: ElevatedButton(
  //                     onPressed: _isProcessing ? null : _placeBidNow,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: MyTheme.accent_color,
  //                       padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 14.h),
  //                       shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8.r)),
  //                     ),
  //                     child: _isProcessing
  //                         ? _buildButtonLoader()
  //                         : Text(
  //                             '${AppLocalizations.of(context)!.bid_now}',
  //                             style: TextStyle(
  //                               fontSize: isSmallScreen ? 12.sp : 14.sp,
  //                               color: Colors.white,
  //                             ),
  //                           ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // ============================================
  //         // MORE MENU OVERLAY
  //         // ============================================
  //         if (_showMoreMenu)
  //           Positioned(
  //             top: MediaQuery.of(context).padding.top + 80.h,
  //             right: 16.w,
  //             child: Material(
  //               elevation: 20,
  //               borderRadius: BorderRadius.circular(16.r),
  //               child: Container(
  //                 width: isSmallScreen ? 150.w : 180.w,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(16.r),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(0.25),
  //                       blurRadius: 15.r,
  //                       offset: Offset(0, 5.h),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     _buildMoreMenuItem(
  //                       icon: Icons.share,
  //                       text: AppLocalizations.of(context)!.share_ucf,
  //                       onTap: () {
  //                         setState(() => _showMoreMenu = false);
  //                         _shareProduct();
  //                       },
  //                       isSmallScreen: isSmallScreen,
  //                     ),
  //                     _buildMoreMenuItem(
  //                       icon: _isInWishlist
  //                           ? Icons.favorite
  //                           : Icons.favorite_border,
  //                       text: _isInWishlist ? AppLocalizations.of(context)!.saved_ucf : AppLocalizations.of(context)!.save_ucf,
  //                       onTap: () {
  //                         setState(() => _showMoreMenu = false);
  //                         _toggleWishlist();
  //                       },
  //                       isSmallScreen: isSmallScreen,
  //                     ),
  //                     _buildMoreMenuItem(
  //                       icon: Icons.contact_mail,
  //                       text: _isProcessing ? AppLocalizations.of(context)!.contacting : AppLocalizations.of(context)!.contact_seller,
  //                       onTap: _isProcessing ? null : () {
  //                         setState(() => _showMoreMenu = false);
  //                         _contactSeller();
  //                       },
  //                       isSmallScreen: isSmallScreen,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // ============================================
  // Icon Circle with Custom Image - Updated with size param
  // ============================================

  Widget _buildIconCircleWithImage({
    required String imagePath,
    required VoidCallback onTap,
    bool isLoading = false,
    IconData? fallbackIcon,
    double size = 48,
  }) {
    final isSmallScreen = size < 44;
    final iconSize = isSmallScreen ? 18.sp : 22.sp;
    final double width = size.w;  
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        height: width,
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
                height: 16.w,
                width: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: MyTheme.accent_color,
                ),
              )
            : Padding(
                padding: EdgeInsets.all(isSmallScreen ? 6.w : 10.w),
                child: Image.asset(
                  imagePath,
                  height: iconSize,
                  width: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (imagePath.contains('product_details')) {
                      return Icon(
                        Icons.info_outline,
                        size: iconSize,
                        color: Colors.black87,
                      );
                    } else if (imagePath.contains('bid_history')) {
                      return Icon(
                        Icons.history,
                        size: iconSize,
                        color: Colors.black87,
                      );
                    }
                    return Icon(
                      Icons.image_not_supported,
                      size: iconSize,
                      color: Colors.black87,
                    );
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return frame == null
                        ? SizedBox(
                            height: iconSize,
                            width: iconSize,
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
  // MOBILE WIDGETS - Updated with responsive sizes
  // ============================================

  Widget _buildIconCircle({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    bool isLoading = false,
    double size = 48,
  }) {
    final isSmallScreen = size < 44;
    final iconSize = isSmallScreen ? 18.sp : 22.sp;
    final double width = size.w;
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        height: width,
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
                height: 16.w,
                width: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: MyTheme.accent_color,
                ),
              )
            : Icon(
                icon,
                color: isActive ? MyTheme.accent_color : Colors.black87,
                size: iconSize,
              ),
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.w : 16.w, vertical: isSmallScreen ? 8.h : 12.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
        ),
        child: Row(
          children: [
            Icon(icon, size: isSmallScreen ? 14.sp : 18.sp, color: Colors.grey.shade700),
            SizedBox(width: isSmallScreen ? 8.w : 12.w),
            Text(text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12.sp : 14.sp,
                  color: Colors.grey.shade800,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4.w : 8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9.sp : 11.sp,
                color: Colors.grey.shade600,
              )),
          SizedBox(height: 2.h),
          Text(value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12.sp : 14.sp,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  // ============================================
  // MOBILE LAYOUT - UPDATED
  // ============================================

  Widget _buildMobileLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.85; // 85% of screen height
    final isSmallScreen = _screenWidth < 380;
    final isMediumScreen = _screenWidth >= 380 && _screenWidth < 480;
    
    // Responsive font sizes - dynamically scale
    final double nameFontSize = isSmallScreen ? 16.sp : (isMediumScreen ? 18.sp : 20.sp);
    final double descFontSize = isSmallScreen ? 10.sp : (isMediumScreen ? 11.sp : 12.sp);
    final double commentFontSize = isSmallScreen ? 8.sp : (isMediumScreen ? 9.sp : 10.sp);
    final double commentNameFontSize = isSmallScreen ? 9.sp : (isMediumScreen ? 10.sp : 11.sp);
    final double badgeFontSize = isSmallScreen ? 6.sp : (isMediumScreen ? 7.sp : 8.sp);
    final double timerTitleSize = isSmallScreen ? 10.sp : (isMediumScreen ? 11.sp : 12.sp);
    final double bidPriceSize = isSmallScreen ? 16.sp : (isMediumScreen ? 18.sp : 20.sp);
    final double bidLabelSize = isSmallScreen ? 9.sp : (isMediumScreen ? 10.sp : 11.sp);
    final double commentsHeight = isSmallScreen ? 200.h : 240.h; // Longer comment section
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main scrollable content
          RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Colors.white,
            onRefresh: _fetchAllData,
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 80.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // IMAGE CAROUSEL WITH OVERLAY
                  // ============================================
                  Stack(
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
                      Container(
                        height: imageHeight,
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
                                    width: isSmallScreen ? 40.w : 48.w,
                                    height: isSmallScreen ? 40.w : 48.w,
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
                                            height: 16.w,
                                            width: 16.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.w,
                                              color: MyTheme.accent_color,
                                            ),
                                          )
                                        : Icon(
                                            Icons.more_vert,
                                            color: Colors.black87,
                                            size: isSmallScreen ? 18.sp : 22.sp,
                                          ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 8.h),
                            _buildIconCircleWithImage(
                              imagePath: 'assets/bid_history.png',
                              onTap: _openBidHistoryModal,
                              isLoading: _isProcessing,
                              fallbackIcon: Icons.history,
                              size: isSmallScreen ? 40.w : 48.w,
                            ),
                            SizedBox(height: 8.h),
                            _buildIconCircleWithImage(
                              imagePath: 'assets/product_details.png',
                              onTap: _openTitleModal,
                              isLoading: _isProcessing,
                              fallbackIcon: Icons.info_outline,
                              size: isSmallScreen ? 40.w : 48.w,
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
                          size: isSmallScreen ? 40.w : 48.w,
                        ),
                      ),
                      // ============================================
                      // COMMENTS SECTION - Updated: Longer height, latest at bottom
                      // ============================================
                      Positioned(
                        bottom: 100.h,
                        left: 12.w,
                        child: Container(
                          width: _screenWidth * 0.78,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15), width: 1.w),
                          ),
                          padding: EdgeInsets.all(8.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Comments List - SCROLLABLE - LONGER HEIGHT
                              Container(
                                height: commentsHeight,
                                child: _comments.isEmpty
                                    ? Center(
                                        child: Text(
                                          AppLocalizations.of(context)!.no_comments_yet,
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: commentFontSize,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _commentsScrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        itemCount: _comments.length,
                                        itemBuilder: (context, index) {
                                          final comment = _comments[index];
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 4.h),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: isSmallScreen ? 10.w : 14.w,
                                                  backgroundImage:
                                                      NetworkImage(comment
                                                              .userAvatar ??
                                                          ''),
                                                  child: comment
                                                          .userAvatar ==
                                                      null
                                                      ? Icon(Icons.person,
                                                          size: isSmallScreen ? 8.sp : 12.sp,
                                                          color: Colors
                                                              .white54)
                                                      : null,
                                                ),
                                                SizedBox(width: 6.w),
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
                                                          fontSize: commentNameFontSize,
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
                                                          fontSize: commentFontSize,
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
                                                                fontSize: badgeFontSize,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8.w),
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
                                                                fontSize: badgeFontSize,
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
                                            BorderRadius.circular(10.r),
                                      ),
                                      child: TextField(
                                        controller: _commentController,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: commentFontSize),
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)!.add_comment_hint,
                                          hintStyle: TextStyle(
                                              color: Colors.white54,
                                              fontSize: commentFontSize),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h),
                                        ),
                                        onSubmitted: (value) =>
                                            _sendComment(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  GestureDetector(
                                    onTap: _isProcessing ? null : _sendComment,
                                    child: Container(
                                      width: isSmallScreen ? 24.w : 28.w,
                                      height: isSmallScreen ? 24.w : 28.w,
                                      decoration: BoxDecoration(
                                        color: MyTheme.accent_color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isProcessing
                                          ? SizedBox(
                                              height: 10.w,
                                              width: 10.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.w,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(Icons.send,
                                              size: isSmallScreen ? 12.sp : 14.sp,
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
                      // PRODUCT NAME & DESCRIPTION
                      // ============================================
                      Positioned(
                        bottom: 90.h,
                        left: 12.w,
                        right: 12.w,
                        child: GestureDetector(
                          onTap: _openTitleModal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_product?.name ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: nameFontSize,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2.h),
                              Text(
                                  _product?.description
                                          ?.replaceAll(RegExp(r'<[^>]*>'),
                                              '') ??
                                      '',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: descFontSize),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      // ============================================
                      // TIMER & CURRENT BID - FIXED: Sky blue only on counter box
                      // ============================================
                      Positioned(
                        bottom: 16.h,
                        left: 12.w,
                        right: 12.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TIME LEFT Title (outside the sky blue box)
                            Text(
                              AppLocalizations.of(context)!.time_left,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: timerTitleSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Timer with sky blue background and accent border (ONLY THIS PART IS SKY BLUE)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F4F8), // Sky blue background
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: MyTheme.accent_color,
                                      width: 1.5.w,
                                    ),
                                  ),
                                  child: _buildTimerRowWithLabels(),
                                ),
                                // Current Bid
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.current_bid,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: bidLabelSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(_currentHighestBid),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: bidPriceSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // ============================================
                  // BID INFORMATION SECTION
                  // ============================================
                  Transform.translate(
                    offset: Offset(0, -15.h),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.bid_information,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14.sp : 16.sp)),
                          SizedBox(height: 10.h),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: 3,
                            children: [
                              _buildInfoItem(
                                AppLocalizations.of(context)!.starting_bid,
                                _formatPrice(_startingBid),
                                isSmallScreen,
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.total_bidders,
                                '$_totalBids',
                                isSmallScreen,
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.highest_bidder,
                                _highestBidder.isNotEmpty
                                    ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                    : AppLocalizations.of(context)!.no_bids,
                                isSmallScreen,
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.bid_now_at,
                                '$_pointPerBid',
                                isSmallScreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // ============================================
                  // REVIEWS SECTION
                  // ============================================
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GestureDetector(
                      onTap: _openReviewsModal,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
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
                                      size: isSmallScreen ? 14.sp : 16.sp,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                SizedBox(width: 6.w),
                                Text(_rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: isSmallScreen ? 14.sp : 16.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text('$_reviewsCount',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 10.sp : 12.sp,
                                          color: Colors.grey)),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: isSmallScreen ? 14.sp : 16.sp, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  
                  // ============================================
                  // THUMBNAILS
                  // ============================================
                  Container(
                    height: isSmallScreen ? 50.h : 70.h,
                    margin: EdgeInsets.all(12.w),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _productImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentImageIndex = index);
                          },
                          child: Container(
                            width: isSmallScreen ? 44.w : 60.w,
                            height: isSmallScreen ? 44.w : 60.w,
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: _currentImageIndex == index
                                    ? MyTheme.accent_color
                                    : Colors.grey.shade300,
                                width: 2.w,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
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
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          // ============================================
          // FIXED BOTTOM BAR
          // ============================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8.r,
                      offset: Offset(0, -2.h))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showBidInputDialog,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.custom_ucf,
                        style: TextStyle(fontSize: isSmallScreen ? 12.sp : 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _placeBidNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              '${AppLocalizations.of(context)!.bid_now}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ============================================
          // MORE MENU OVERLAY
          // ============================================
          if (_showMoreMenu)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80.h,
              right: 16.w,
              child: Material(
                elevation: 20,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  width: isSmallScreen ? 150.w : 180.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15.r,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMoreMenuItem(
                        icon: Icons.share,
                        text: AppLocalizations.of(context)!.share_ucf,
                        onTap: () {
                          setState(() => _showMoreMenu = false);
                          _shareProduct();
                        },
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildMoreMenuItem(
                        icon: _isInWishlist
                            ? Icons.favorite
                            : Icons.favorite_border,
                        text: _isInWishlist ? AppLocalizations.of(context)!.saved_ucf : AppLocalizations.of(context)!.save_ucf,
                        onTap: () {
                          setState(() => _showMoreMenu = false);
                          _toggleWishlist();
                        },
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildMoreMenuItem(
                        icon: Icons.contact_mail,
                        text: _isProcessing ? AppLocalizations.of(context)!.contacting : AppLocalizations.of(context)!.contact_seller,
                        onTap: _isProcessing ? null : () {
                          setState(() => _showMoreMenu = false);
                          _contactSeller();
                        },
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // DESKTOP WIDGETS - Updated with responsive sizes
  // ============================================

  Widget _buildDesktopIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.w : 12.w, vertical: isSmallScreen ? 4.h : 6.h),
        decoration: BoxDecoration(
          color: isActive ? MyTheme.accent_color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200, width: 1.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: isSmallScreen ? 12.sp : 14.sp,
                color: isActive ? Colors.white : Colors.grey.shade600),
            SizedBox(width: 4.w),
            Text(label,
                style: TextStyle(
                    fontSize: isSmallScreen ? 10.sp : 12.sp,
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
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.w : 16.w, vertical: isSmallScreen ? 8.h : 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.w)),
        ),
        child: Row(
          children: [
            Icon(icon, size: isSmallScreen ? 14.sp : 16.sp, color: Colors.grey.shade600),
            SizedBox(width: isSmallScreen ? 8.w : 12.w),
            Text(text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11.sp : 13.sp,
                  color: Colors.grey.shade800,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTimerUnit(String value, String label, {bool isSmallScreen = false}) {
    if (label == 's' && _timeLeft.inDays > 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(left: isSmallScreen ? 4.w : 8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4.w : 6.w, vertical: isSmallScreen ? 1.h : 2.h),
            decoration: BoxDecoration(
              color: _isEndingSoon ? Colors.red : MyTheme.accent_color,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12.sp : 14.sp,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                fontSize: isSmallScreen ? 7.sp : 9.sp,
                color: Colors.grey,
              )),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoItem(String label, String value, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4.w : 8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isSmallScreen ? 8.sp : 10.sp,
                color: Colors.grey,
              )),
          SizedBox(height: 2.h),
          Text(value,
              style: TextStyle(
                fontSize: isSmallScreen ? 11.sp : 13.sp,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}