import 'dart:async';
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
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/chat.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data_model/auction_models.dart';
import '../data_model/user_info_response.dart';

class _BidSystemNotification {
  _BidSystemNotification.bid({
    required this.id,
    required this.key,
    required this.bidderName,
    required this.amount,
  }) : message = null;

  _BidSystemNotification.message({
    required this.id,
    required this.key,
    required this.message,
  }) : bidderName = null,
       amount = null;

  final int id;
  final String key;
  final String? bidderName;
  final double? amount;
  final String? message;
  bool isLeaving = false;
}

class ProductDetails extends StatefulWidget {
  final String slug;
  ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
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
  bool _isBidSubmitting = false;
  bool _isPolling = false;
  bool _isBuyNowLoading = false;
  bool _isInWishlist = false;
  bool _showMoreMenu = false;
  bool _isSendingMessage = false;
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
  Duration _timeLeft = Duration.zero;
  Duration _timeUntilStart = Duration.zero;
  String _auctionStatus = "live"; // "live" | "upcoming" | "ended"
  int? _endingSeconds;
  DateTime? _auctionEndDateTime;
  DateTime? _auctionStartDateTime;

  // =========================
  // BID
  // =========================
  double _currentHighestBid = 0;
  double _minNextBidNow = 0;
  double _startingBid = 0;
  double? _pointPerBid;
  double? _pointPerBidCustom;
  int _totalBids = 0;
  String _highestBidder = '';
  double _rating = 0;
  int _reviewsCount = 0;
  bool? _myStatus;
  bool _userHasBid = false;
  double _lastNotifiedBid = 0;

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

  // Slide to bid
  double _slideOffset = 0;
  double _thumbStartX = 0;
  bool _isDragging = false;
  static const double _thumbSize = 49;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _commentPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  bool _bellSoundPlayed = false;

  // The Blade room keeps bid notices in the chat for 4.5 seconds, even when
  // polling redraws the comments. Keep them separately for the same behavior.
  final List<_BidSystemNotification> _systemNotifications = [];
  final Set<String> _displayedSystemNotificationKeys = {};
  final Map<int, Timer> _systemNotificationTimers = {};
  int _systemNotificationSequence = 0;
  static const Duration _systemNotificationVisibleTime = Duration(
    milliseconds: 4500,
  );
  static const Duration _systemNotificationFadeTime = Duration(
    milliseconds: 250,
  );

  // Repositories
  final ProductRepository _productRepository = ProductRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  // Responsive
  double _screenWidth = 0;

