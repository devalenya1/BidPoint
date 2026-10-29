import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/data_model/product_details_response.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/chat_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/chat.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data_model/auction_models.dart';
import '../data_model/user_info_response.dart';

class ProductDetails extends StatefulWidget {
  final String slug;
  ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  // =========================
  // DATA
  // =========================
  DetailedProduct? _product;
  UserInformation? _userInfo;
  List<String> _productImages = [];
  List<Comment> _comments = [];
  List<Review> _reviews = [];
  List<BidHistory> _bidHistory = [];
  int _currentImageIndex = 0;
  double _selectedRating = 0;

  // =========================
  // STATE
  // =========================
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isBuyNowLoading = false;
  bool _isInWishlist = false;
  bool _showMoreMenu = false;
  bool _isSendingMessage = false;
  bool _showWinnerModal = false;
  bool _winnerModalShown = false;
  bool _isEndingSoon = false;
  bool _userInteractedWithComments = false;
  bool _isAtBottom = true;

  // =========================
  // TIMER / AUCTION STATE
  // =========================
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Timer? _upcomingTimer;
  Timer? _bellTimer;
  Duration _timeLeft = Duration.zero;
  Duration _timeUntilStart = Duration.zero;
  String _auctionStatus = "live"; // "live" | "upcoming" | "ended"
  int _endingSeconds = 10;
  DateTime? _auctionEndDateTime;

  // =========================
  // BID
  // =========================
  double _currentHighestBid = 0;
  double _minNextBidNow = 0;
  double _startingBid = 0;
  double _pointPerBid = 0;
  double _pointPerBidCustom = 0;
  int _totalBids = 0;
  String _highestBidder = '';
  double _rating = 0;
  int _reviewsCount = 0;
  bool? _myStatus;
  bool _userHasBid = false;

  // points balance
  int _pointBalance = 0;
  bool _isPointBalanceLoading = true;
  Timer? _balanceRefreshTimer;

  // Buy Now
  int _buyNow = 0;
  String _buyNowLink = '';

  // Winner
  Winner? _winnerData;

  // Controllers
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // Animations
  late AnimationController _blinkController;
  late AnimationController _countdownCircleController;

  // Slide to bid
  double _slideOffset = 0;
  double _thumbStartX = 0;
  bool _isDragging = false;
  static const double _thumbSize = 43;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  bool _bellSoundPlayed = false;

  // Repositories
  final ProductRepository _productRepository = ProductRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  // Responsive
  double _screenWidth = 0;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _countdownCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _commentsScrollController.addListener(_onCommentsScroll);

    final prefsBalance =
        int.tryParse(points_balance.$ ?? '0') ??
        double.tryParse(points_balance.$ ?? '0')?.toInt() ??
        0;
    _pointBalance = prefsBalance;
    _isPointBalanceLoading = false;

    _fetchAllData();
    _startPolling();
    _fetchUserInfo();
    _fetchPointBalance();

