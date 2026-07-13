import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:active_ecommerce_flutter/screens/chat.dart';
import 'package:active_ecommerce_flutter/repositories/chat_repository.dart';
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
import '../data_model/user_info_response.dart';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/data_model/product_details_response.dart';
import 'package:active_ecommerce_flutter/helpers/main_helpers.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';

class ProductDetails extends StatefulWidget {
  String slug;

  ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin, SingleTickerProviderStateMixin {

  late TabController _tabController;
  late ScrollController _mainScrollController;
  late AnimationController _blinkController;
  late AnimationController _countdownCircleController;
  TextEditingController _commentController = TextEditingController();
  TextEditingController _bidController = TextEditingController();
  TextEditingController _reviewController = TextEditingController();

  // Data
  bool? _myStatus;
  bool _userHasBid = false;
  bool _hasBid = false;
  bool _isListening = false;
  bool _isLoading = true;
  bool _isCommentSoundPlaying = false;
  bool _isBidSoundPlaying = false;
  bool _userInteractedWithComments = false;
  bool _initialScrollDone = false; 
  DetailedProduct? _product;
  UserInformation? _userInfo;
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
  Timer? _upcomingTimer;
  Duration _timeLeft = Duration.zero;
  Duration _timeUntilStart = Duration.zero;
  bool _isEndingSoon = false;
  int _endingSeconds = 10;
  String _auctionStatus = "live";

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
  bool _isTickSoundPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Repository
  final ProductRepository _productRepository = ProductRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  // Refresh indicator key
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Loading state for buttons
  bool _isProcessing = false;

  // Screen width for responsive sizing
  double _screenWidth = 0;

  // Scroll controller for comments to auto-scroll to bottom
  final ScrollController _commentsScrollController = ScrollController();
  
  late CarouselController _fullScreenCarouselController;

  // ✅ Track if we've already triggered auto-scroll for current counter state
  bool _counterScrollTriggered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mainScrollController = ScrollController();
    _fullScreenCarouselController = CarouselController();
    
    // Initialize the countdown circle animation controller
    _countdownCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Add scroll listener for comments
    _commentsScrollController.addListener(() {
      if (_commentsScrollController.position.pixels < 
          _commentsScrollController.position.maxScrollExtent - 10) {
        _userInteractedWithComments = true;
      }
    });
    
    // Listen for when sound stops to restart if needed
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isTickSoundPlaying && _isEndingSoon) {
        print('🔄 Tick sound stopped, restarting...');
        _playTickSound();
      }
    });

    _fetchAllData();
    _startPolling();
    _fetchUserInfo(); 
    
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    _setupLoginStateListener();
    
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _tabController.dispose();
    _mainScrollController.dispose();
    _commentController.dispose();
    _bidController.dispose();
    _reviewController.dispose();
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _upcomingTimer?.cancel();
    _stopTickSound();  // ✅ Stop tick sound on dispose
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _commentsScrollController.dispose();
    super.dispose();
  }

  // ============================================
  // API CALLS
  // ============================================