  @override
  void initState() {
    super.initState();

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
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _upcomingTimer?.cancel();
    _balanceRefreshTimer?.cancel();
    for (final timer in _systemNotificationTimers.values) {
      timer.cancel();
    }
    _systemNotificationTimers.clear();
    _commentController.dispose();
    _bidController.dispose();
    _reviewController.dispose();
    _commentsScrollController.dispose();
    _mainScrollController.dispose();
    _audioPlayer.dispose();
    _commentPlayer.dispose();
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

      if (n <= 0) return null;

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

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();

    final normalized = raw
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  // ============================================================
  // FETCHING
  // ============================================================

  Future<void> _fetchAllData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final productData = await _productRepository.getProductDetails(
        slug: widget.slug,
      );

      if (productData.detailedProducts == null ||
          productData.detailedProducts!.isEmpty) {
        throw StateError('Product details response was empty');
      }

      _product = productData.detailedProducts![0];
      _productImages = _product!.getAllImageUrls();
      if (_currentImageIndex >= _productImages.length) {
        _currentImageIndex = 0;
      }

      _startingBid = _parseAmount(_product!.startingBid);
      final productHighestBid = _parseAmount(_product!.highestBid);
      _currentHighestBid = max(_startingBid, productHighestBid);
      _totalBids = _product!.totalBids ?? 0;
      _highestBidder = _product!.lastBidderName ?? '';
      // Point costs are user-specific. As on the Blade page, polling is the
      // only authority; product details must never enable bidding with a
      // stale/default cost.
      _pointPerBid = null;
      _pointPerBidCustom = null;
      _reviewsCount = _product!.ratingCount ?? 0;
      _rating = (_product!.rating ?? 0).toDouble();
      final endingSeconds = _product!.swipeLeft;
      _endingSeconds = endingSeconds != null && endingSeconds > 0
          ? endingSeconds
          : null;
      _myStatus = _product!.myStatus;
      _userHasBid = _myStatus != null || (_product!.userHasBid ?? false);
      _buyNow = _product!.buyNow ?? 0;
      _buyNowLink = _product!.buyNowLink ?? '';
      _minNextBidNow = _currentHighestBid + 0.01;
      _lastNotifiedBid = _currentHighestBid;

      _determineAuctionStatus();

      // Render the core product immediately. Polling, comments, reviews,
      // history, wishlist and balance must never block the whole page.
      if (mounted) setState(() => _isLoading = false);

      unawaited(_pollData());
      unawaited(_fetchComments());
      unawaited(_fetchReviews());
      unawaited(_fetchBidHistory());
      unawaited(_fetchWishlistStatus());
      unawaited(_fetchPointBalance());
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _determineAuctionStatus() {
    if (_product == null) return;

    _auctionStartDateTime = _parseServerDate(_product!.auctionStartDate);
    _auctionEndDateTime =
        _parseServerDate(_product!.auctionEndDate) ??
        _product!.getAuctionEndDateTime();

    final now = DateTime.now();
    final isUpcoming =
        _auctionStartDateTime != null && _auctionStartDateTime!.isAfter(now);
    final isEnded =
        _product?.isAuctionEnded == true ||
        (_auctionEndDateTime != null && !_auctionEndDateTime!.isAfter(now));

    if (isUpcoming) {
      _auctionStatus = "upcoming";
      _startUpcomingTimer();
      return;
    }

    if (isEnded) {
      _auctionStatus = "ended";
      _timeLeft = Duration.zero;
      return;
    }

    _auctionStatus = "live";

    // Prefer our own parser on the raw end date, because the server
    // sends epoch seconds (e.g. 1790488740) and the data-model parser
    // may not handle that format.
    final endTime = _auctionEndDateTime;

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
      final response = await _productRepository.getProductComments(
        _product?.id ?? 0,
      );
      if (mounted && response.success == true && response.comments != null) {
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
      final response = await _productRepository.getProductReviews(
        _product?.id ?? 0,
      );
      if (mounted && response.success == true && response.reviews != null) {
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
      final response = await _productRepository.getProductBidHistory(
        _product?.id ?? 0,
      );
      if (mounted && response.success == true && response.bids != null) {
        setState(() => _bidHistory = response.bids!);
      }
    } catch (e) {
      print('Error fetching bid history: $e');
    }
  }

  Future<void> _fetchWishlistStatus() async {
    if (!is_logged_in.$ || _product == null) return;
    try {
      final result = await _productRepository.getWishlistStatus(
        _product!.id ?? 0,
      );
      if (mounted && result['success'] == true) {
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
      if (mounted &&
          response.success == true &&
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
          newBalance = bal.toInt();
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
        final fromServer =
            response.success == true &&
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

  // ============================================================
  // POLLING
  // ============================================================

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollData(),
    );
  }

  Future<void> _pollData() async {
    if (_product == null || _isPolling) return;

    _isPolling = true;

    try {
      final response = await _productRepository.pollProductData(
        _product!.id ?? 0,
      );
      if (response.success != true || !mounted) return;

      String? notificationName;
      double? notificationAmount;
      String? notificationKey;
      DateTime? countdownEnd;
      bool startUpcomingCountdown = false;
      bool stopAllCountdowns = false;
      int? balanceToPersist;

      final polledHighestBid = response.highestBid;
      if (polledHighestBid != null && polledHighestBid > _lastNotifiedBid) {
        notificationName = response.lastBidderName?.trim().isNotEmpty == true
            ? response.lastBidderName!.trim()
            : AppLocalizations.of(context)!.someone_ucf;
        notificationAmount = response.lastBidAmount ?? polledHighestBid;
        notificationKey = 'remote-bid-$polledHighestBid-$notificationName';
      }

      setState(() {
        if (response.balance != null && is_logged_in.$) {
          _pointBalance = max(0, response.balance!);
          _isPointBalanceLoading = false;
          balanceToPersist = _pointBalance;
        }

        if (response.myStatus != null) {
          _myStatus = response.myStatus;
          _userHasBid = true;
        } else {
          _myStatus = null;
          _userHasBid = response.userHasBid ?? false;
        }

        if (response.startingBid != null) {
          _startingBid = response.startingBid!;
        }
        if (polledHighestBid != null) {
          _currentHighestBid = polledHighestBid;
          _lastNotifiedBid = max(_lastNotifiedBid, polledHighestBid);
        }
        if (response.totalBids != null) _totalBids = response.totalBids!;
        if (response.lastBidderName?.trim().isNotEmpty == true) {
          _highestBidder = response.lastBidderName!.trim();
        }

        // These are the only assignments to point costs in this screen.
        if (response.pointPerBid != null && response.pointPerBid! >= 0) {
          _pointPerBid = response.pointPerBid;
        }
        if (response.pointPerBidCustom != null &&
            response.pointPerBidCustom! >= 0) {
          _pointPerBidCustom = response.pointPerBidCustom;
        }

        if (response.buyNow != null) _buyNow = response.buyNow!;
        if (response.isInWishlist != null) {
          _isInWishlist = response.isInWishlist!;
        }
        if (_buyNowLink.isEmpty && response.buyNowLink?.isNotEmpty == true) {
          _buyNowLink = response.buyNowLink!;
        } else if (_buyNowLink.isEmpty &&
            response.payLink?.isNotEmpty == true) {
          _buyNowLink = response.payLink!;
        }

        _minNextBidNow = _currentHighestBid + 0.01;

        final polledStatus = response.upcomingStatus?.trim().toLowerCase();
        if (polledStatus == 'upcoming') {
          _auctionStatus = 'upcoming';
          final newStart = _parseServerDate(response.auctionStartDate);
          if (newStart != null) _auctionStartDateTime = newStart;
          startUpcomingCountdown = true;
        } else if (polledStatus == 'live' && _auctionStatus != 'ended') {
          _auctionStatus = 'live';
          _upcomingTimer?.cancel();
        }

        if (response.auctionEnded == true || polledStatus == 'ended') {
          _auctionStatus = 'ended';
          _timeLeft = Duration.zero;
          _isEndingSoon = false;
          _bellSoundPlayed = false;
          stopAllCountdowns = true;
        } else if (_auctionStatus == 'live') {
          DateTime? synchronizedEnd;
          final remaining = response.remainingSeconds;
          if (remaining != null && remaining >= 0) {
            synchronizedEnd = DateTime.now().add(Duration(seconds: remaining));
          } else {
            synchronizedEnd = _parseServerDate(response.auctionEndDate);
          }

          if (synchronizedEnd != null) {
            final changed =
                _auctionEndDateTime == null ||
                synchronizedEnd
                        .difference(_auctionEndDateTime!)
                        .inMilliseconds
                        .abs() >
                    1500;
            _auctionEndDateTime = synchronizedEnd;
            _timeLeft = synchronizedEnd.difference(DateTime.now());
            if (changed || _countdownTimer == null) {
              countdownEnd = synchronizedEnd;
            }
          }
        }

        if (response.rating != null) _rating = response.rating!;
        if (response.reviewsCount != null) {
          _reviewsCount = response.reviewsCount!;
        }

        if (response.comments != null) {
          _comments = response.comments!.reversed.toList();
        }
        if (response.reviews != null) {
          _reviews = response.reviews!;
          _reviewsCount = _reviews.length;
        }
        if (response.bidHistory != null) {
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

      if (balanceToPersist != null) {
        points_balance.$ = balanceToPersist.toString();
        points_balance.save();
      } else if (response.balance == null) {
        await _fetchPointBalance(silent: true);
      }

      final synchronizedCountdownEnd = countdownEnd;
      if (stopAllCountdowns) {
        _countdownTimer?.cancel();
        _upcomingTimer?.cancel();
        _bellPlayer.stop();
        ToastComponent.tickSoundPlaying = false;
      } else if (startUpcomingCountdown) {
        _countdownTimer?.cancel();
        _startUpcomingTimer();
      } else if (synchronizedCountdownEnd != null) {
        _startCountdown(synchronizedCountdownEnd);
      }

      if (notificationName != null &&
          notificationAmount != null &&
          notificationKey != null) {
        _playBidSound();
        _addBidSystemNotification(
          bidderName: notificationName,
          amount: notificationAmount,
          key: notificationKey,
        );
      } else if (_isAtBottom && !_userInteractedWithComments) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }

      if (response.auctionEnded == true &&
          response.winner != null &&
          !_winnerModalShown) {
        _winnerData = response.winner;
        _winnerModalShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showWinnerModalDialog();
        });
      }
    } catch (e) {
      print('Polling error: $e');
    } finally {
      _isPolling = false;
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
        _bellPlayer.stop();
        ToastComponent.tickSoundPlaying = false;
        _pollData();
        return;
      }

      final seconds = remaining.inSeconds;
      final shouldEnd =
          _endingSeconds != null && seconds > 0 && seconds <= _endingSeconds!;

      if (shouldEnd != _isEndingSoon) {
        setState(() => _isEndingSoon = shouldEnd);
        if (shouldEnd && !_bellSoundPlayed) {
          _bellSoundPlayed = true;
          _playBell();
        } else if (!shouldEnd) {
          _bellSoundPlayed = false;
          ToastComponent.tickSoundPlaying = false;
        }
      }

      if (mounted) {
        setState(() => _timeLeft = remaining);
      }
    });
  }

  void _startUpcomingTimer() {
    _upcomingTimer?.cancel();
    final start =
        _auctionStartDateTime ??
        _parseServerDate(_product?.auctionStartDate) ??
        _product?.getAuctionStartDateTime();
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
      final endTime =
          _auctionEndDateTime ??
          _parseServerDate(_product?.auctionEndDate) ??
          _product!.getAuctionEndDateTime();
      if (endTime != null) {
        _auctionEndDateTime = endTime;
        _startCountdown(endTime);
      }
      _pollData();
      return;
    }
    if (mounted) setState(() => _timeUntilStart = remaining);
  }

  Future<void> _playBell() async {
    try {
      await _bellPlayer.stop();
      await _bellPlayer.setReleaseMode(ReleaseMode.release);
      await _bellPlayer.play(
        AssetSource('sounds/bell.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 0.85,
      );
      ToastComponent.tickSoundPlaying = true;
    } catch (_) {}
  }

  Future<void> _playBidSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/bid_notification.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  Future<void> _playCommentSound() async {
    try {
      await _commentPlayer.stop();
      await _commentPlayer.play(
        AssetSource('sounds/comment_sound.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  void _addBidSystemNotification({
    required String bidderName,
    required double amount,
    required String key,
  }) {
    if (_displayedSystemNotificationKeys.contains(key)) return;

    _displayedSystemNotificationKeys.add(key);
    final notification = _BidSystemNotification.bid(
      id: ++_systemNotificationSequence,
      key: key,
      bidderName: bidderName,
      amount: amount,
    );

    if (!mounted) return;
    setState(() {
      _systemNotifications.add(notification);
      _isAtBottom = true;
      _userInteractedWithComments = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    _systemNotificationTimers[notification.id] = Timer(
      _systemNotificationVisibleTime,
      () {
        if (!mounted) return;
        setState(() => notification.isLeaving = true);

        _systemNotificationTimers[notification.id] = Timer(
          _systemNotificationFadeTime,
          () {
            _systemNotificationTimers.remove(notification.id);
            if (!mounted) return;
            setState(() => _systemNotifications.remove(notification));
          },
        );
      },
    );
  }

  void _addSystemNotificationMessage({
    required String message,
    required String key,
  }) {
    if (_displayedSystemNotificationKeys.contains(key)) return;

    _displayedSystemNotificationKeys.add(key);
    final notification = _BidSystemNotification.message(
      id: ++_systemNotificationSequence,
      key: key,
      message: message,
    );

    if (!mounted) return;
    setState(() {
      _systemNotifications.add(notification);
      _isAtBottom = true;
      _userInteractedWithComments = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    _systemNotificationTimers[notification.id] = Timer(
      _systemNotificationVisibleTime,
      () {
        if (!mounted) return;
        setState(() => notification.isLeaving = true);
        _systemNotificationTimers[notification.id] = Timer(
          _systemNotificationFadeTime,
          () {
            _systemNotificationTimers.remove(notification.id);
            if (!mounted) return;
            setState(() => _systemNotifications.remove(notification));
          },
        );
      },
    );
  }

  // ============================================================
  // COMMENTS SCROLL
  // ============================================================
  void _onCommentsScroll() {
    if (!_commentsScrollController.hasClients) return;
    final cur = _commentsScrollController.position.pixels;
    final atBottom = cur <= 30;
    if (atBottom != _isAtBottom) setState(() => _isAtBottom = atBottom);
    if (!atBottom && cur > 80) {
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
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================
  Future<void> _placeBidNow() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_isBidSubmitting) return;
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.auction_not_active,
      );
      return;
    }
    if (_pointPerBid == null) {
      ToastComponent.showInfo(AppLocalizations.of(context)!.loading_bid_cost);
      _pollData();
      return;
    }

    await _submitBid(
      amount: _minNextBidNow,
      type: 'quick',
      pointCost: _pointPerBid!,
    );
  }

  Future<void> _submitCustomBid() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_isBidSubmitting) return;
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.auction_not_active,
      );
      return;
    }
    if (_pointPerBidCustom == null) {
      ToastComponent.showInfo(
        AppLocalizations.of(context)!.loading_manual_bid_cost,
      );
      _pollData();
      return;
    }

    final amount = double.tryParse(_bidController.text);
    if (amount == null || amount <= _currentHighestBid) {
      ToastComponent.showWarning(
        '${AppLocalizations.of(context)!.bid_must_be_at_least} ${_formatPrice(_minNextBidNow)}',
      );
      return;
    }

    await _submitBid(
      amount: amount,
      type: 'custom',
      pointCost: _pointPerBidCustom!,
    );
  }

  Future<void> _submitBid({
    required double amount,
    required String type,
    required double pointCost,
  }) async {
    if (_isBidSubmitting || _product == null) return;
    setState(() => _isBidSubmitting = true);

    try {
      final response = await _productRepository.placeBid(
        (_product!.id ?? 0).toString(),
        amount.toString(),
        type: type,
      );

      if (!mounted) return;

      if (response.success == true) {
        final loc = AppLocalizations.of(context)!;
        final acceptedAmount = response.currentHighest ?? amount;
        final pointsUsed =
            response.pointsUsed ??
            response.pointsDeducted?.toDouble() ??
            pointCost;

        setState(() {
          _currentHighestBid = acceptedAmount;
          _minNextBidNow = response.nextMinBid ?? acceptedAmount + 0.01;
          _lastNotifiedBid = max(_lastNotifiedBid, acceptedAmount);
          _highestBidder = loc.you_ucf;
          _userHasBid = true;
          _myStatus = true;
          _totalBids += 1;

          final responseBalance = response.balance ?? response.remainingBalance;
          if (responseBalance != null) {
            _pointBalance = max(0, responseBalance.round());
          } else {
            _pointBalance = max(0, (_pointBalance - pointsUsed).round());
          }
          _isPointBalanceLoading = false;

          _bidHistory.insert(
            0,
            BidHistory(
              userName: loc.you_ucf,
              amount: acceptedAmount,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        });

        points_balance.$ = _pointBalance.toString();
        points_balance.save();
        _playBidSound();
        _addBidSystemNotification(
          bidderName: loc.you_ucf,
          amount: acceptedAmount,
          key: 'own-bid-$acceptedAmount',
        );

        if (response.timeExtended == true && response.newEndDate != null) {
          final newEnd = _parseServerDate(response.newEndDate);
          if (newEnd != null) {
            _auctionEndDateTime = newEnd;
            _startCountdown(newEnd);
          }
          _addSystemNotificationMessage(
            message:
                '⏰ ${response.message ?? AppLocalizations.of(context)!.auction_time_extended}',
            key:
                'time-extension-${newEnd?.millisecondsSinceEpoch ?? response.newEndDate}',
          );
        }

        _bidController.clear();
        await _pollData();
      } else {
        ToastComponent.showError(
          response.message ??
              AppLocalizations.of(context)!.something_went_wrong,
        );
      }
    } catch (_) {
      ToastComponent.showError(AppLocalizations.of(context)!.error_placing_bid);
    } finally {
      if (mounted) setState(() => _isBidSubmitting = false);
    }
  }

  Future<void> _sendComment() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_isSendingMessage) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.please_enter_comment,
      );
      return;
    }

    setState(() => _isSendingMessage = true);
    try {
      final response = await _productRepository.addProductComment(
        _product!.id ?? 0,
        text,
      );
      if (!mounted) return;
      if (response.success == true) {
        _playCommentSound();
        _commentController.clear();
        await _fetchComments();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        ToastComponent.showError(
          response.message ??
              AppLocalizations.of(context)!.error_adding_comment,
        );
      }
    } catch (_) {
      ToastComponent.showError(
        AppLocalizations.of(context)!.error_adding_comment,
      );
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _submitReview() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_isProcessing) return;
    if (_selectedRating == 0) {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.please_select_rating,
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.please_write_review,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await _productRepository.addProductReview(
        _product!.id ?? 0,
        _selectedRating.toInt(),
        _reviewController.text,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response.success == true) {
        ToastComponent.showSuccess(
          AppLocalizations.of(context)!.review_submitted,
        );
        _selectedRating = 0;
        _reviewController.clear();
        Navigator.pop(context);
        await _fetchReviews();
        await _pollData();
      } else {
        ToastComponent.showError(
          response.message ??
              AppLocalizations.of(context)!.error_submitting_review,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(
        AppLocalizations.of(context)!.error_submitting_review,
      );
    }
  }

  Future<void> _toggleWishlist() async {
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_isProcessing) return;

    final wasIn = _isInWishlist;
    setState(() {
      _isProcessing = true;
      _isInWishlist = !wasIn;
    });

    try {
      WishlistResponse response;
      if (wasIn) {
        response = await _productRepository.removeFromWishlist(
          _product!.id ?? 0,
        );
      } else {
        response = await _productRepository.addToWishlist(_product!.id ?? 0);
      }

      if (response.success == true) {
        _playCommentSound();
        ToastComponent.showSuccess(
          wasIn
              ? AppLocalizations.of(context)!.removed_from_wishlist
              : AppLocalizations.of(context)!.added_to_wishlist,
        );
        await _fetchWishlistStatus();
      } else {
        setState(() => _isInWishlist = wasIn);
        ToastComponent.showError(
          AppLocalizations.of(context)!.wishlist_update_failed,
        );
      }
    } catch (_) {
      setState(() => _isInWishlist = wasIn);
      ToastComponent.showError(
        AppLocalizations.of(context)!.wishlist_update_failed,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

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
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response['success'] == true) {
        ToastComponent.showSuccess(
          response['message'] ??
              AppLocalizations.of(context)!.message_sent_to_seller,
        );
        final data = response['data'] ?? {};
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chat(
                  conversation_id: response['conversation_id'],
                  messenger_name:
                      data['seller_name'] ??
                      AppLocalizations.of(context)!.seller,
                  messenger_title: data['product_name'] ?? _product?.name ?? '',
                  messenger_image: data['seller_avatar'] ?? '',
                ),
              ),
            );
          }
        });
      } else {
        ToastComponent.showError(
          response['message'] ??
              AppLocalizations.of(context)!.failed_to_contact_seller,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
      ToastComponent.showError(
        AppLocalizations.of(context)!.error_contacting_seller,
      );
    }
  }

  void _onBuyNowPressed() async {
    if (_isBuyNowLoading) return;
    if (_auctionStatus == 'ended') {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.auction_has_ended,
      );
      return;
    }
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    if (_buyNow != 1) {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.buy_now_not_available,
      );
      return;
    }
    if (_buyNowLink.isEmpty) {
      ToastComponent.showWarning(
        AppLocalizations.of(context)!.payment_link_unavailable,
      );
      return;
    }

    setState(() => _isBuyNowLoading = true);
    try {
      await _productRepository.trackBuyNowClick(_product?.id ?? 0);
      if (!mounted) return;
      _playCommentSound();
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
        AppLocalizations.of(context)!.failed_to_open_payment,
      );
    } finally {
      if (mounted) setState(() => _isBuyNowLoading = false);
    }
  }

  void _showLoginRequired() {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Expanded(child: Text(loc.login_required_ucf)),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text(loc.login_required_message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Login()),
                );
              },
              child: Text(loc.login_ucf),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================
  String _formatPrice(double amount) => FormatHelper.formatPrice(amount);

  String _formatNotificationPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: r'$ ',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  String _formatTimeLeft(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final loc = AppLocalizations.of(context)!;

    final days = d.inDays;
    final h = d.inHours.remainder(24);
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    if (days > 0) {
      return '$days${loc.duration_days_compact} '
          '$hh${loc.duration_hours_compact}';
    }
    if (d.inHours > 0) {
      return '$hh${loc.duration_hours_compact} '
          '$mm${loc.duration_minutes_compact}';
    }
    return '$mm${loc.duration_minutes_compact} '
        '$ss${loc.duration_seconds_compact}';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.trim().isEmpty) return '';
    try {
      DateTime? d = DateTime.tryParse(dateTime);
      if (d == null) {
        try {
          d = DateFormat(
            'dd MMM yyyy, hh:mm a',
            'en_US',
          ).parseLoose(dateTime.trim());
        } catch (_) {}
      }
      if (d == null) return dateTime;
      return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year} · '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime;
    }
  }

  String _formatPointCost(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _productVideoUrl() {
    final links = _product?.getVideoLinks() ?? const <String>[];
    return links.isEmpty ? '' : links.first.trim();
  }

  String _videoIdFromUrl(String rawUrl) {
    final value = rawUrl
        .trim()
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&quot;', '"');
    if (value.isEmpty) return '';

    if (RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(value)) {
      return value;
    }

    try {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        final host = uri.host.toLowerCase().replaceFirst('www.', '');
        if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
        if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
          final queryId = uri.queryParameters['v'];
          if (queryId?.isNotEmpty == true) return queryId!;

          final segments = uri.pathSegments;
          if (segments.length >= 2 &&
              const {'embed', 'shorts', 'live'}.contains(segments.first)) {
            return segments[1];
          }
        }
      }

      final fallback = RegExp(
        r'(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:embed|shorts|live)/|[?&]v=)([A-Za-z0-9_-]{6,20})',
        caseSensitive: false,
      ).firstMatch(value);
      return fallback?.group(1) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  Widget _constrainRoomContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf5f9fd),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildShimmer()),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      final loc = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9FD),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48.sp,
                          color: const Color(0xFF637A92),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          loc.failed_to_load_product_details,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF102C4C),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        ElevatedButton.icon(
                          onPressed: _fetchAllData,
                          icon: const Icon(Icons.refresh),
                          label: Text(loc.retry_ucf),
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: false,
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
              SliverToBoxAdapter(child: _constrainRoomContent(_buildStage())),
              SliverToBoxAdapter(
                child: _constrainRoomContent(_buildPhotoRail()),
              ),
              SliverToBoxAdapter(child: _constrainRoomContent(_buildSummary())),
              SliverToBoxAdapter(
                child: _constrainRoomContent(_buildHowItWorks()),
              ),
              if (_buyNow == 1 && _auctionStatus != "ended")
                SliverToBoxAdapter(
                  child: _constrainRoomContent(_buildBuyNowCard()),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
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
    final loc = AppLocalizations.of(context)!;
    return Container(
      height: 60.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE4EDF6))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 836),
          child: Row(
            children: [
              Image.asset(
                'assets/app_logo.png',
                height: 36.h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  AppConfig.app_name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const Spacer(),
              if (is_logged_in.$)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFCFA),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: const Color(0xFFB8ECEA)),
                  ),
                  child: _isPointBalanceLoading
                      ? SizedBox(
                          width: 12.w,
                          height: 12.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF007D7F),
                          ),
                        )
                      : Text(
                          '✦ $_pointBalance ${loc.points_plural_ucf}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF007D7F),
                          ),
                        ),
                ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  if (is_logged_in.$) {
                    Navigator.pop(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Login()),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 11.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6FF),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        is_logged_in.$ ? Icons.arrow_back : Icons.login,
                        size: 14.sp,
                        color: const Color(0xFF1870D5),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        is_logged_in.$ ? loc.exit_ucf : loc.login_ucf,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1870D5),
                        ),
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

  // ============================================================
  // STAGE
  // ============================================================
  Widget _buildStage() {
    final isMobile = _screenWidth < 800;
    final screenHeight = MediaQuery.of(context).size.height;
    final mobileMinimum = screenHeight <= 690 ? 380.0 : 400.0;
    final double stageHeight = isMobile
        ? (screenHeight - 260).clamp(mobileMinimum, 640.0).toDouble()
        : (screenHeight * .60).clamp(420.0, 560.0).toDouble();
    final chatHeight = screenHeight <= 690
        ? 100.0
        : (screenHeight * .32).clamp(170.0, 340.0).toDouble();

    return Container(
      margin: isMobile
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 0),
      height: stageHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FD),
        borderRadius: BorderRadius.circular(isMobile ? 0 : 28.r),
        boxShadow: isMobile
            ? null
            : const [
                BoxShadow(
                  color: Color(0x2215365A),
                  blurRadius: 48,
                  offset: Offset(0, 18),
                ),
              ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image-background.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: .72,
                  colors: [
                    Color(0x38FFFFFF),
                    Color(0x180ABFC4),
                    Color(0x00071C35),
                  ],
                  stops: [0, .48, 1],
                ),
              ),
            ),
          ),
          if (_productImages.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Opacity(
                    opacity: .22,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF79E7FF),
                        BlendMode.srcATop,
                      ),
                      child: Image.network(
                        _productImages[_currentImageIndex],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: _productImages.isEmpty
                ? const Icon(
                    Icons.image_outlined,
                    color: Color(0xBFFFFFFF),
                    size: 60,
                  )
                : Image.network(
                    _productImages[_currentImageIndex],
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: Color(0xBFFFFFFF),
                      size: 60,
                    ),
                  ),
          ),

          // ── Chat overlay
          Positioned(
            left: 13.w,
            right: 13.w,
            bottom: max(17.h, MediaQuery.of(context).padding.bottom),
            height: min(stageHeight - 90, chatHeight + 64.h),
            child: _buildChatOverlay(),
          ),

          // ── Floating icons (top-right)
          Positioned(top: 13.h, right: 13.w, child: _buildActionCircles()),

          // ── Status badge (top-left)
          Positioned(
            top: 13.h,
            left: 13.w,
            right: 76.w,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(),
            ),
          ),

          if (_isEndingSoon && _auctionStatus == 'live')
            Positioned.fill(
              child: IgnorePointer(child: _buildCircularCountdown()),
            ),

          // ── More menu (highest z)
          if (_showMoreMenu)
            Positioned(
              top: 72.h,
              right: 8.w,
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
    final loc = AppLocalizations.of(context)!;
    String label;
    Color bg;
    Color border;
    Color foreground;
    Color dotColor;

    if (_auctionStatus == "ended") {
      label = loc.status_ended_ucf;
      bg = const Color(0xFF2B3D52);
      border = const Color(0xFFC2D2E2);
      foreground = const Color(0xFFDBE7F3);
      dotColor = const Color(0xFFC2D2E2);
    } else if (_userHasBid && _myStatus != null) {
      final winning = _myStatus == true;
      label = winning ? loc.status_winning_ucf : loc.status_outbid_ucf;
      bg = winning ? const Color(0xFF047E60) : const Color(0xFFAC2848);
      border = winning ? const Color(0xFF62F3C8) : const Color(0xFFFFB3C2);
      foreground = Colors.white;
      dotColor = winning ? const Color(0xFF9EFFD6) : const Color(0xFFFFD5DE);
    } else {
      label = loc.status_live_ucf;
      bg = const Color(0xFF0B2038);
      border = const Color(0x3BFFFFFF);
      foreground = Colors.white;
      dotColor = const Color(0xFF9EFFD6);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dotColor.withOpacity(.25), spreadRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13.sp,
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
            _playCommentSound();
            Share.share(_product?.link ?? AppConfig.RAW_BASE_URL);
          },
        ),
        SizedBox(height: 9.h),
        _actionCircle(icon: Icons.play_arrow_rounded, onTap: _openVideoModal),
        SizedBox(height: 9.h),
        _actionCircle(icon: Icons.history, onTap: _openBidHistoryModal),
      ],
    );
  }

  Widget _actionCircle({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xB5071D35),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x75FFFFFF)),
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularCountdown() {
    final endingSeconds = _endingSeconds;
    if (endingSeconds == null || endingSeconds <= 0) {
      return const SizedBox.shrink();
    }

    final remaining = max(0, _timeLeft.inSeconds);
    final progress = (remaining / endingSeconds).clamp(0.0, 1.0).toDouble();
    final size = min(200.0, _screenWidth * .5);

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: const Color(0x2E102C4C),
                color: remaining <= 5
                    ? const Color(0xFFFF4444)
                    : const Color(0xFFFF9800),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$remaining',
                  style: TextStyle(
                    color: const Color(0xFF102C4C),
                    fontSize: min(40.sp, _screenWidth * .08),
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.seconds_left_short,
                  style: TextStyle(
                    color: const Color(0xCC102C4C),
                    fontSize: min(12.sp, _screenWidth * .02),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: 236.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: const Color(0xFFE0EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 44,
            offset: Offset(0, 16),
          ),
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
                    loc.options_ucf,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102C4C),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: const Color(0xFF102C4C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _moreMenuItem(
            icon: Icons.info_outline,
            label: loc.information_ucf,
            onTap: () {
              setState(() => _showMoreMenu = false);
              _showInformationModal();
            },
          ),
          _moreMenuItem(
            icon: _isInWishlist ? Icons.favorite : Icons.favorite_border,
            label: _isInWishlist
                ? loc.remove_from_favorites
                : loc.add_to_favorites,
            onTap: () {
              setState(() => _showMoreMenu = false);
              _toggleWishlist();
            },
          ),
          _moreMenuItem(
            icon: Icons.mail_outline,
            label: loc.contact_seller,
            onTap: () {
              setState(() => _showMoreMenu = false);
              _contactSeller();
            },
          ),
        ],
      ),
    );
  }

  Widget _moreMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
                color: const Color(0xFF102C4C),
              ),
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
    final itemCount = _comments.length + _systemNotifications.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: max(0.0, constraints.maxWidth - 55.w),
                child: itemCount == 0
                    ? const SizedBox.shrink()
                    : ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                          stops: [0, 0.18],
                        ).createShader(bounds),
                        child: ListView.builder(
                          reverse: true,
                          controller: _commentsScrollController,
                          padding: EdgeInsets.only(top: 28.h),
                          itemCount: itemCount,
                          itemBuilder: (context, int reverseIndex) {
                            final index = itemCount - reverseIndex - 1;
                            if (index < _comments.length) {
                              return _buildCommentMessage(_comments[index]);
                            }
                            return _buildSystemNotification(
                              _systemNotifications[index - _comments.length],
                            );
                          },
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xD906172E),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(color: const Color(0x60FFFFFF)),
                    ),
                    child: TextField(
                      controller: _commentController,
                      enabled: !_isSendingMessage,
                      maxLength: 200,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        hintText: AppLocalizations.of(context)!
                            .type_in_chat_ucf,
                        hintStyle: TextStyle(
                          color: const Color(0xFFD1DBE6),
                          fontSize: 14.sp,
                        ),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _isSendingMessage ? null : _sendComment,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0ABFC4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _isSendingMessage
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: const Color(0xFF05394B),
                            size: 20.sp,
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentMessage(Comment comment) {
    final name = comment.userName?.trim().isNotEmpty == true
        ? comment.userName!.trim()
        : AppLocalizations.of(context)!.user_ucf;
    final avatar = comment.userAvatar?.trim() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildChatAvatar(name, avatar),
          SizedBox(width: 7.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xD107192A),
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: const Color(0x25FFFFFF)),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(
                      text: '$name: ',
                      style: const TextStyle(
                        color: Color(0xFF7BE8E9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: comment.comment ?? ''),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatAvatar(String name, String avatarUrl) {
    Widget fallback() {
      final initial = name.runes.isEmpty
          ? '?'
          : String.fromCharCode(name.runes.first).toUpperCase();
      return Container(
        width: 28.w,
        height: 28.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xB5FFFFFF), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF1870D5), Color(0xFF0ABFC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (avatarUrl.isEmpty) return fallback();
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 28.w,
        height: 28.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget _buildSystemNotification(_BidSystemNotification notification) {
    final bidName = notification.bidderName;
    final isBid = bidName != null && notification.amount != null;

    return TweenAnimationBuilder<double>(
      key: ValueKey(notification.id),
      tween: Tween<double>(begin: 0, end: notification.isLeaving ? 0 : 1),
      duration: notification.isLeaving
          ? _systemNotificationFadeTime
          : const Duration(milliseconds: 200),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 5),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: (_screenWidth < 800 ? 35 : 39).w,
          bottom: 8.h,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xD90A5546),
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(color: const Color(0x25FFFFFF)),
            ),
            child: isBid
                ? RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: const Color(0xFFA4FFF2),
                        fontSize: 14.sp,
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(text: '✦ '),
                        TextSpan(
                          text: bidName,
                          style: const TextStyle(
                            color: Color(0xFF7BE8E9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' ${AppLocalizations.of(context)!.placed_a_bid_of} ${_formatNotificationPrice(notification.amount!)}',
                        ),
                      ],
                    ),
                  )
                : Text(
                    notification.message ?? '',
                    style: TextStyle(
                      color: const Color(0xFFA4FFF2),
                      fontSize: 14.sp,
                      height: 1.45,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO RAIL
  // ============================================================
  Widget _buildPhotoRail() {
    if (_productImages.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final isMobile = _screenWidth < 800;
    final gallery = SizedBox(
      height: isMobile ? 58.h : 70.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _productImages.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final active = index == _currentImageIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentImageIndex = index),
            child: Container(
              width: isMobile ? 53.w : 66.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: active
                      ? const Color(0xFF0ABFC4)
                      : const Color(0xA8FFFFFF),
                  width: active ? 3 : 2,
                ),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Color(0x30000000), blurRadius: 16),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                _productImages[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Colors.grey,
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );

    final viewPhotosButton = GestureDetector(
      onTap: () => _openPhotoViewer(_currentImageIndex),
      child: Container(
        constraints: BoxConstraints(minHeight: 42.h),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFC8E6F1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 15.sp, color: const Color(0xFF087E99)),
            SizedBox(width: 5.w),
            Text(
              loc.view_photos_ucf,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF087E99),
              ),
            ),
          ],
        ),
      ),
    );

    final count = Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FB),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        '${_currentImageIndex + 1} / ${_productImages.length}',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF637A92),
        ),
      ),
    );

    return Container(
      margin: isMobile
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.w : 16.w,
        vertical: isMobile ? 10.h : 13.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 0 : 20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B15365A),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Text(
                      loc.product_photos_ucf,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102C4C),
                      ),
                    ),
                    const Spacer(),
                    viewPhotosButton,
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(child: gallery),
                    SizedBox(width: 8.w),
                    count,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  loc.product_photos_ucf,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102C4C),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(child: gallery),
                SizedBox(width: 10.w),
                count,
                SizedBox(width: 10.w),
                viewPhotosButton,
              ],
            ),
    );
  }

  void _openPhotoViewer(int index) {
    if (_productImages.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ProductPhotoViewer(images: _productImages, initialIndex: index),
      ),
    );
  }

  // ============================================================
  // SUMMARY — timer / price / leader
  // ============================================================
  Widget _buildSummary() {
    final title = (_product?.name ?? '').trim();
    final displayTitle = title.length > 32
        ? '${title.substring(0, 32)}...'
        : title;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B15365A),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF102C4C),
              letterSpacing: -0.5,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 14.h),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
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
              fontSize: 17.sp,
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
    final loc = AppLocalizations.of(context)!;
    String label;
    String value;
    Color? valColor;

    if (_auctionStatus == "upcoming") {
      label = '⏱ ${loc.starts_in_upper}';
      value = _formatTimeLeft(_timeUntilStart);
    } else if (_auctionStatus == "ended") {
      label = '⏱ ${loc.ended_upper}';
      value = '—';
    } else {
      label = '⏱ ${loc.time_left_upper}';
      value = _formatTimeLeft(_timeLeft);
      if (_isEndingSoon) valColor = const Color(0xFFDC3545);
    }

    return _metricBox(
      label: label,
      child: _isEndingSoon && _auctionStatus == 'live'
          ? _BlinkingTimerText(value: value)
          : Text(
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
      child: Text(_formatPrice(_currentHighestBid), textAlign: TextAlign.left),
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
    final loc = AppLocalizations.of(context)!;
    final isMobile = _screenWidth < 700;
    final steps = [
      {
        'num': '1',
        'icon': '☝️',
        'title': loc.how_step1_title,
        'desc': loc.how_step1_desc,
      },
      {
        'num': '2',
        'icon': '⏱️',
        'title': loc.how_step2_title,
        'desc': loc.how_step2_desc,
      },
      {
        'num': '3',
        'icon': '🏆',
        'title': loc.how_step3_title,
        'desc': loc.how_step3_desc,
      },
    ];

    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B15365A),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.how_title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF102C4C),
              letterSpacing: -0.45,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            loc.how_subtitle,
            style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF637A92)),
          ),
          SizedBox(height: 19.h),
          if (isMobile)
            Column(
              children: steps.asMap().entries.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  decoration: entry.key == steps.length - 1
                      ? null
                      : const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE4EDF6)),
                          ),
                        ),
                  child: _howStep(entry.value, showBorder: false),
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
            loc.how_note1,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF637A92),
              height: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            loc.how_note2,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF637A92),
              height: 1.5,
            ),
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
              border: Border(right: BorderSide(color: Color(0xFFE4EDF6))),
            )
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
                fontWeight: FontWeight.w800,
              ),
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
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  s['desc']!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF637A92),
                    height: 1.48,
                  ),
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
    final loc = AppLocalizations.of(context)!;
    final compact = _screenWidth < 600;
    final icon = Container(
      width: compact ? 38.w : 42.w,
      height: compact ? 38.w : 42.w,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FA),
        borderRadius: BorderRadius.circular(13.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.open_in_new_rounded,
        color: const Color(0xFF008FA5),
        size: 24.sp,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.buy_now_ucf,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF102C4C),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          loc.buy_now_subtitle,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF637A92)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final button = GestureDetector(
      onTap: _isBuyNowLoading ? null : _onBuyNowPressed,
      child: Container(
        width: compact ? double.infinity : null,
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
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00869C),
                ),
              )
            : Text(
                loc.buy_now_ucf,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00869C),
                ),
              ),
      ),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 22.h),
      padding: EdgeInsets.all(compact ? 13.w : 15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFDCECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B102C4C),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: compact
          ? Column(
              children: [
                Row(
                  children: [
                    icon,
                    SizedBox(width: 12.w),
                    Expanded(child: copy),
                  ],
                ),
                SizedBox(height: 12.h),
                button,
              ],
            )
          : Row(
              children: [
                icon,
                SizedBox(width: 12.w),
                Expanded(child: copy),
                SizedBox(width: 12.w),
                button,
              ],
            ),
    );
  }

  // ============================================================
  // BID DOCK
  // ============================================================
  Widget _buildBidDock() {
    final loc = AppLocalizations.of(context)!;
    final isLive = _auctionStatus == "live";
    final sliderEnabled = isLive && _pointPerBid != null && !_isBidSubmitting;
    final customEnabled =
        isLive && _pointPerBidCustom != null && !_isBidSubmitting;

    String sliderText;
    String customText;
    if (!isLive) {
      sliderText = _auctionStatus == 'upcoming'
          ? loc.starts_soon_ucf
          : loc.status_ended_ucf;
      customText = sliderText;
    } else {
      sliderText = _pointPerBid == null
          ? loc.slide_to_bid_ucf
          : '${loc.slide_to_bid_ucf} → ${_formatPointCost(_pointPerBid)} ${loc.points_plural_ucf}';
      customText = loc.manual_bid_ucf;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        decoration: const BoxDecoration(
          color: Color(0xEDFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFDCEAF5))),
          boxShadow: [
            BoxShadow(
              color: Color(0x1715365A),
              blurRadius: 35,
              offset: Offset(0, -12),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 830),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final thumbWidth = _thumbSize.w;
                      final maxOffset =
                          (constraints.maxWidth - thumbWidth - 10.w)
                              .clamp(0.0, double.infinity)
                              .toDouble();

                      return Opacity(
                        opacity: sliderEnabled ? 1 : .5,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0BBDBD), Color(0xFF1870D5)],
                            ),
                            borderRadius: BorderRadius.circular(17.r),
                            border: Border.all(color: const Color(0xFF65E6E1)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4400A4C0),
                                blurRadius: 28,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (_slideOffset > 0)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: _slideOffset + thumbWidth,
                                  child: Container(
                                    color: const Color(0x45FFFFFF),
                                  ),
                                ),
                              Positioned.fill(
                                left: 42.w,
                                right: 8.w,
                                child: Center(
                                  child: Text(
                                    sliderText,
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
                                top: 5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragStart: sliderEnabled
                                      ? (details) {
                                          setState(() {
                                            _thumbStartX =
                                                details.globalPosition.dx;
                                            _isDragging = true;
                                          });
                                        }
                                      : null,
                                  onHorizontalDragUpdate: sliderEnabled
                                      ? (details) {
                                          if (!_isDragging) return;
                                          final distance =
                                              details.globalPosition.dx -
                                              _thumbStartX;
                                          setState(
                                            () => _slideOffset = distance
                                                .clamp(0.0, maxOffset)
                                                .toDouble(),
                                          );
                                        }
                                      : null,
                                  onHorizontalDragCancel: sliderEnabled
                                      ? () {
                                          setState(() {
                                            _isDragging = false;
                                            _slideOffset = 0;
                                          });
                                        }
                                      : null,
                                  onHorizontalDragEnd: sliderEnabled
                                      ? (_) {
                                          if (!_isDragging) return;
                                          final distance = _slideOffset;
                                          final shouldBid =
                                              distance > maxOffset * .75;
                                          setState(() {
                                            _isDragging = false;
                                            _slideOffset = 0;
                                          });
                                          if (shouldBid) {
                                            _placeBidNow();
                                          } else if (distance >
                                              maxOffset * .10) {
                                            ToastComponent.showInfo(
                                              loc.slide_all_the_way_to_bid,
                                            );
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    width: thumbWidth,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(13.r),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x4D123A57),
                                          blurRadius: 14,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isBidSubmitting
                                        ? Center(
                                            child: SizedBox(
                                              width: 23.w,
                                              height: 23.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: Color(0xFF1870D5),
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.keyboard_arrow_right_rounded,
                                            size: 31.sp,
                                            color: const Color(0xFF1870D5),
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
                ),
                SizedBox(width: 8.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _screenWidth * .47),
                  child: GestureDetector(
                    onTap: customEnabled ? _showBidInputDialog : null,
                    child: Opacity(
                      opacity: customEnabled ? 1 : .5,
                      child: Container(
                        height: 56,
                        padding: EdgeInsets.symmetric(horizontal: 9.w),
                        decoration: BoxDecoration(
                          color: const Color(0xEDFFFFFF),
                          borderRadius: BorderRadius.circular(17.r),
                          border: Border.all(color: const Color(0x80FFFFFF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '▦',
                              style: TextStyle(
                                fontSize: 19.sp,
                                color: const Color(0xFF1163A8),
                              ),
                            ),
                            SizedBox(width: 7.w),
                            Flexible(
                              child: Text(
                                customText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _screenWidth <= 430 ? 11.sp : 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1163A8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
  // INFORMATION MODAL
  // ============================================================
  void _showInformationModal() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Container(
          width: min(_screenWidth - 32.w, 480.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 32.h,
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.auction_information,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 22.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                loc.auction_information_description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF637A92),
                ),
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
                              loc.starting_bid,
                              _formatPrice(_startingBid),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _infoTile(loc.bidders_ucf, '$_totalBids'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _infoTile(
                              loc.highest_bidder,
                              _highestBidder.isEmpty
                                  ? '—'
                                  : (_highestBidder.length > 7
                                        ? '${_highestBidder.substring(0, 7)}...'
                                        : _highestBidder),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _infoTile(
                              loc.next_bid,
                              _formatPrice(_minNextBidNow),
                            ),
                          ),
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
                              loc.product_description_ucf,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                              ),
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
                              loc.product_materials_note,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF637A92),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_buyNow == 1 && _auctionStatus != "ended") ...[
                        SizedBox(height: 12.h),
                        _buildModalBuyNowCard(),
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
                      loc.close_ucf,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102C4C),
                      ),
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
              color: const Color(0xFF102C4C),
            ),
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
    final loc = AppLocalizations.of(context)!;
    if (_auctionStatus != "live") {
      ToastComponent.showWarning(loc.auction_not_active);
      return;
    }
    if (_pointPerBidCustom == null) {
      ToastComponent.showInfo(loc.loading_manual_bid_cost);
      _pollData();
      return;
    }
    if (!is_logged_in.$) {
      _showLoginRequired();
      return;
    }
    _bidController.text = _minNextBidNow.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Container(
          width: min(_screenWidth - 32.w, 480.0),
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.your_bid_ucf,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                      ),
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
                '${loc.enter_amount_higher_current_bid} '
                '${loc.each_bid_costs} ${_formatPointCost(_pointPerBidCustom)} '
                '${loc.points_plural_ucf}.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF637A92),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _bidController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFDCEAF6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF0ABFC4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
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
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                      ),
                      child: Text(
                        loc.close_ucf,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF102C4C),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBidSubmitting
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _submitCustomBid();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                      ),
                      child: _isBidSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.confirm_bid_ucf,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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
    final url = _productVideoUrl();
    final videoId = _videoIdFromUrl(url);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xEB030C19),
      builder: (_) =>
          _ProductVideoDialog(videoUrl: url, youtubeVideoId: videoId),
    );
  }

  Widget _buildModalBuyNowCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFDCECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B102C4C),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FA),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: const Color(0xFF008FA5),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.buy_now_ucf,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102C4C),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      loc.buy_now_subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF637A92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBuyNowLoading ? null : _onBuyNowPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE9F8FB),
                foregroundColor: const Color(0xFF00869C),
                minimumSize: Size.fromHeight(43.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: const BorderSide(color: Color(0xFFC9EDF1)),
                ),
              ),
              child: _isBuyNowLoading
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00869C),
                      ),
                    )
                  : Text(loc.buy_now_ucf),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BID HISTORY
  // ============================================================
  void _openBidHistoryModal() {
    final loc = AppLocalizations.of(context)!;
    final bidLabel = _totalBids == 1
        ? loc.bid_singular_ucf
        : loc.bids_plural_ucf;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          width: min(_screenWidth - 32.w, 460.0),
          constraints: BoxConstraints(
            maxHeight: min(MediaQuery.of(context).size.height * .8, 660.0),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.auction_activity_upper,
                          style: TextStyle(
                            color: const Color(0xFF008E9A),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          loc.bid_history_ucf,
                          style: TextStyle(
                            fontSize: 25.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 22.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '$_totalBids $bidLabel · ${loc.newest_first_ucf}.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF637A92),
                ),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: _bidHistory.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
                        child: Center(
                          child: Text(
                            loc.no_bids_yet_ucf,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF637A92),
                            ),
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
                                    color: const Color(0xFF94A5B7),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.userName ?? loc.user_ucf,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(b.createdAt),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF637A92),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(b.amount ?? 0),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF007E94),
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

  // ============================================================
  // WINNER
  // ============================================================
  void _showWinnerModalDialog() {
    if (_winnerData == null) return;
    final loc = AppLocalizations.of(context)!;

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
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 8.h),
              Text(
                loc.auction_ended_exclamation,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: 90.w,
                height: 90.w,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  backgroundImage:
                      _winnerData!.avatar?.trim().isNotEmpty == true
                      ? NetworkImage(_winnerData!.avatar!.trim())
                      : null,
                  child: _winnerData!.avatar?.trim().isNotEmpty == true
                      ? null
                      : Icon(Icons.person, size: 40.sp),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                _winnerData!.userName ?? loc.winner_ucf,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _formatPrice(_winnerData!.amount ?? 0),
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                loc.congratulations_to_winner,
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
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  loc.close_ucf,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
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
                ShimmerHelper().buildBasicShimmer(
                  height: 30.h,
                  width: double.infinity,
                ),
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

class _BlinkingTimerText extends StatefulWidget {
  const _BlinkingTimerText({required this.value});

  final String value;

  @override
  State<_BlinkingTimerText> createState() => _BlinkingTimerTextState();
}

class _BlinkingTimerTextState extends State<_BlinkingTimerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: .55).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.value,
        textAlign: TextAlign.left,
        style: const TextStyle(color: Color(0xFFDC3545)),
      ),
    );
  }
}