    _balanceRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchPointBalance(silent: true),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _countdownCircleController.dispose();
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _upcomingTimer?.cancel();
    _bellTimer?.cancel();
    _balanceRefreshTimer?.cancel();
    _commentController.dispose();
    _bidController.dispose();
    _reviewController.dispose();
    _commentsScrollController.dispose();
    _mainScrollController.dispose();
    _audioPlayer.dispose();
    _bellPlayer.dispose();
    ToastComponent.tickSoundPlaying = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.of(context).size.width;
  }

  // ============================================================
  // ROBUST SERVER DATE PARSER
  // ============================================================
  /// Accepts unix seconds, unix millis, unix micros, unix nanos,
  /// ISO strings, and "YYYY-MM-DD HH:mm:ss".
  /// Always returns LOCAL time.
  DateTime? _parseServerDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is DateTime) return raw.toLocal();

      int? n;
      if (raw is int) {
        n = raw;
      } else if (raw is num) {
        n = raw.toInt();
      } else {
        final s = raw.toString().trim();
        if (s.isEmpty) return null;
        if (RegExp(r'^\d+$').hasMatch(s)) {
          n = int.tryParse(s);
          if (n == null) return null;
        } else {
          final normalized = s.contains(' ') && !s.contains('T')
              ? s.replaceFirst(' ', 'T')
              : s;
          return DateTime.parse(normalized).toLocal();
        }
      }

      if (n == null || n <= 0) return null;

      // Detect precision by magnitude:
      //   seconds ~ 1e9    -> *1000
      //   millis  ~ 1e12
      //   micros  ~ 1e15   -> /1000
      //   nanos   ~ 1e18   -> /1e6
      int millis;
      if (n < 100000000000) {
        millis = n * 1000;
      } else if (n < 100000000000000) {
        millis = n;
      } else if (n < 100000000000000000) {
        millis = n ~/ 1000;
      } else {
        millis = n ~/ 1000000;
      }

      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // FETCHING
  // ============================================================

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
        _endingSeconds = _product!.swipeLeft ?? 10;
        _myStatus = _product!.myStatus;
        _userHasBid = _product!.userHasBid ?? false;
        _buyNow = _product!.buyNow ?? 0;
        _buyNowLink = _product!.buyNowLink ?? '';
        _minNextBidNow = _currentHighestBid + 0.01;

        _determineAuctionStatus();
      }

      await _fetchComments();
      await _fetchReviews();
      await _fetchBidHistory();
      await _fetchWishlistStatus();
      await _fetchPointBalance();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _determineAuctionStatus() {
    if (_product == null) return;

    if (_product?.upcomingStatus == "Upcoming") {
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

    // Prefer our own parser on the raw end date, because the server
    // sends epoch seconds (e.g. 1790488740) and the data-model parser
    // may not handle that format.
    DateTime? endTime;
    try {
      final dyn = _product as dynamic;
      endTime = _parseServerDate(dyn.auctionEndDate);
    } catch (_) {}
    endTime ??= _product!.getAuctionEndDateTime();

    if (endTime != null) {
      _auctionEndDateTime = endTime;
      final left = endTime.difference(DateTime.now());
      if (left.isNegative) {
        _auctionStatus = "ended";
        _timeLeft = Duration.zero;
      } else {
        _timeLeft = left;
        _startCountdown(endTime);
      }
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response =
          await _productRepository.getProductComments(_product?.id ?? 0);
      if (response.success == true && response.comments != null) {
        setState(() {
          _comments = response.comments!.reversed.toList();
          _isAtBottom = true;
          _userInteractedWithComments = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
        setState(() {
          _reviews = response.reviews!;
          _reviewsCount = _reviews.length;
        });
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

  Future<void> _fetchWishlistStatus() async {
    if (!is_logged_in.$ || _product == null) return;
    try {
      final result =
          await _productRepository.getWishlistStatus(_product!.id ?? 0);
      if (result['success'] == true) {
        setState(() => _isInWishlist = result['isInWishlist'] ?? false);
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
    }
  }

  Future<void> _fetchUserInfo() async {
    if (!is_logged_in.$) return;
    try {
      final response = await _profileRepository.getUserInfoResponse();
      if (response.success == true &&
          response.data != null &&
          response.data!.isNotEmpty) {
        setState(() => _userInfo = response.data![0]);
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _fetchPointBalance({bool silent = false}) async {
    if (!is_logged_in.$) {
      if (mounted) setState(() => _isPointBalanceLoading = false);
      return;
    }
    try {
      final response = await _profileRepository.getUserInfoResponse();
      int? newBalance;

      if (response.success == true &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final u = response.data![0];
        _userInfo = u;
        final bal = u.balance;
        if (bal != null) {
          newBalance = (bal is num) ? bal.toInt() : int.tryParse('$bal');
        }
      }

      if (newBalance == null) {
        final stored = int.tryParse(points_balance.$ ?? '');
        if (stored != null) newBalance = stored;
      }

      if (newBalance != null && newBalance >= 0) {
        if (mounted) {
          setState(() {
            _pointBalance = newBalance!;
            _isPointBalanceLoading = false;
          });
        }
        final fromServer = response.success == true &&
            response.data != null &&
            response.data!.isNotEmpty &&
            response.data![0].balance != null;
        if (fromServer) {
          points_balance.$ = newBalance.toString();
          points_balance.save();
        }
      } else if (mounted) {
        setState(() => _isPointBalanceLoading = false);
      }
    } catch (e) {
      print('Error fetching point balance: $e');
      if (mounted) setState(() => _isPointBalanceLoading = false);
    }
  }

  void _applyBalanceFromPoll(PollDataResponse response) {
    final b = response.balance;
    if (b == null || b <= 0) return;
    if (b == _pointBalance) return;
    setState(() {
      _pointBalance = b;
      _isPointBalanceLoading = false;
    });
    points_balance.$ = b.toString();
    points_balance.save();
  }

  // ============================================================
  // POLLING
  // ============================================================

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollData(),
    );
  }

  Future<void> _pollData() async {
    if (_product == null) return;

    try {
      final response =
          await _productRepository.pollProductData(_product!.id ?? 0);
      if (response.success != true) return;

      setState(() {
        _applyBalanceFromPoll(response);

        if (response.myStatus != null) {
          _myStatus = response.myStatus;
          _userHasBid = true;
        } else {
          _myStatus = null;
          _userHasBid = response.userHasBid ?? false;
        }

        if (response.startingBid != null) _startingBid = response.startingBid!;

        if (response.highestBid != null) {
          final old = _currentHighestBid;
          _currentHighestBid = response.highestBid!;
          if (_currentHighestBid > old && response.lastBidderName != null) {
            ToastComponent.showInfo(
              '${response.lastBidderName} ${AppLocalizations.of(context)!.placed_a_bid_of} ${_formatPrice(_currentHighestBid)}',
            );
          }
        }

        if (response.totalBids != null) _totalBids = response.totalBids!;
        if (response.lastBidderName != null &&
            response.lastBidderName!.isNotEmpty) {
          _highestBidder = response.lastBidderName!;
        }
        if (response.pointPerBid != null) _pointPerBid = response.pointPerBid!;
        if (response.pointPerBidCustom != null) {
          _pointPerBidCustom = response.pointPerBidCustom!;
        }
        if (response.buyNow != null) _buyNow = response.buyNow!;
        if (response.buyNowLink != null) _buyNowLink = response.buyNowLink!;

        _minNextBidNow = _currentHighestBid + 0.01;

        // Status change handling
        if (response.upcomingStatus != null) {
          final newStatus = response.upcomingStatus!;
          if (_auctionStatus != newStatus) {
            _auctionStatus = newStatus;
            if (newStatus == "upcoming") {
              _startUpcomingTimer();
              _countdownTimer?.cancel();
            } else if (newStatus == "live" &&
                response.auctionEndDate != null) {
              _upcomingTimer?.cancel();
              final endTime = _parseServerDate(response.auctionEndDate);
              if (endTime != null) {
                _auctionEndDateTime = endTime;
                final left = endTime.difference(DateTime.now());
                if (left.isNegative) {
                  _auctionStatus = "ended";
                  _timeLeft = Duration.zero;
                } else {
                  _timeLeft = left;
                  _startCountdown(endTime);
                }
              }
            }
          }
        }

        // End date changed — restart countdown ONLY if the server
        // actually moved the end time (>5s tolerance), otherwise we
        // kill and re-create the timer every 2s and it looks frozen.
        if (response.auctionEndDate != null && _auctionStatus == "live") {
          final newEnd = _parseServerDate(response.auctionEndDate);
          if (newEnd != null) {
            final changed = _auctionEndDateTime == null ||
                newEnd
                        .difference(_auctionEndDateTime!)
                        .inSeconds
                        .abs() >
                    5;
            if (changed) {
              _auctionEndDateTime = newEnd;
              final left = newEnd.difference(DateTime.now());
              if (left.isNegative) {
                _auctionStatus = "ended";
                _timeLeft = Duration.zero;
                _countdownTimer?.cancel();
              } else {
                _timeLeft = left;
                _startCountdown(newEnd);
              }
            }
          }
        }

        if (response.auctionEnded == true) {
          _auctionStatus = "ended";
          _timeLeft = Duration.zero;
          _auctionEndDateTime = null;
          _isEndingSoon = false;
          _bellSoundPlayed = false;
          _countdownTimer?.cancel();
          _countdownCircleController.stop();
        }

        if (response.rating != null) _rating = response.rating!;
        if (response.reviewsCount != null) _reviewsCount = response.reviewsCount!;

        if (response.comments != null && response.comments!.isNotEmpty) {
          _comments = response.comments!.reversed.toList();
          if (_isAtBottom && !_userInteractedWithComments) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
          }
        }

        if (response.reviews != null && response.reviews!.isNotEmpty) {
          _reviews = response.reviews!;
          _reviewsCount = _reviews.length;
        }

        if (response.bidHistory != null && response.bidHistory!.isNotEmpty) {
          _bidHistory = response.bidHistory!.map((item) {
            return BidHistory(
              userId: item.userId,
              userName: item.userName,
              amount: item.amount,
              createdAt: item.createdAt,
            );
          }).toList();
        }
      });

      if (response.balance == null || response.balance! <= 0) {
        await _fetchPointBalance(silent: true);
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
    } catch (e) {
      print('Polling error: $e');
    }
  }

  // ============================================================
  // TIMERS
  // ============================================================
  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _timeLeft = Duration.zero;
          _auctionStatus = "ended";
          _isEndingSoon = false;
          _bellSoundPlayed = false;
        });
        _pollData();
        return;
      }

      final seconds = remaining.inSeconds;
      final shouldEnd = seconds > 0 && seconds <= _endingSeconds;

      if (shouldEnd != _isEndingSoon) {
        setState(() => _isEndingSoon = shouldEnd);
        if (shouldEnd && !_bellSoundPlayed) {
          _bellSoundPlayed = true;
          _playBell();
          _countdownCircleController.repeat();
        } else if (!shouldEnd) {
          _countdownCircleController.stop();
        }
      }

      if (mounted) {
        setState(() => _timeLeft = remaining);
      }
    });
  }

  void _startUpcomingTimer() {
    _upcomingTimer?.cancel();
    final start = _product?.getAuctionStartDateTime();
    if (start == null) return;

    _tickUpcoming(start);
    _upcomingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickUpcoming(start),
    );
  }

  void _tickUpcoming(DateTime start) {
    final remaining = start.difference(DateTime.now());
    if (remaining.isNegative) {
      _upcomingTimer?.cancel();
      setState(() {
        _timeUntilStart = Duration.zero;
        _auctionStatus = "live";
      });
      final endTime = _product!.getAuctionEndDateTime();
      if (endTime != null) {
        _auctionEndDateTime = endTime;
        _startCountdown(endTime);
      }
      return;
    }
    if (mounted) setState(() => _timeUntilStart = remaining);
  }

  Future<void> _playBell() async {
    try {
      await _bellPlayer.stop();
      await _bellPlayer.setReleaseMode(ReleaseMode.release);
      await _bellPlayer.play(
        AssetSource('sounds/bell1.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 0.85,
      );
      ToastComponent.tickSoundPlaying = true;
    } catch (_) {}
  }

  // ============================================================
  // COMMENTS SCROLL
  // ============================================================
  void _onCommentsScroll() {
    if (!_commentsScrollController.hasClients) return;
    final max = _commentsScrollController.position.maxScrollExtent;
    final cur = _commentsScrollController.position.pixels;
    final atBottom = cur >= max - 30;
    if (atBottom != _isAtBottom) setState(() => _isAtBottom = atBottom);
    if (!atBottom && cur < max - 80) {
      _userInteractedWithComments = true;
    } else if (atBottom) {
      _userInteractedWithComments = false;
    }
  }

  void _scrollToBottom() {
    if (_commentsScrollController.hasClients &&
        _isAtBottom &&
        !_userInteractedWithComments) {
      _commentsScrollController.animateTo(
        _commentsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================
  Future<void> _placeBidNow() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.auction_not_active);
      return;
    }

    final amount = _minNextBidNow;
    setState(() => _isProcessing = true);

    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
        type: "quick",
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response.success == true) {
        if (response.timeExtended == true && response.newEndDate != null) {
          ToastComponent.showSuccess(response.message ??
              AppLocalizations.of(context)!.auction_time_extended);
          final newEnd = _parseServerDate(response.newEndDate);
          if (newEnd != null) {
            _auctionEndDateTime = newEnd;
            _startCountdown(newEnd);
          }
        } else {
          ToastComponent.showSuccess(
              response.message ??
                  '${AppLocalizations.of(context)!.bid_placed} ${_formatPrice(amount)}');
        }
        await _pollData();
        await _fetchPointBalance(silent: true);
      } else {
        ToastComponent.showError(response.message ??
            AppLocalizations.of(context)!.something_went_wrong);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(AppLocalizations.of(context)!.error_placing_bid);
    }
  }

  Future<void> _submitCustomBid() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.auction_not_active);
      return;
    }

    final amount = double.tryParse(_bidController.text);
    if (amount == null || amount < _minNextBidNow) {
      ToastComponent.showWarning(
          '${AppLocalizations.of(context)!.bid_must_be_at_least} ${_formatPrice(_minNextBidNow)}');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
        type: "custom",
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response.success == true) {
        _bidController.clear();
        ToastComponent.showSuccess(
            response.message ?? AppLocalizations.of(context)!.bid_placed);
        await _pollData();
        await _fetchPointBalance(silent: true);
      } else {
        ToastComponent.showError(response.message ??
            AppLocalizations.of(context)!.error_placing_bid);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(AppLocalizations.of(context)!.error_placing_bid);
    }
  }

  Future<void> _sendComment() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.please_enter_comment);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response =
          await _productRepository.addProductComment(_product!.id ?? 0, text);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response.success == true) {
        _commentController.clear();
        await _fetchComments();
        ToastComponent.showSuccess(
            AppLocalizations.of(context)!.comment_added);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        ToastComponent.showError(response.message ??
            AppLocalizations.of(context)!.error_adding_comment);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(
          AppLocalizations.of(context)!.error_adding_comment);
    }
  }

  Future<void> _submitReview() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;
    if (_selectedRating == 0) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.please_select_rating);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.please_write_review);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await _productRepository.addProductReview(
          _product!.id ?? 0, _selectedRating.toInt(), _reviewController.text);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response.success == true) {
        ToastComponent.showSuccess(
            AppLocalizations.of(context)!.review_submitted);
        _selectedRating = 0;
        _reviewController.clear();
        Navigator.pop(context);
        await _fetchReviews();
        await _pollData();
      } else {
        ToastComponent.showError(response.message ??
            AppLocalizations.of(context)!.error_submitting_review);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(
          AppLocalizations.of(context)!.error_submitting_review);
    }
  }

  Future<void> _toggleWishlist() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;

    final wasIn = _isInWishlist;
    setState(() {
      _isProcessing = true;
      _isInWishlist = !wasIn;
    });

    try {
      WishlistResponse response;
      if (wasIn) {
        response =
            await _productRepository.removeFromWishlist(_product!.id ?? 0);
      } else {
        response = await _productRepository.addToWishlist(_product!.id ?? 0);
      }

      if (response.success == true) {
        ToastComponent.showSuccess(
            wasIn
                ? AppLocalizations.of(context)!.removed_from_wishlist
                : AppLocalizations.of(context)!.added_to_wishlist);
        await _fetchWishlistStatus();
      } else {
        setState(() => _isInWishlist = wasIn);
        ToastComponent.showError(
            AppLocalizations.of(context)!.wishlist_update_failed);
      }
    } catch (_) {
      setState(() => _isInWishlist = wasIn);
      ToastComponent.showError(
          AppLocalizations.of(context)!.wishlist_update_failed);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _contactSeller() async {
    if (!is_logged_in.$) return _showLoginRequired();
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final response =
          await _productRepository.contactSeller(_product!.id ?? 0);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response['success'] == true) {
        ToastComponent.showSuccess(response['message'] ??
            AppLocalizations.of(context)!.message_sent_to_seller);
        final data = response['data'] ?? {};
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chat(
                  conversation_id: response['conversation_id'],
                  messenger_name: data['seller_name'] ??
                      AppLocalizations.of(context)!.seller,
                  messenger_title:
                      data['product_name'] ?? _product?.name ?? '',
                  messenger_image: data['seller_avatar'] ?? '',
                ),
              ),
            );
          }
        });
      } else {
        ToastComponent.showError(response['message'] ??
            AppLocalizations.of(context)!.failed_to_contact_seller);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(
          AppLocalizations.of(context)!.error_contacting_seller);
    }
  }

  void _onBuyNowPressed() async {
    if (_isBuyNowLoading) return;
    if (_buyNowLink.isEmpty) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.payment_link_unavailable);
      return;
    }

    setState(() => _isBuyNowLoading = true);
    try {
      await _productRepository.trackBuyNowClick(_product?.id ?? 0);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommonWebviewScreen(
            page_name: AppLocalizations.of(context)!.buy_now_ucf,
            url: _buyNowLink,
          ),
        ),
      );
    } catch (_) {
      ToastComponent.showError(
          AppLocalizations.of(context)!.failed_to_open_payment);
    } finally {
      if (mounted) setState(() => _isBuyNowLoading = false);
    }
  }

  void _showLoginRequired() {
    ToastComponent.showWarning(
        AppLocalizations.of(context)!.please_login_to_continue);
    Navigator.push(context, MaterialPageRoute(builder: (_) => Login()));
  }

  // ============================================================
  // FORMATTING
  // ============================================================
  String _formatPrice(double amount) => FormatHelper.formatPrice(amount);

  /// Always renders "Xd HH:MM:SS" — days, hours, minutes and seconds.
  /// This is what the summary card shows, so it always ticks (seconds
  /// change every 1s).
  String _formatTimeLeft(Duration d) {
    if (d.isNegative) d = Duration.zero;

    final days = d.inDays;
    final h = d.inHours.remainder(24);
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    if (days > 0) return '${days}d $hh:$mm:$ss';
    return '$hh:$mm:$ss';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final d = DateTime.parse(dateTime);
      return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year} · '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _videoIdFromUrl(String url) {
    try {
      final reg = RegExp(
          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})');
      final m = reg.firstMatch(url);
      return m?.group(1) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf5f9fd),
        body: _buildShimmer(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf5f9fd),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _fetchAllData,
          color: MyTheme.accent_color,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildStage()),
              SliverToBoxAdapter(child: _buildPhotoRail()),
              SliverToBoxAdapter(child: _buildSummary()),
              SliverToBoxAdapter(child: _buildHowItWorks()),
              if (_buyNow == 1 && _auctionStatus != "ended")
                SliverToBoxAdapter(child: _buildBuyNowCard()),
              SliverToBoxAdapter(child: SizedBox(height: 110.h)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBidDock(),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================
  Widget _buildTopBar() {
    return Container(
      height: 60.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE4EDF6))),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/app_logo.png',
            height: 36.h,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'Logo',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1),
            ),
          ),
          const Spacer(),
          if (is_logged_in.$)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFecfcfa),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: const Color(0xFFb8ecea)),
              ),
              child: _isPointBalanceLoading
                  ? SizedBox(
                      width: 12.w,
                      height: 12.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 1.5, color: Color(0xFF007d7f)),
                    )
                  : Text(
                      '✦ $_pointBalance ${AppLocalizations.of(context)!.points_ucf}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF007d7f),
                      ),
                    ),
            ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: () =>
                is_logged_in.$ ? Navigator.pop(context) : _showLoginRequired(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFedf6ff),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    is_logged_in.$ ? Icons.arrow_back : Icons.login,
                    size: 14.sp,
                    color: const Color(0xFF1870d5),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    is_logged_in.$
                        ? AppLocalizations.of(context)!.exit_ucf ?? 'Exit'
                        : AppLocalizations.of(context)!.login_ucf,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1870d5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAGE
  // ============================================================
  Widget _buildStage() {
    final isMobile = _screenWidth < 800;
    final double stageHeight = isMobile
        ? max(600.0, _screenWidth * 1.15)
        : min(_screenWidth * 0.85, 780.0);

    final bottomPad = 13.h + MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.zero,
      height: stageHeight,
      decoration: const BoxDecoration(color: Color(0xFF142337)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Main image — cover
          Positioned.fill(
            child: _productImages.isEmpty
                ? Container(color: const Color(0xFF1a2a3e))
                : Image.network(
                    _productImages[_currentImageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, color: Colors.white54, size: 60),
                  ),
          ),

          // ── Gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x85051C29),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x94051425),
                      Color(0xF7051121),
                    ],
                    stops: [0.0, 0.22, 0.4, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Chat overlay
          Positioned(
            left: 13.w,
            right: 13.w,
            bottom: bottomPad,
            height: min(stageHeight * 0.42, 320.0),
            child: _buildChatOverlay(),
          ),

          // ── Floating icons (top-right)
          Positioned(
            top: 13.h,
            right: 13.w,
            child: _buildActionCircles(),
          ),

          // ── Status badge (top-left)
          Positioned(
            top: 13.h,
            left: 13.w,
            child: _buildStatusBadge(),
          ),

          // ── More menu (highest z)
          if (_showMoreMenu)
            Positioned(
              top: 60.h,
              right: 9.w,
              child: Material(
                color: Colors.transparent,
                elevation: 24,
                shadowColor: Colors.black54,
                child: _buildMoreMenu(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color bg;
    Color border;

    if (_auctionStatus == "ended") {
      label = AppLocalizations.of(context)!.status_ended_ucf;
      bg = const Color(0xB80B2038);
      border = const Color(0x3BFFFFFF);
    } else if (_userHasBid && _myStatus != null) {
      final winning = _myStatus == true;
      label = winning
          ? AppLocalizations.of(context)!.status_winning_ucf
          : AppLocalizations.of(context)!.status_outbid_ucf;
      bg = winning ? const Color(0xEB047E60) : const Color(0xEDAC2848);
      border = winning ? const Color(0xFF62F3C8) : const Color(0xFFFFB3C2);
    } else if (_auctionStatus == "upcoming") {
      label = AppLocalizations.of(context)!.status_upcoming_ucf;
      bg = const Color(0xB80B2038);
      border = const Color(0x3BFFFFFF);
    } else {
      label = AppLocalizations.of(context)!.status_live_ucf;
      bg = const Color(0xB80B2038);
      border = const Color(0x3BFFFFFF);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.w,
            height: 7.w,
            decoration: const BoxDecoration(
              color: Color(0xFF9EFFD6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircles() {
    return Column(
      children: [
        _actionCircle(
          icon: Icons.more_vert,
          onTap: () => setState(() => _showMoreMenu = !_showMoreMenu),
        ),
        SizedBox(height: 9.h),
        _actionCircle(
          icon: Icons.share_outlined,
          onTap: () {
            Share.share(_product?.link ?? AppConfig.RAW_BASE_URL);
          },
        ),
        SizedBox(height: 9.h),
        _actionCircle(
          icon: Icons.play_arrow_rounded,
          onTap: _openVideoModal,
        ),
        SizedBox(height: 9.h),
        _actionCircle(
          icon: Icons.history,
          onTap: _openBidHistoryModal,
        ),
      ],
    );
  }

  Widget _actionCircle({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43.w,
        height: 43.w,
        decoration: BoxDecoration(
          color: const Color(0xB5071D35),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x75FFFFFF)),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      width: 236.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: const Color(0xFFE0EDF7)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 44, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showMoreMenu = false),
            child: Container(
              margin: EdgeInsets.only(bottom: 5.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7FC),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Row(
                children: [
                  Text(
                    'Options',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102C4C)),
                  ),
                  const Spacer(),
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(Icons.close,
                        size: 18.sp, color: const Color(0xFF102C4C)),
                  ),
                ],
              ),
            ),
          ),
          _moreMenuItem(
            icon: Icons.info_outline,
            label: 'Information',
            onTap: () {
              setState(() => _showMoreMenu = false);
              _showInformationModal();
            },
          ),
          _moreMenuItem(
            icon: _isInWishlist ? Icons.favorite : Icons.favorite_border,
            label:
                _isInWishlist ? 'Remove from favorites' : 'Add to favorites',
            onTap: () {
              setState(() => _showMoreMenu = false);
              _toggleWishlist();
            },
          ),
          _moreMenuItem(
            icon: Icons.mail_outline,
            label: 'Contact seller',
            onTap: () {
              setState(() => _showMoreMenu = false);
              _contactSeller();
            },
          ),
        ],
      ),
    );
  }

  Widget _moreMenuItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: const Color(0xFF102C4C)),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF102C4C)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHAT OVERLAY (full width + safe area)
  // ============================================================
  Widget _buildChatOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: _comments.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _commentsScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: _comments.length,
                  itemBuilder: (context, i) {
                    final c = _comments[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (c.userAvatar != null && c.userAvatar!.isNotEmpty)
                            ClipOval(
                              child: Image.network(
                                c.userAvatar!,
                                width: 28.w,
                                height: 28.w,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                          if (c.userAvatar != null && c.userAvatar!.isNotEmpty)
                            SizedBox(width: 6.w),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: const Color(0xB507192A),
                                borderRadius: BorderRadius.circular(13.r),
                                border:
                                    Border.all(color: const Color(0x18FFFFFF)),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${c.userName ?? 'User'}: ',
                                      style: const TextStyle(
                                          color: Color(0xFF7BE8E9),
                                          fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(text: c.comment ?? ''),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xC906172E),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(color: const Color(0x47FFFFFF)),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      hintText: AppLocalizations.of(context)!.type_in_chat_ucf,
                      hintStyle: TextStyle(
                          color: const Color(0xFFD1DBE6), fontSize: 13.sp),
                    ),
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _isProcessing ? null : _sendComment,
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0ABFC4),
                    shape: BoxShape.circle,
                  ),
                  child: _isProcessing
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.send_rounded,
                          color: const Color(0xFF05394B), size: 20.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PHOTO RAIL
  // ============================================================
  Widget _buildPhotoRail() {
    if (_productImages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0B15365A), blurRadius: 25, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.product_photos_ucf,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF102C4C),
            ),
          ),
          SizedBox(width: 9.w),
          GestureDetector(
            onTap: () => _openPhotoViewer(_currentImageIndex),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFC8E6F1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search,
                      size: 13.sp, color: const Color(0xFF087E99)),
                  SizedBox(width: 4.w),
                  Text(
                    AppLocalizations.of(context)!.view_photos_ucf ??
                        'View photos',
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF087E99)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: SizedBox(
              height: 58.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _productImages.length,
                separatorBuilder: (_, __) => SizedBox(width: 9.w),
                itemBuilder: (context, index) {
                  final active = index == _currentImageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentImageIndex = index),
                    child: Container(
                      width: 53.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF0ABFC4)
                              : const Color(0xFFE0EAF2),
                          width: active ? 3 : 2,
                        ),
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _productImages[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                            size: 22),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '${_currentImageIndex + 1} / ${_productImages.length}',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF637A92),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhotoViewer(int index) {
    if (_productImages.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE4EDF6))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1} / ${_productImages.length}',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF102C4C)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDF4FB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 23.sp, color: const Color(0xFF102C4C)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: PageController(initialPage: index),
                    itemCount: _productImages.length,
                    itemBuilder: (_, i) => PhotoView(
                      imageProvider: NetworkImage(_productImages[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY — timer / price / leader
  // ============================================================
  Widget _buildSummary() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0B15365A), blurRadius: 25, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product?.name ?? '',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF102C4C),
              letterSpacing: -0.5,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 9.h),
          Row(
            children: [
              Expanded(child: _metricTimer()),
              SizedBox(width: 6.w),
              Expanded(child: _metricPrice()),
              SizedBox(width: 6.w),
              Expanded(child: _metricLeader()),
            ],
          ),
        ],
      ),
    );
  }

  // ═══ Left-aligned metric box — label AND value start at the left ═══
  Widget _metricBox({
    required String label,
    required Widget child,
    Color? bgColor,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF1F7FB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDCEAF5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: labelColor ?? const Color(0xFF637A92),
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: valueColor ?? const Color(0xFF102C4C),
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _metricTimer() {
    String label;
    String value;
    Color? valColor;

    if (_auctionStatus == "upcoming") {
      label = '⏱ ${AppLocalizations.of(context)!.starts_in_upper}';
      value = _formatTimeLeft(_timeUntilStart);
    } else if (_auctionStatus == "ended") {
      label = '⏱ ${AppLocalizations.of(context)!.ended_upper}';
      value = '—';
    } else {
      label =
          '⏱ ${_isEndingSoon ? AppLocalizations.of(context)!.ending_upper : AppLocalizations.of(context)!.time_left_upper}';
      value = _formatTimeLeft(_timeLeft);
      if (_isEndingSoon) valColor = const Color(0xFFDC3545);
    }

    return _metricBox(
      label: label,
      child: Text(
        value,
        textAlign: TextAlign.left,
        style: TextStyle(color: valColor ?? const Color(0xFF008E9D)),
      ),
      valueColor: valColor ?? const Color(0xFF008E9D),
    );
  }

  Widget _metricPrice() {
    return _metricBox(
      label: AppLocalizations.of(context)!.current_bid_upper,
      child: Text(
        _formatPrice(
            _auctionStatus == "upcoming" ? _startingBid : _currentHighestBid),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _metricLeader() {
    final display = _highestBidder.isEmpty
        ? '—'
        : (_highestBidder.length > 7
            ? '${_highestBidder.substring(0, 7)}...'
            : _highestBidder);
    return _metricBox(
      label: AppLocalizations.of(context)!.latest_bid_upper,
      child: Text(display, textAlign: TextAlign.left),
    );
  }

  // ============================================================
  // HOW IT WORKS
  // ============================================================
  Widget _buildHowItWorks() {
    final isMobile = _screenWidth < 700;
    final steps = [
      {
        'num': '1',
        'icon': '☝️',
        'title': AppLocalizations.of(context)!.how_step1_title,
        'desc': AppLocalizations.of(context)!.how_step1_desc,
      },
      {
        'num': '2',
        'icon': '⏱️',
        'title': AppLocalizations.of(context)!.how_step2_title,
        'desc': AppLocalizations.of(context)!.how_step2_desc,
      },
      {
        'num': '3',
        'icon': '🏆',
        'title': AppLocalizations.of(context)!.how_step3_title,
        'desc': AppLocalizations.of(context)!.how_step3_desc,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0B15365A), blurRadius: 25, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.how_title,
            style: TextStyle(
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF102C4C),
              letterSpacing: -0.45,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            AppLocalizations.of(context)!.how_subtitle,
            style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF637A92)),
          ),
          SizedBox(height: 19.h),
          if (isMobile)
            Column(
              children: steps.map((s) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  child: _howStep(s, showBorder: false),
                );
              }).toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((e) {
                final isLast = e.key == steps.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 13.w),
                    child: _howStep(e.value, showBorder: !isLast),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 16.h),
          Divider(color: const Color(0xFFE4EDF6)),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.how_note1,
            style: TextStyle(
                fontSize: 12.sp, color: const Color(0xFF637A92), height: 1.5),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.how_note2,
            style: TextStyle(
                fontSize: 12.sp, color: const Color(0xFF637A92), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _howStep(Map<String, String> s, {required bool showBorder}) {
    return Container(
      padding: EdgeInsets.only(right: showBorder ? 9.w : 0),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE4EDF6))))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25.w,
            height: 25.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1870D5), Color(0xFF0ABFC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              s['num']!,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 9.w),
          Text(s['icon']!, style: TextStyle(fontSize: 23.sp, height: 1.15)),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title']!,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102C4C),
                      height: 1.35),
                ),
                SizedBox(height: 5.h),
                Text(
                  s['desc']!,
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF637A92),
                      height: 1.48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUY NOW
  // ============================================================
  Widget _buildBuyNowCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFDCECF3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0B102C4C), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FA),
              borderRadius: BorderRadius.circular(13.r),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.open_in_new_rounded,
                color: const Color(0xFF008FA5), size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.buy_now_ucf,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102C4C),
                      height: 1.25),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!.buy_now_subtitle,
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF637A92),
                      height: 1.35),
                  softWrap: true,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isBuyNowLoading ? null : _onBuyNowPressed,
            child: Container(
              constraints: BoxConstraints(minHeight: 43.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8FB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFC9EDF1)),
              ),
              alignment: Alignment.center,
              child: _isBuyNowLoading
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: const Color(0xFF00869C)),
                    )
                  : Text(
                      AppLocalizations.of(context)!.buy_now_ucf,
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00869C),
                          height: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BID DOCK
  // ============================================================
  Widget _buildBidDock() {
    final isLive = _auctionStatus == "live";

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(9.w, 9.h, 9.w, 9.h),
        decoration: const BoxDecoration(
          color: Color(0xEDFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFDCEAF5))),
          boxShadow: [
            BoxShadow(
                color: Color(0x1715365A),
                blurRadius: 35,
                offset: Offset(0, -12)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxOffset = (constraints.maxWidth - _thumbSize - 10)
                      .clamp(0.0, double.infinity);

                  return GestureDetector(
                    onHorizontalDragStart: isLive
                        ? (d) {
                            setState(() {
                              _thumbStartX = d.localPosition.dx;
                              _isDragging = true;
                            });
                          }
                        : null,
                    onHorizontalDragUpdate: isLive
                        ? (d) {
                            if (!_isDragging) return;
                            final dx = d.localPosition.dx - _thumbStartX;
                            setState(
                                () => _slideOffset = dx.clamp(0.0, maxOffset));
                          }
                        : null,
                    onHorizontalDragEnd: isLive
                        ? (_) {
                            if (!_isDragging) return;
                            _isDragging = false;
                            final should = _slideOffset > maxOffset * 0.75;
                            setState(
                                () => _slideOffset = should ? maxOffset : 0);
                            Future.delayed(
                                Duration(milliseconds: should ? 200 : 300), () {
                              if (mounted) setState(() => _slideOffset = 0);
                            });
                            if (should) _placeBidNow();
                          }
                        : null,
                    child: Opacity(
                      opacity: isLive ? 1.0 : 0.5,
                      child: Container(
                        height: 56.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0BBDBD), Color(0xFF1870D5)],
                          ),
                          borderRadius: BorderRadius.circular(17.r),
                          border: Border.all(color: const Color(0xFF65E6E1)),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: _slideOffset + _thumbSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.27),
                                  borderRadius: BorderRadius.circular(17.r),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 5.w + _thumbSize + 6.w,
                              right: 8.w,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  !isLive
                                      ? (_auctionStatus == "upcoming"
                                          ? AppLocalizations.of(context)!
                                              .starts_soon_ucf
                                          : AppLocalizations.of(context)!
                                              .ended_ucf)
                                      : 'Slide to bid · − ${_pointPerBid.toInt()} pts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 5.w + _slideOffset,
                              top: 5.h,
                              child: Container(
                                width: 43.w,
                                height: 43.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13.r),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x4D123A57),
                                        blurRadius: 14,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                                child: _isProcessing
                                    ? Padding(
                                        padding: EdgeInsets.all(12.w),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: MyTheme.accent_color,
                                        ),
                                      )
                                    : Icon(Icons.arrow_forward_rounded,
                                        size: 23.sp,
                                        color: const Color(0xFF1870D5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: isLive ? _showBidInputDialog : null,
              child: Opacity(
                opacity: isLive ? 1.0 : 0.5,
                child: Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xEDFFFFFF),
                    borderRadius: BorderRadius.circular(17.r),
                    border: Border.all(color: const Color(0x80FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('▦',
                          style: TextStyle(
                              fontSize: 17.sp,
                              color: const Color(0xFF1163A8))),
                      SizedBox(width: 5.w),
                      Text(
                        !isLive
                            ? (_auctionStatus == "upcoming"
                                ? AppLocalizations.of(context)!.starts_soon_ucf
                                : AppLocalizations.of(context)!.ended_ucf)
                            : AppLocalizations.of(context)!.manual_bid_ucf,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1163A8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION MODAL
  // ============================================================
  void _showInformationModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
        child: Container(
          constraints: BoxConstraints(maxHeight: _screenWidth * 1.5),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Auction information',
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 22.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Auction details, product description, and direct purchase.',
                style:
                    TextStyle(fontSize: 13.sp, color: const Color(0xFF637A92)),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _infoTile(
                                  'Starting bid', _formatPrice(_startingBid))),
                          SizedBox(width: 8.w),
                          Expanded(child: _infoTile('Bidders', '$_totalBids')),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                              child: _infoTile(
                                  'Highest bidder', _highestBidder)),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: _infoTile(
                                  'Next bid', _formatPrice(_minNextBidNow))),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FC),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product description',
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 8.h),
                            Html(
                              data: _product?.description ?? '',
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(13.sp),
                                ),
                              },
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Materials, dimensions, condition, and exact package contents must be confirmed by the seller.',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF637A92)),
                            ),
                          ],
                        ),
                      ),
                      if (_buyNow == 1 && _auctionStatus != "ended") ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(15.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border:
                                Border.all(color: const Color(0xFFDCECF3)),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x0B102C4C),
                                  blurRadius: 16,
                                  offset: Offset(0, 5)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42.w,
                                height: 42.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8FA),
                                  borderRadius: BorderRadius.circular(13.r),
                                ),
                                child: Icon(Icons.open_in_new_rounded,
                                    color: const Color(0xFF008FA5),
                                    size: 22.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .buy_now_ucf,
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF102C4C)),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .buy_now_subtitle,
                                      style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF637A92)),
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: _isBuyNowLoading
                                    ? null
                                    : _onBuyNowPressed,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F8FB),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                        color: const Color(0xFFC9EDF1)),
                                  ),
                                  child: _isBuyNowLoading
                                      ? SizedBox(
                                          width: 14.w,
                                          height: 14.w,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: MyTheme.accent_color))
                                      : Text(
                                          AppLocalizations.of(context)!
                                              .buy_now_ucf,
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  const Color(0xFF00869C)),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 12.h),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE4EDF6))),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4FB),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizations.of(context)!.close_ucf,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF102C4C)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 9.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF637A92)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF102C4C)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BID INPUT DIALOG
  // ============================================================
  void _showBidInputDialog() {
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.auction_not_active);
      return;
    }
    _bidController.text = _minNextBidNow.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.your_bid_ucf,
                      style: TextStyle(
                          fontSize: 22.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 22.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '${AppLocalizations.of(context)!.enter_amount_higher_ucf} ${_formatPrice(_currentHighestBid)}.',
                style:
                    TextStyle(fontSize: 14.sp, color: const Color(0xFF637A92)),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _bidController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style:
                    TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: const Color(0xFFEDF4FB),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.r)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.close_ucf,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF102C4C)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _submitCustomBid();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.r)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              AppLocalizations.of(context)!.confirm_bid_ucf,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO
  // ============================================================
  void _openVideoModal() {
    final url = _product?.videoLink ?? '';
    if (url.isEmpty) {
      ToastComponent.showInfo(
          AppLocalizations.of(context)!.no_video_available_ucf);
      return;
    }
    final videoId = _videoIdFromUrl(url);
    if (videoId.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.product_video_ucf),
          content: Text(url),
          actions: [
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: Text(AppLocalizations.of(context)!.open_in_browser_ucf),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.close_ucf)),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(20.w),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                YoutubePlayer(controller: controller),
                Positioned(
                  top: 4.w,
                  right: 4.w,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      controller.close();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BID HISTORY
  // ============================================================
  void _openBidHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          constraints: BoxConstraints(maxHeight: _screenWidth * 1.4),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.bid_history_ucf,
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 22.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '$_totalBids ${_totalBids == 1 ? AppLocalizations.of(context)!.bid_singular_ucf : AppLocalizations.of(context)!.bids_plural_ucf} · ${AppLocalizations.of(context)!.newest_first_ucf}',
                style:
                    TextStyle(fontSize: 12.sp, color: const Color(0xFF637A92)),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: _bidHistory.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.no_bids_yet_ucf,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF637A92)),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _bidHistory.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: const Color(0xFFE6EFF6), height: 1),
                        itemBuilder: (_, i) {
                          final b = _bidHistory[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: Row(
                              children: [
                                Text(
                                  '#${(_bidHistory.length - i).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF94A5B7)),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.userName ??
                                            AppLocalizations.of(context)!
                                                .user_ucf,
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        _formatDateTime(b.createdAt),
                                        style: TextStyle(
                                            fontSize: 11.sp,
                                            color: const Color(0xFF637A92)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(b.amount ?? 0),
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF007E94)),
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

  // ============================================================
  // WINNER
  // ============================================================
  void _showWinnerModalDialog() {
    if (_winnerData == null) return;

    if (is_logged_in.$ && _winnerData?.userId == _userInfo?.id) {
      _productRepository.sendWinnerNotification(
        _product?.id ?? 0,
        _winnerData?.userId ?? 0,
        _winnerData?.amount ?? 0,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
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
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              SizedBox(height: 12.h),
              CircleAvatar(
                radius: 50.w,
                backgroundImage: NetworkImage(_winnerData!.avatar ?? ''),
                child: _winnerData!.avatar == null
                    ? Icon(Icons.person, size: 40.sp)
                    : null,
              ),
              SizedBox(height: 10.h),
              Text(
                _winnerData!.userName ??
                    AppLocalizations.of(context)!.winner_ucf,
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              SizedBox(height: 6.h),
              Text(
                _formatPrice(_winnerData!.amount ?? 0),
                style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber),
              ),
              SizedBox(height: 12.h),
              Text(
                AppLocalizations.of(context)!.congratulations_to_winner,
                style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _winnerModalShown = true);
                  _pollData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r)),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  AppLocalizations.of(context)!.close_ucf,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: MyTheme.accent_color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHIMMER
  // ============================================================
  Widget _buildShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShimmerHelper().buildBasicShimmer(height: 600.h),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                ShimmerHelper()
                    .buildBasicShimmer(height: 30.h, width: double.infinity),
                SizedBox(height: 10.h),
                ShimmerHelper().buildBasicShimmer(height: 20.h, width: 150.w),
                SizedBox(height: 10.h),
                ShimmerHelper().buildBasicShimmer(height: 60.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}