void _scrollToBottom() {
  if (_commentsScrollController.hasClients && !_userInteractedWithComments) {
    // Small delay to let layout settle after timer rebuilds
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_commentsScrollController.hasClients && !_userInteractedWithComments) {
        _commentsScrollController.animateTo(
          _commentsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ✅ New method: Force scroll to bottom with 1-second delay (respects user interaction)
void _forceScrollToBottomWithDelay() {
  // Reset the interaction flag so scroll can happen
  _userInteractedWithComments = false;
  
  Future.delayed(const Duration(milliseconds: 1000), () {
    if (mounted && _commentsScrollController.hasClients) {
      _commentsScrollController.animateTo(
        _commentsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  });
}

  Future<void> _fetchComments() async {
    try {
      final response =
          await _productRepository.getProductComments(_product?.id ?? 0);
      if (response.success == true && response.comments != null) {
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
    _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _pollData();
    });
  }

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

        // ============================================
        // ✅ Capture myStatus from initial data
        // ============================================
        _myStatus = _product!.myStatus;
        _userHasBid = _product!.userHasBid ?? false;

        _minNextBidNow = _currentHighestBid + 0.01;
        _minNextBid = _currentHighestBid + 1;

        // ============================================
        // DETERMINE AUCTION STATUS
        // ============================================
        _determineAuctionStatus();
      }

      await _fetchComments();
      await _fetchReviews();
      await _fetchBidHistory();
      await _fetchWishlistStatus();

      setState(() => _isLoading = false);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error fetching data: $e');
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_product_details);
      setState(() => _isLoading = false);
    }
  }

  // ============================================
  // DETERMINE AUCTION STATUS
  // ============================================
  
  void _determineAuctionStatus() {
    if (_product == null) return;
    
    final String? upcomingStatus = _product?.upcomingStatus;
    
    if (upcomingStatus == "Upcoming") {
      _auctionStatus = "upcoming";
      _startUpcomingTimer();
      return;
    }
    
    if (_product?.isAuctionEnded == true) {
      _auctionStatus = "ended";
      _timeLeft = Duration.zero;
      return;
    }
    
    _auctionStatus = "live";
    
    if (_product!.getAuctionEndDateTime() != null) {
      final endTime = _product!.getAuctionEndDateTime()!;
      final now = DateTime.now();
      _timeLeft = endTime.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
      _startCountdown(endTime);
    }
  }

  // ============================================
  // UPCOMING TIMER
  // ============================================
  
  void _startUpcomingTimer() {
    _upcomingTimer?.cancel();
    
    DateTime? startDateTime = _product?.getAuctionStartDateTime();
    if (startDateTime == null) {
      _timeUntilStart = Duration.zero;
      return;
    }
    
    _updateUpcomingTimer(startDateTime);
    
    _upcomingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateUpcomingTimer(startDateTime);
    });
  }

  void _updateUpcomingTimer(DateTime startDateTime) {
    final now = DateTime.now();
    final remaining = startDateTime.difference(now);
    
    if (remaining.isNegative) {
      _upcomingTimer?.cancel();
      setState(() {
        _timeUntilStart = Duration.zero;
        _auctionStatus = "live";
      });
      if (_product!.getAuctionEndDateTime() != null) {
        final endTime = _product!.getAuctionEndDateTime()!;
        _startCountdown(endTime);
      }
      return;
    }
    
    setState(() {
      _timeUntilStart = remaining;
    });
  }

  // ============================================
  // ENDING COUNTDOWN TIMER
  // ============================================

  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();
    _stopTickSound();
    
    // Reset the scroll trigger flag
    _counterScrollTriggered = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        _stopTickSound();                    // ← Force stop
        setState(() {
          _timeLeft = Duration.zero;
          _auctionStatus = "ended";
          _isEndingSoon = false;
        });
        
        // ✅ When counter ends, wait 1 second and auto-scroll to latest
        _counterScrollTriggered = false;
        _forceScrollToBottomWithDelay();
        
        _pollData();
        return;
      }

      final secondsLeft = remaining.inSeconds;
      final shouldBeEndingSoon = secondsLeft > 0 && secondsLeft <= _endingSeconds;

      if (shouldBeEndingSoon != _isEndingSoon) {
        setState(() {
          _isEndingSoon = shouldBeEndingSoon;
          // Reset trigger when state changes
          _counterScrollTriggered = false;
        });

        if (shouldBeEndingSoon) {
          // ✅ When counter starts (popup appears), wait 1 second and auto-scroll
          _playTickSound();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _isEndingSoon) {
              _forceScrollToBottomWithDelay();
            }
          });
        } else {
          _stopTickSound();
          // ✅ When counter ends (popup disappears), wait 1 second and auto-scroll
          _forceScrollToBottomWithDelay();
        }
      }

      setState(() => _timeLeft = remaining);
    });
  }

  Future<void> _pollData() async {
    if (_product == null) return;

    try { 
      final response =
          await _productRepository.pollProductData(_product!.id ?? 0);

      if (response.success == true) {
        // ✅ CRITICAL FIX: Update user status from polling
        setState(() {
          if (response.myStatus != null) {
            _myStatus = response.myStatus;
            _userHasBid = true;
          } else {
            _myStatus = null;
            _userHasBid = response.userHasBid ?? false;
          }
        });

        if (response.startingBid != null) {
          setState(() { _startingBid = response.startingBid!; });
        }

        if (response.highestBid != null) {
          final oldHighestBid = _currentHighestBid;
          setState(() { _currentHighestBid = response.highestBid!; });
          
          if (_currentHighestBid > oldHighestBid && response.lastBidderName != null) {
            // _playBidSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
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

        // ============================================
        // UPDATE AUCTION STATUS FROM POLLING
        // ============================================
        if (response.upcomingStatus != null) {
          final newStatus = response.upcomingStatus!;
          if (_auctionStatus != newStatus) {
            setState(() {
              _auctionStatus = newStatus;
            });
            
            if (newStatus == "upcoming") {
              _startUpcomingTimer();
              _countdownTimer?.cancel();
            } else if (newStatus == "live" && response.auctionEndDate != null) {
              _upcomingTimer?.cancel();
              try {
                final endTime = DateTime.parse(response.auctionEndDate!);
                _startCountdown(endTime);
              } catch (e) {
                print('Error parsing auction end date: $e');
              }
            }
          }
        }

        // Update auction end date and timer for active auctions
        if (response.auctionEndDate != null && 
            _auctionStatus == "live") {
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
        // CHECK FOR AUCTION ENDED
        // ============================================
        if (response.auctionEnded == true) {
          setState(() {
            _auctionStatus = "ended";
            _timeLeft = Duration.zero;
            _isEndingSoon = false;
          });
          _countdownTimer?.cancel();
          _countdownCircleController.stop();
          _stopTickSound(); // ✅ Stop tick sound when auction ends
          
          if (response.winner != null && !_winnerModalShown) {
            _winnerData = response.winner;
            _winnerModalShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWinnerModalDialog();
            });
          }
        }

        if (response.rating != null) {
          setState(() { _rating = response.rating!; });
        }
        if (response.reviewsCount != null) {
          setState(() { _reviewsCount = response.reviewsCount!; });
        }

        // In _fetchComments() and _pollData() when comments update:
        if (response.comments != null && response.comments!.isNotEmpty) {
          setState(() => _comments = response.comments!.reversed.toList());
          
          // Only scroll to bottom if user hasn't interacted
          if (!_userInteractedWithComments) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
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

  // ============================================
  // ✅ FIX 2: BLINKING STATUS TEXT - Plain text without container
  // ============================================
  Widget _buildBlinkingStatusText() {
    // Debug logging
    print('🔍 _buildBlinkingStatusText: auctionStatus=$_auctionStatus, userHasBid=$_userHasBid, myStatus=$_myStatus');
    
    // Only show if auction is live and user has bid
    if (_auctionStatus != "live") {
      print('❌ Auction not live: $_auctionStatus');
      return const SizedBox.shrink();
    }
    
    if (_userHasBid != true) {
      print('❌ User has no bid: $_userHasBid');
      return const SizedBox.shrink();
    }
    
    // Determine winning status
    bool isWinning = false;
    
    if (_myStatus != null) {
      isWinning = _myStatus!;
      print('✅ Using myStatus from API: $isWinning');
    } else {
      print('⚠️ myStatus is null, trying to determine from bid history');
      isWinning = _determineWinningStatusFromBids();
      print('✅ Determined from bid history: $isWinning');
    }
    
    final text = isWinning 
        ? "🎉 You are winning!"
        : "😔 You have been outbid";
    
    print('✅ Showing status: ${isWinning ? "Winning" : "Losing"}');
    
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final opacity = 0.3 + (0.7 * _blinkController.value);
        return Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              color: isWinning ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(10, 14),
            ),
          ),
        );
      },
    );
  }

  // Add this method to determine winning status from bid history
  bool _determineWinningStatusFromBids() {
    if (_bidHistory.isEmpty) return false;
    
    final myBids = _bidHistory.where((bid) => 
      bid.userId == _userInfo?.id
    ).toList();
    
    if (myBids.isEmpty) return false;
    
    final myHighestBid = myBids.map((b) => b.amount ?? 0).reduce((a, b) => a > b ? a : b);
    final allBids = _bidHistory.map((b) => b.amount ?? 0).toList();
    final highestBid = allBids.isNotEmpty ? allBids.reduce((a, b) => a > b ? a : b) : 0;
    
    return myHighestBid >= highestBid && highestBid > 0;
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
    
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.auction_not_active);
      return;
    }

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
        // _playBidSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
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
    
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.auction_not_active);
      return;
    }

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
        // _playBidSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
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
        // _playCommentSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
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
  // WISHLIST STATUS
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
  // WISHLIST ACTIONS
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
          // _playCommentSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
          ToastComponent.showSuccess(AppLocalizations.of(context)!.removed_from_wishlist);
        } else {
          // _playBidSound();  // 🚫 COMMENTED OUT - SILENT FOR NOW
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

      print('📡 Contact Seller Response: $response');

      if (response['success'] == true) {
        ToastComponent.showSuccess(response['message'] ?? AppLocalizations.of(context)!.message_sent_to_seller);
        
        final conversationId = response['conversation_id'];
        final data = response['data'] ?? {};
        final sellerName = data['seller_name'] ?? AppLocalizations.of(context)!.seller;
        final productName = data['product_name'] ?? _product?.name ?? '';
        final sellerAvatar = data['seller_avatar'] ?? '';
        
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => Chat(
                    conversation_id: conversationId,
                    messenger_name: sellerName,
                    messenger_title: productName,
                    messenger_image: sellerAvatar,
                  )
                )
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
      print('❌ Error contacting seller: $e');
      ToastComponent.showError(AppLocalizations.of(context)!.error_contacting_seller);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ============================================
  // SOUND EFFECTS - Tick sound tied to popup visibility
  // ============================================

  /*
  // 🚫 COMMENTED OUT - BID SOUND (SILENT FOR NOW)
  void _playBidSound() async {
    if (!_soundEnabled || _isTickSoundPlaying) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/bid_notification.wav'));
    } catch (e) {
      print('Bid sound error: $e');
    }
  }
  */

  /*
  // 🚫 COMMENTED OUT - COMMENT SOUND (SILENT FOR NOW)
  void _playCommentSound() async {
    if (!_soundEnabled || _isTickSoundPlaying) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/comment_sound.wav'));
    } catch (e) {
      print('Comment sound error: $e');
    }
  }
  */

  // ✅ Tick sound - ONLY plays when popup is visible (_isEndingSoon == true)
  void _playTickSound() async {
    if (!_soundEnabled) return;

    // ✅ Only play if popup is visible
    if (!_isEndingSoon) {
      print('⏭️ Popup not visible, skipping tick sound');
      return;
    }

    // If sound is already playing, don't restart it
    if (_isTickSoundPlaying) {
      print('⏭️ Tick sound already playing');
      return;
    }

    try {
      _isTickSoundPlaying = true;
      print('✅ Tick sound STARTED (popup is visible)');

      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/tick_clock.mp3'),
        mode: PlayerMode.lowLatency,
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Tick sound error: $e');
      _isTickSoundPlaying = false;
    }
  }

  // ✅ Stop tick sound - called when popup disappears
  void _stopTickSound() async {
    if (!_isTickSoundPlaying) return;

    print('⏹️ Tick sound STOPPED (popup disappeared)');
    _isTickSoundPlaying = false;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Stop tick error: $e');
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

  String _formatUpcomingTimeLeft() {
    if (_timeUntilStart.isNegative) return '00:00:00';

    final days = _timeUntilStart.inDays;
    final hours = _timeUntilStart.inHours.remainder(24);
    final minutes = _timeUntilStart.inMinutes.remainder(60);
    final seconds = _timeUntilStart.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> _getUpcomingTimeComponents() {
    final days = _timeUntilStart.inDays;
    final hours = _timeUntilStart.inHours.remainder(24);
    final minutes = _timeUntilStart.inMinutes.remainder(60);
    final seconds = _timeUntilStart.inSeconds.remainder(60);

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
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.auction_not_active);
      return;
    }
    
    _bidController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.enter_your_bid,
              style: TextStyle(fontSize: _getResponsiveFontSize(14, 18), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context)!.one_bid_equals} $_pointPerBidCustom',
              style: TextStyle(fontSize: _getResponsiveFontSize(10, 14), color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '${AppLocalizations.of(context)!.min_ucf}: ${_formatPrice(_minNextBidNow)}',
                hintStyle: TextStyle(fontSize: _getResponsiveFontSize(10, 14)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel_ucf,
                      style: TextStyle(fontSize: _getResponsiveFontSize(11, 14), color: Colors.grey.shade600),
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            AppLocalizations.of(context)!.place_bid,
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(11, 14),
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
  // RESPONSIVE HELPER
  // ============================================
  
  double _getResponsiveFontSize(double smallSize, double largeSize) {
    return _screenWidth < 400 ? smallSize : largeSize;
  }

  double _getResponsivePadding(double smallSize, double largeSize) {
    return _screenWidth < 400 ? smallSize : largeSize;
  }

  double _getResponsiveSize(double smallSize, double largeSize) {
    return _screenWidth < 400 ? smallSize : largeSize;
  }

  // ============================================
  // MODAL DIALOGS
  // ============================================

  void _showProductDetailsModal() {
    final modalWidth = _screenWidth * 0.95;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: modalWidth,
          height: MediaQuery.of(context).size.height * 0.80,
          padding: EdgeInsets.all(_getResponsivePadding(6, 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.product_details,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(14, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: _getResponsiveSize(20, 24)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product?.name ?? '',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(16, 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Html(
                        data: _product?.description ?? '',
                        style: {
                          'body': Style(
                            fontSize: FontSize(_getResponsiveFontSize(11, 14)),
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
    final modalWidth = _screenWidth * 0.95;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: modalWidth,
          height: MediaQuery.of(context).size.height * 0.80,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsivePadding(6, 8)),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.bid_history,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(12, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: _getResponsiveSize(18, 22)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(8, 12), vertical: _getResponsivePadding(6, 8)),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppLocalizations.of(context)!.bidder_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveFontSize(7, 10),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        AppLocalizations.of(context)!.amount_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveFontSize(7, 10),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        AppLocalizations.of(context)!.date_time_ucf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveFontSize(7, 10),
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
                          style: TextStyle(fontSize: _getResponsiveFontSize(11, 14)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _bidHistory.length,
                        itemBuilder: (context, index) {
                          final bid = _bidHistory[index];
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(8, 12), vertical: _getResponsivePadding(6, 8)),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    bid.userName ?? AppLocalizations.of(context)!.user_ucf,
                                    style: TextStyle(fontSize: _getResponsiveFontSize(7, 12)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _formatPrice(bid.amount ?? 0),
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(7, 12),
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
                                      fontSize: _getResponsiveFontSize(5, 9),
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
    final modalWidth = _screenWidth * 0.95;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: modalWidth,
              height: MediaQuery.of(context).size.height * 0.90,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsivePadding(6, 8)),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.all_reviews} ($_reviewsCount)',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(12, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: _getResponsiveSize(18, 22)),
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
                              style: TextStyle(fontSize: _getResponsiveFontSize(11, 14)),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(_getResponsivePadding(12, 16)),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(6, 8)),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
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
                                              size: _getResponsiveSize(10, 14),
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          _formatDate(review.createdAt),
                                          style: TextStyle(
                                            fontSize: _getResponsiveFontSize(8, 11),
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      review.comment ?? '',
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(10, 14),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      review.userName ?? AppLocalizations.of(context)!.user_ucf,
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(9, 12),
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
                    padding: EdgeInsets.all(_getResponsivePadding(12, 16)),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
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
                        padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(10, 14)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              AppLocalizations.of(context)!.write_a_review,
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(11, 14),
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
    final modalWidth = _screenWidth * 0.9;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: modalWidth,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(_getResponsivePadding(16, 24)),
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
                          fontSize: _getResponsiveFontSize(14, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: _getResponsiveSize(18, 22)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: _getResponsiveSize(8, 12)),
                  Text(
                    AppLocalizations.of(context)!.rating_ucf,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(11, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(4, 8)),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: _getResponsiveSize(22, 30),
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      tempRating = rating;
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: _getResponsiveSize(8, 12)),
                  Text(
                    AppLocalizations.of(context)!.review_ucf,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(11, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(4, 8)),
                  TextField(
                    controller: tempController,
                    maxLines: 4,
                    style: TextStyle(fontSize: _getResponsiveFontSize(11, 14)),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.share_experience_hint,
                      hintStyle: TextStyle(fontSize: _getResponsiveFontSize(11, 14)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(10, 12), vertical: _getResponsivePadding(8, 12)),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(12, 16)),
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
                      padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(10, 14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(double.infinity, 0),
                    ),
                    child: _isProcessing
                        ? _buildButtonLoader()
                        : Text(
                            AppLocalizations.of(context)!.submit_review,
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(11, 14),
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

    _stopTickSound();  // ✅ Stop tick sound when winner modal shows

    final productId = _product?.id ?? 0;
    final userId = _winnerData?.userId ?? 0;
    final highestBid = _winnerData?.amount ?? 0.0;
    
    print('🏆 Winner - Product ID: $productId, Winner User ID: $userId, Amount: $highestBid');
    
    if (is_logged_in.$ && _winnerData?.userId == _userInfo?.id) {
      print('✅ Current user is the winner! Sending notification...');
      _productRepository.sendWinnerNotification(productId, userId, highestBid);
    } else {
      print('❌ Current user is NOT the winner (or not logged in)');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(_getResponsivePadding(16, 24)),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: _getResponsiveSize(36, 48))),
              SizedBox(height: _getResponsiveSize(4, 8)),
              Text(
                AppLocalizations.of(context)!.auction_ended_exclamation,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(18, 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: _getResponsiveSize(8, 12)),
              CircleAvatar(
                radius: _getResponsiveSize(32, 50),
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null
                    ? Icon(Icons.person, size: _getResponsiveSize(24, 40))
                    : null,
              ),
              SizedBox(height: _getResponsiveSize(6, 10)),
              Text(
                _winnerData!.userName ?? AppLocalizations.of(context)!.winner_ucf,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(14, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: _getResponsiveSize(2, 4)),
              Text(
                _formatPrice(_winnerData!.amount ?? 0),
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(18, 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: _getResponsiveSize(6, 10)),
              Text(
                AppLocalizations.of(context)!.congratulations_to_winner,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(10, 14),
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: _getResponsiveSize(12, 16)),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // ✅ Don't reload the page - just update state
                  setState(() {
                    _winnerModalShown = true;
                  });
                  // Optional: Refresh just the auction status without full reload
                  _pollData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.close_ucf,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(10, 14),
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
                    child: Icon(Icons.close, size: _getResponsiveSize(18, 24), color: Colors.white),
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
  // FULL-SCREEN IMAGE VIEWER
  // ============================================

  void _showFullImageFromThumbnail(int selectedIndex) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          int currentIndex = selectedIndex;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  CarouselSlider(
                    carouselController: _fullScreenCarouselController,
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                      initialPage: selectedIndex,
                      autoPlay: false,
                      enlargeCenterPage: false,
                      scrollPhysics: const BouncingScrollPhysics(),
                      onPageChanged: (index, reason) {
                        currentIndex = index;
                        setModalState(() {});
                      },
                    ),
                    items: _productImages.map((image) {
                      return Builder(
                        builder: (context) => Center(
                          child: PhotoView(
                            imageProvider: NetworkImage(image),
                            backgroundDecoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2.0,
                            initialScale: PhotoViewComputedScale.contained,
                            heroAttributes: PhotoViewHeroAttributes(tag: image),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + _getResponsiveSize(6, 10),
                    right: _getResponsiveSize(11, 19),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(_getResponsiveSize(8, 12)),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: _getResponsiveSize(18, 24),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: _getResponsiveSize(30, 50),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsivePadding(12, 18),
                          vertical: _getResponsivePadding(4, 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(_getResponsiveSize(12, 20)),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${_productImages.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(10, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_productImages.length > 1) ...[
                    Positioned(
                      left: _getResponsiveSize(6, 12),
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (currentIndex > 0) {
                              _fullScreenCarouselController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(_getResponsiveSize(8, 12)),
                            decoration: BoxDecoration(
                              color: currentIndex > 0 
                                  ? Colors.black54 
                                  : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: _getResponsiveSize(16, 22),
                              color: currentIndex > 0 
                                  ? Colors.white 
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: _getResponsiveSize(6, 12),
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (currentIndex < _productImages.length - 1) {
                              _fullScreenCarouselController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(_getResponsiveSize(8, 12)),
                            decoration: BoxDecoration(
                              color: currentIndex < _productImages.length - 1 
                                  ? Colors.black54 
                                  : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: _getResponsiveSize(16, 22),
                              color: currentIndex < _productImages.length - 1 
                                  ? Colors.white 
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // GET USER INFO FOR WINNER CHECK
  // ============================================
  Future<void> _fetchUserInfo() async {
    if (!is_logged_in.$) return;
    try {
      final response = await _profileRepository.getUserInfoResponse();
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _fetchAllData,
              child: _buildMobileLayout(),
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
  // TIMER WIDGETS
  // ============================================

  Widget _buildTimerUnit(String value, String label, {bool isEndingSoon = false, bool showColon = false}) {
    if (label == 's' && _timeLeft.inDays > 0) {
      return const SizedBox.shrink(); 
    }
    
    List<Widget> children = [
      Container(
        margin: EdgeInsets.only(right: _getResponsiveSize(3, 6)),
        padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(5, 9), vertical: _getResponsiveSize(5, 9)),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(_getResponsiveSize(8, 16)),
          border: Border.all(
            color: MyTheme.accent_color,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: _getResponsiveFontSize(14, 19),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: _getResponsiveSize(1.5, 3)),
            Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: _getResponsiveFontSize(7, 11),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ];
    
    if (showColon) {
      children.add(
        Padding(
          padding: EdgeInsets.only(right: _getResponsiveSize(1.5, 3)),
          child: Text(
            ':',
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(12, 19),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // ============================================
  // TIMER ROW
  // ============================================

  Widget _buildTimerRow() {
    if (_auctionStatus == "upcoming") {
      return _buildUpcomingTimerRow();
    } else if (_auctionStatus == "ended") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.auction_ended,
            style: TextStyle(
              color: Colors.red,
              fontSize: _getResponsiveFontSize(10, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            AppLocalizations.of(context)!.no_bids_available,
            style: TextStyle(
              color: Colors.white70,
              fontSize: _getResponsiveFontSize(8, 11),
            ),
          ),
        ],
      );
    } else {
      return _buildEndingTimerRow();
    }
  }

  Widget _buildUpcomingTimerRow() {
    final components = _getUpcomingTimeComponents();
    final days = components['days'] as String;
    final hours = components['hours'] as String;
    final minutes = components['minutes'] as String;
    final seconds = components['seconds'] as String;
    final showDays = components['showDays'] as bool;
    final showSeconds = components['showSeconds'] as bool;

    List<Widget> timerUnits = [];

    if (showDays) {
      timerUnits.add(_buildTimerUnit(days, 'd', showColon: true));
    }
    timerUnits.add(_buildTimerUnit(hours, 'h', showColon: true));
    timerUnits.add(_buildTimerUnit(minutes, 'm', showColon: showSeconds));
    if (showSeconds) {
      timerUnits.add(_buildTimerUnit(seconds, 's', showColon: false));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.starts_in,
          style: TextStyle(
            color: Colors.orange,
            fontSize: _getResponsiveFontSize(8, 11),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: timerUnits,
        ),
      ],
    );
  }

  Widget _buildEndingTimerRow() {
    final components = _getTimeComponents();
    final days = components['days'] as String;
    final hours = components['hours'] as String;
    final minutes = components['minutes'] as String;
    final seconds = components['seconds'] as String;
    final showDays = components['showDays'] as bool;
    final showSeconds = components['showSeconds'] as bool;

    List<Widget> timerUnits = [];

    if (showDays) {
      timerUnits.add(_buildTimerUnit(days, 'd', isEndingSoon: _isEndingSoon, showColon: true));
    }
    timerUnits.add(_buildTimerUnit(hours, 'h', isEndingSoon: _isEndingSoon, showColon: true));
    timerUnits.add(_buildTimerUnit(minutes, 'm', isEndingSoon: _isEndingSoon, showColon: showSeconds));
    if (showSeconds) {
      timerUnits.add(_buildTimerUnit(seconds, 's', isEndingSoon: _isEndingSoon, showColon: false));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEndingSoon 
              ? AppLocalizations.of(context)!.ending_soon_ucf
              : AppLocalizations.of(context)!.time_left,
          style: TextStyle(
            color: _isEndingSoon ? Colors.red : Colors.white70,
            fontSize: _getResponsiveFontSize(8, 11),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: timerUnits,
        ),
      ],
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
    final size = _getResponsiveSize(45, 56);
    final iconSize = _getResponsiveSize(22, 28);
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: size,
        height: size,
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
            ? SizedBox(
                height: _getResponsiveSize(14, 18),
                width: _getResponsiveSize(14, 18),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MyTheme.accent_color,
                ),
              )
            : Padding(
                padding: EdgeInsets.all(_getResponsiveSize(8, 12)),
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
                                strokeWidth: 2,
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
    final size = _getResponsiveSize(45, 56);
    final iconSize = _getResponsiveSize(22, 28);
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: size,
        height: size,
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
            ? SizedBox(
                height: _getResponsiveSize(14, 18),
                width: _getResponsiveSize(14, 18),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(13, 18), vertical: _getResponsivePadding(13, 18)),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: _getResponsiveSize(17, 21), color: Colors.grey.shade700),
            SizedBox(width: _getResponsiveSize(8, 12)),
            Text(text,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(10, 13),
                  color: Colors.grey.shade800,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(6, 10)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_getResponsiveSize(6, 10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(9, 12),
                color: Colors.grey.shade600,
              )),
          SizedBox(height: 1),
          Text(value,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(12, 16),
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  // ============================================
  // MOBILE LAYOUT
  // ============================================

  Widget _buildMobileLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Colors.white,
            onRefresh: _fetchAllData,
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: _getResponsiveSize(60, 80)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      // ✅ FIX: Circular countdown with IgnorePointer
                      if (_isEndingSoon)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Center(
                              child: _buildCircularCountdown(),
                            ),
                          ),
                        ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + _getResponsiveSize(6, 10),
                        right: _getResponsiveSize(10, 18),
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
                                    width: _getResponsiveSize(45, 57),
                                    height: _getResponsiveSize(45, 57),
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
                                    child: _isProcessing
                                        ? SizedBox(
                                            height: _getResponsiveSize(14, 18),
                                            width: _getResponsiveSize(14, 18),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: MyTheme.accent_color,
                                            ),
                                          )
                                        : Icon(
                                            Icons.more_vert,
                                            color: Colors.black87,
                                            size: _getResponsiveSize(20, 28),
                                          ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: _getResponsiveSize(6, 10)),
                            _buildIconCircleWithImage(
                              imagePath: 'assets/bid_history.png',
                              onTap: _openBidHistoryModal,
                              isLoading: _isProcessing,
                              fallbackIcon: Icons.history,
                            ),
                            SizedBox(height: _getResponsiveSize(6, 10)),
                            _buildIconCircleWithImage(
                              imagePath: 'assets/product_details.png',
                              onTap: _openTitleModal,
                              isLoading: _isProcessing,
                              fallbackIcon: Icons.info_outline,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + _getResponsiveSize(6, 10),
                        left: _getResponsiveSize(11, 19),
                        child: _buildIconCircle(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                          isLoading: false,
                        ),
                      ),
                      Positioned(
                        bottom: _getResponsiveSize(135, 175),
                        left: _getResponsiveSize(10, 16),
                        child: Container(
                          width: _screenWidth * 0.74,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.025),
                            borderRadius: BorderRadius.circular(_getResponsiveSize(10, 16)),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.015), width: 1),
                          ),
                          padding: EdgeInsets.all(_getResponsiveSize(6, 10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: _getResponsiveSize(200, 280),
                                child: _comments.isEmpty
                                    ? Center(
                                        child: Text(
                                          AppLocalizations.of(context)!.no_comments_yet,
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: _getResponsiveFontSize(9, 12),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _commentsScrollController,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: _comments.length,
                                        itemBuilder: (context, index) {
                                          final comment = _comments[index];
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: _getResponsiveSize(3, 5)),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: _getResponsiveSize(11, 17),
                                                  backgroundImage:
                                                      NetworkImage(comment
                                                              .userAvatar ??
                                                          ''),
                                                  child: comment
                                                          .userAvatar ==
                                                      null
                                                      ? Icon(Icons.person,
                                                          size: _getResponsiveSize(8, 14),
                                                          color: Colors
                                                              .white54)
                                                      : null,
                                                ),
                                                SizedBox(width: _getResponsiveSize(4, 8)),
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
                                                          fontSize: _getResponsiveFontSize(8, 10),
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
                                                          fontSize: _getResponsiveFontSize(7, 10),
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
                                                                fontSize: _getResponsiveFontSize(6, 9),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: _getResponsiveSize(6, 9)),
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
                                                                fontSize: _getResponsiveFontSize(6, 9),
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
                              SizedBox(height: _getResponsiveSize(4, 6)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: _getResponsiveSize(30, 38),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(_getResponsiveSize(8, 12)),
                                      ),
                                      child: TextField(
                                        controller: _commentController,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: _getResponsiveFontSize(9, 12),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)!.add_comment_hint,
                                          hintStyle: TextStyle(
                                            color: Colors.white54,
                                            fontSize: _getResponsiveFontSize(9, 12),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: _getResponsiveSize(12, 16),
                                            vertical: _getResponsiveSize(6, 10),
                                          ),
                                          isDense: true,
                                        ),
                                        onSubmitted: (value) => _sendComment(),
                                        textAlignVertical: TextAlignVertical.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: _getResponsiveSize(4, 6)),
                                  GestureDetector(
                                    onTap: _isProcessing ? null : _sendComment,
                                    child: Container(
                                      width: _getResponsiveSize(32, 40),
                                      height: _getResponsiveSize(32, 40),
                                      decoration: BoxDecoration(
                                        color: MyTheme.accent_color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isProcessing
                                          ? SizedBox(
                                              height: _getResponsiveSize(8, 12),
                                              width: _getResponsiveSize(8, 12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              Icons.send,
                                              size: _getResponsiveSize(12, 16),
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: _getResponsiveSize(87, 117),
                        left: _getResponsiveSize(10, 16),
                        right: _getResponsiveSize(10, 16),
                        child: GestureDetector(
                          onTap: _openTitleModal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_product?.name ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _getResponsiveFontSize(18, 25),
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: _getResponsiveSize(2, 4)),
                              Text(
                                  _product?.description
                                          ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                                      '',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: _getResponsiveFontSize(9, 12)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              
                              // ✅ FIX 2: Plain blinking text without container
                              if (_auctionStatus == "live" && _userHasBid == true)
                                Padding(
                                  padding: EdgeInsets.only(top: _getResponsiveSize(4, 8)),
                                  child: _buildBlinkingStatusText(),
                                ),
                              
                              SizedBox(height: _getResponsiveSize(1, 2)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: _getResponsiveSize(22, 27),
                        left: _getResponsiveSize(10, 10),
                        right: _getResponsiveSize(10, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: _getResponsiveSize(1, 3),
                                right: _getResponsiveSize(1, 3),
                                top: _getResponsiveSize(1, 1),
                              ),
                              child: _buildTimerRow(),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsivePadding(18, 28), 
                                vertical: _getResponsivePadding(17, 26)
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(_getResponsiveSize(10, 16)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _auctionStatus == "upcoming"
                                        ? AppLocalizations.of(context)!.starting_bid
                                        : (_auctionStatus == "ended"
                                            ? AppLocalizations.of(context)!.final_bid
                                            : AppLocalizations.of(context)!.current_bid),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: _getResponsiveFontSize(7, 10),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(_auctionStatus == "upcoming" 
                                        ? _startingBid 
                                        : _currentHighestBid),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _getResponsiveFontSize(11, 18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Transform.translate(
                    offset: Offset(0, -15),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: _getResponsivePadding(10, 18)),
                      padding: EdgeInsets.all(_getResponsivePadding(10, 18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_getResponsiveSize(10, 18)),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: _getResponsiveSize(6, 10),
                            offset: Offset(0, _getResponsiveSize(2, 4)),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.bid_information,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getResponsiveFontSize(12, 18))),
                          SizedBox(height: _getResponsiveSize(8, 12)),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: _getResponsiveSize(6, 12),
                            mainAxisSpacing: _getResponsiveSize(6, 12),
                            childAspectRatio: 3,
                            children: [
                              _buildInfoItem(
                                AppLocalizations.of(context)!.starting_bid,
                                _formatPrice(_startingBid),
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.total_bidders,
                                '$_totalBids',
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.highest_bidder,
                                _highestBidder.isNotEmpty
                                    ? '${_highestBidder.substring(0, _highestBidder.length > 6 ? 6 : _highestBidder.length)}***'
                                    : AppLocalizations.of(context)!.no_bids,
                              ),
                              _buildInfoItem(
                                AppLocalizations.of(context)!.bid_now_at,
                                '$_pointPerBid',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: _getResponsivePadding(10, 18)),
                    child: GestureDetector(
                      onTap: _openReviewsModal,
                      child: Container(
                        padding: EdgeInsets.all(_getResponsivePadding(12, 18)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_getResponsiveSize(10, 18)),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: _getResponsiveSize(2, 4),
                                offset: Offset(0, _getResponsiveSize(1, 2)))
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
                                      size: _getResponsiveSize(12, 18),
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                SizedBox(width: _getResponsiveSize(4, 8)),
                                Text(_rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: _getResponsiveFontSize(13, 18),
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: _getResponsiveSize(4, 8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: _getResponsiveSize(4, 8), vertical: _getResponsiveSize(2, 4)),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(_getResponsiveSize(14, 22)),
                                  ),
                                  child: Text('$_reviewsCount',
                                      style: TextStyle(
                                          fontSize: _getResponsiveFontSize(9, 13),
                                          color: Colors.grey)),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: _getResponsiveSize(14, 20), color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(8, 14)),
                  
                  Container(
                    height: _getResponsiveSize(60, 80),
                    margin: EdgeInsets.all(_getResponsivePadding(10, 14)),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _productImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showFullImageFromThumbnail(index);
                          },
                          child: Container(
                            width: _getResponsiveSize(48, 68),
                            height: _getResponsiveSize(48, 68),
                            margin: EdgeInsets.only(right: _getResponsiveSize(6, 8)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_getResponsiveSize(8, 12)),
                              border: Border.all(
                                color: _currentImageIndex == index
                                    ? MyTheme.accent_color
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_getResponsiveSize(6, 10)),
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
                  SizedBox(height: _getResponsiveSize(14, 22)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(10, 14), vertical: _getResponsivePadding(8, 12)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: _getResponsiveSize(4, 8),
                      offset: Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _auctionStatus == "live" ? _showBidInputDialog : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _auctionStatus == "live" ? const Color(0xFFE8F4F8) : Colors.grey.shade100,
                        padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(12, 17)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_getResponsiveSize(6, 10))),
                      ),
                      child: Text(
                        _auctionStatus == "upcoming" 
                            ? AppLocalizations.of(context)!.starts_soon
                            : (_auctionStatus == "ended"
                                ? AppLocalizations.of(context)!.ended
                                : AppLocalizations.of(context)!.custom_ucf),
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(11, 16), 
                          color: _auctionStatus == "live" ? MyTheme.accent_color : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _getResponsiveSize(8, 12)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _auctionStatus == "live" && !_isProcessing ? _placeBidNow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _auctionStatus == "live" ? MyTheme.accent_color : Colors.grey,
                        padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(12, 17)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_getResponsiveSize(6, 10))),
                      ),
                      child: _isProcessing
                          ? _buildButtonLoader()
                          : Text(
                              _auctionStatus == "upcoming"
                                  ? AppLocalizations.of(context)!.starts_soon
                                  : (_auctionStatus == "ended"
                                      ? AppLocalizations.of(context)!.auction_ended
                                      : '${AppLocalizations.of(context)!.bid_now} - ${_formatPrice(_minNextBidNow)}'),
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(11, 16),
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showMoreMenu)
            Positioned(
              top: MediaQuery.of(context).padding.top + _getResponsiveSize(70, 90),
              right: _getResponsiveSize(10, 18),
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(_getResponsiveSize(10, 16)),
                child: Container(
                  width: _getResponsiveSize(140, 190),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8),
                    borderRadius: BorderRadius.circular(_getResponsiveSize(10, 16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: _getResponsiveSize(8, 15),
                        offset: Offset(0, _getResponsiveSize(2, 5)),
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
                      ),
                      _buildMoreMenuItem(
                        icon: Icons.contact_mail,
                        text: _isProcessing ? AppLocalizations.of(context)!.contacting : AppLocalizations.of(context)!.contact_seller,
                        onTap: _isProcessing ? null : () {
                          setState(() => _showMoreMenu = false);
                          _contactSeller();
                        },
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
  // ✅ FIX: CIRCULAR COUNTDOWN - Improved overlay
  // ============================================

  Widget _buildCircularCountdown() {
    if (!_isEndingSoon || _timeLeft.inSeconds <= 0) {
      return const SizedBox.shrink();
    }

    final remaining = _timeLeft.inSeconds.clamp(0, _endingSeconds);
    final progress = remaining / _endingSeconds;

    return Container(
      width: _getResponsiveSize(160, 200),
      height: _getResponsiveSize(160, 200),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _getResponsiveSize(120, 160),
            height: _getResponsiveSize(120, 160),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining <= 5 ? Colors.red : Colors.orange,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining.toString(),
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(38, 50),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "sec left",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(12, 15),
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // SEND WINNER NOTIFICATION TO SERVER
  // ============================================
  Future<Map<String, dynamic>> sendWinnerNotification(int productId, int userId, double highestBid) async {
    String url = "${AppConfig.RAW_BASE_URL}/winner-notification";
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$ ?? 'en',
        },
        body: json.encode({
          'product_id': productId,
          'user_id': userId,
          'highest_bid': highestBid,
        }),
      );
      
      print('📤 Winner notification response: ${response.statusCode}');
      print('📤 Winner notification body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send winner notification: ${response.statusCode}');
      }
      
    } catch (e) {
      print("❌ Error in sendWinnerNotification: $e");
      return {
        'success': false,
        'message': 'Network error occurred',
        'status': 500,
      };
    }
  }
}

// ============================================
// CUSTOM PAINTER FOR CIRCULAR TIMER
// ============================================

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularTimerPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.08;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}