class _ProductPhotoViewer extends StatefulWidget {
  const _ProductPhotoViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ProductPhotoViewer> createState() => _ProductPhotoViewerState();
}

class _ProductPhotoViewerState extends State<_ProductPhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1).toInt();
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int direction) {
    final next =
        (_index + direction + widget.images.length) % widget.images.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              top: 56.h,
              left: 50.w,
              right: 50.w,
              bottom: 20.h,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) => PhotoView(
                  imageProvider: NetworkImage(widget.images[index]),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Text(
                      '${_index + 1} / ${widget.images.length}',
                      style: TextStyle(
                        color: const Color(0xFF102C4C),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F9FD),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 9.w,
              top: 0,
              bottom: 0,
              child: Center(child: _arrow(Icons.chevron_left, () => _move(-1))),
            ),
            Positioned(
              right: 9.w,
              top: 0,
              bottom: 0,
              child: Center(child: _arrow(Icons.chevron_right, () => _move(1))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 43.w,
      height: 52.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF5F9FD),
          foregroundColor: const Color(0xFF1870D5),
          side: const BorderSide(color: Color(0xFFD8E7F4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Icon(icon, size: 36.sp),
      ),
    );
  }
}

class _ProductVideoDialog extends StatefulWidget {
  const _ProductVideoDialog({
    required this.videoUrl,
    required this.youtubeVideoId,
  });

  final String videoUrl;
  final String youtubeVideoId;

  @override
  State<_ProductVideoDialog> createState() => _ProductVideoDialogState();
}

class _ProductVideoDialogState extends State<_ProductVideoDialog> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      final playbackUrl = widget.youtubeVideoId.isNotEmpty
          ? 'https://www.youtube.com/embed/${Uri.encodeComponent(widget.youtubeVideoId)}?autoplay=1&rel=0'
          : widget.videoUrl;
      final uri = Uri.tryParse(playbackUrl);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final target = Uri.tryParse(request.url);
                return target != null &&
                        (target.scheme == 'http' || target.scheme == 'https')
                    ? NavigationDecision.navigate
                    : NavigationDecision.prevent;
              },
            ),
          )
          ..loadRequest(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(20.w, 72.h, 20.w, 20.h),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -46.h,
                left: 0,
                child: Text(
                  AppLocalizations.of(context)!.product_video_ucf,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
              ),
              Positioned(
                top: -52.h,
                right: 0,
                child: Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF102C4C)),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: ColoredBox(
                    color: Colors.black,
                    child: _buildVideoContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_controller != null) {
      return WebViewWidget(controller: _controller!);
    }

    if (widget.videoUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎬', style: TextStyle(fontSize: 50.sp)),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)!.no_video_available_ucf,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        AppLocalizations.of(context)!.unable_to_open_video_link,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
    );
  }
}
