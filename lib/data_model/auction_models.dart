import 'dart:convert';

double? _doubleFromJson(dynamic value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();

  final normalized = value
      .toString()
      .replaceAll(',', '')
      .replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(normalized);
}

int? _intFromJson(dynamic value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _boolFromJson(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;

  switch (value.toString().trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
      return true;
    case '0':
    case 'false':
    case 'no':
      return false;
  }
  return null;
}

// ============================================
// 1. BID RESPONSE
// ============================================

BidResponse bidResponseFromJson(String str) => BidResponse.fromJson(json.decode(str));

String bidResponseToJson(BidResponse data) => json.encode(data.toJson());

class BidResponse {
  bool? success;
  bool? result;
  String? message;
  dynamic bid;
  int? pointsDeducted;
  double? remainingBalance;
  double? nextMinBid;
  double? currentHighest;
  bool? timeExtended;
  int? extendedBy;
  String? newEndDate;
  double? balance;
  double? pointsUsed;
  double? pointPerBid;
  double? pointPerBidCustom;

  /// Realtime payload of the bid, pushed through Pusher on the
  /// `product.{id}` channel.
  Map<String, dynamic>? realtime;

  BidResponse({
    this.success,
    this.result,
    this.message,
    this.bid,
    this.pointsDeducted,
    this.remainingBalance,
    this.nextMinBid,
    this.currentHighest,
    this.timeExtended,
    this.extendedBy,
    this.newEndDate,
    this.balance,
    this.pointsUsed,
    this.pointPerBid,
    this.pointPerBidCustom,
    this.realtime,
  });

  factory BidResponse.fromJson(Map<String, dynamic> json) {
    final successValue = json['success'] ?? json['result'];

    // The API returns the bid details inside "data", the older web shaped
    // payload puts them on the root. Both are supported.
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};

    dynamic pick(String key) => json[key] ?? data[key];

    return BidResponse(
      success: _boolFromJson(successValue),
      result: _boolFromJson(json['result']),
      message: json['message'],
      bid: pick('bid'),
      pointsDeducted:
          _intFromJson(pick('points_deducted') ?? pick('pointsDeducted')),
      remainingBalance: _doubleFromJson(
          pick('remaining_balance') ?? pick('remainingBalance')),
      nextMinBid:
          _doubleFromJson(pick('next_min_bid') ?? pick('nextMinBid')),
      currentHighest:
          _doubleFromJson(pick('current_highest') ?? pick('currentHighest')),
      timeExtended:
          _boolFromJson(pick('time_extended') ?? pick('timeExtended')),
      extendedBy: _intFromJson(pick('extended_by') ?? pick('extendedBy')),
      newEndDate: (pick('new_end_date') ?? pick('newEndDate'))?.toString(),
      balance: _doubleFromJson(pick('balance') ?? pick('user_balance')),
      pointsUsed: _doubleFromJson(pick('points_used') ??
          pick('pointsUsed') ??
          pick('points_deducted') ??
          pick('pointsDeducted')),
      pointPerBid:
          _doubleFromJson(pick('point_per_bid') ?? pick('pointPerBid')),
      pointPerBidCustom: _doubleFromJson(
          pick('point_per_bid_custom') ?? pick('pointPerBidCustom')),
      realtime: pick('realtime') is Map
          ? Map<String, dynamic>.from(pick('realtime') as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'result': result,
    'message': message,
    'bid': bid,
    'points_deducted': pointsDeducted,
    'remaining_balance': remainingBalance,
    'next_min_bid': nextMinBid,
    'current_highest': currentHighest,
    'time_extended': timeExtended,
    'extended_by': extendedBy,
    'new_end_date': newEndDate,
    'balance': balance,
    'points_used': pointsUsed,
    'point_per_bid': pointPerBid,
    'point_per_bid_custom': pointPerBidCustom,
    'realtime': realtime,
  };

  // Snake case getters for backward compatibility
  int? get points_deducted => pointsDeducted;
  double? get remaining_balance => remainingBalance;
  double? get next_min_bid => nextMinBid;
  double? get current_highest => currentHighest;
  bool? get time_extended => timeExtended;
  int? get extended_by => extendedBy;
  String? get new_end_date => newEndDate;
  double? get point_per_bid => pointPerBid;
  double? get point_per_bid_custom => pointPerBidCustom;
}


// ============================================
// 2. COMMENT RESPONSE
// ============================================

CommentResponse commentResponseFromJson(String str) => CommentResponse.fromJson(json.decode(str));

String commentResponseToJson(CommentResponse data) => json.encode(data.toJson());

class CommentResponse {
  bool? success;
  List<Comment>? comments;
  int? status;

  CommentResponse({
    this.success,
    this.comments,
    this.status,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    List<Comment> commentList = [];
    
    if (json['data'] != null && json['data'] is List) {
      commentList = (json['data'] as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json['comments'] != null && json['comments'] is List) {
      commentList = (json['comments'] as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json is List) {
      commentList = (json as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return CommentResponse(
      success: json['success'] ?? true,
      comments: commentList,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': comments?.map((c) => c.toJson()).toList(),
    'status': status,
  };

  bool get hasComments => (comments?.length ?? 0) > 0;
  int get commentCount => comments?.length ?? 0;
  List<Comment> get allComments => comments ?? [];
}


// ============================================
// 3. ADD COMMENT RESPONSE
// ============================================

AddCommentResponse addCommentResponseFromJson(String str) => AddCommentResponse.fromJson(json.decode(str));

String addCommentResponseToJson(AddCommentResponse data) => json.encode(data.toJson());

class AddCommentResponse {
  bool? success;
  String? message;
  Comment? comment;

  AddCommentResponse({
    this.success,
    this.message,
    this.comment,
  });

  factory AddCommentResponse.fromJson(Map<String, dynamic> json) {
    return AddCommentResponse(
      success: json['success'],
      message: json['message'],
      comment: json['data'] != null ? Comment.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'comment': comment?.toJson(),
  };
}


// ============================================
// 4. REVIEW RESPONSE
// ============================================

ReviewResponse reviewResponseFromJson(String str) => ReviewResponse.fromJson(json.decode(str));

String reviewResponseToJson(ReviewResponse data) => json.encode(data.toJson());

class ReviewResponse {
  bool? success;
  List<Review>? reviews;

  ReviewResponse({
    this.success,
    this.reviews,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    List<Review> reviewList = [];
    
    if (json['data'] != null && json['data'] is List) {
      reviewList = (json['data'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['reviews'] != null && json['reviews'] is List) {
      reviewList = (json['reviews'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json is List) {
      reviewList = (json as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return ReviewResponse(
      success: json['success'] ?? true,
      reviews: reviewList,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'reviews': reviews?.map((r) => r.toJson()).toList(),
  };

  bool get hasReviews => (reviews?.length ?? 0) > 0;
  int get reviewCount => reviews?.length ?? 0;
  List<Review> get allReviews => reviews ?? [];
}


// ============================================
// 5. ADD REVIEW RESPONSE
// ============================================

AddReviewResponse addReviewResponseFromJson(String str) => AddReviewResponse.fromJson(json.decode(str));

String addReviewResponseToJson(AddReviewResponse data) => json.encode(data.toJson());

class AddReviewResponse {
  bool? success;
  String? message;

  AddReviewResponse({
    this.success,
    this.message,
  });

  factory AddReviewResponse.fromJson(Map<String, dynamic> json) {
    return AddReviewResponse(
      success: json['success'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
  };
}


// ============================================
// 6. BID HISTORY RESPONSE
// ============================================

BidHistoryResponse bidHistoryResponseFromJson(String str) => BidHistoryResponse.fromJson(json.decode(str));

String bidHistoryResponseToJson(BidHistoryResponse data) => json.encode(data.toJson());

class BidHistoryResponse {
  bool? success;
  List<BidHistory>? bids;
  Pagination? pagination;
  int? status;

  BidHistoryResponse({
    this.success,
    this.bids,
    this.pagination,
    this.status,
  });

  factory BidHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<BidHistory> bidList = [];
    
    if (json['data'] != null && json['data'] is List) {
      bidList = (json['data'] as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    } else if (json['bids'] != null && json['bids'] is List) {
      bidList = (json['bids'] as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    } else if (json is List) {
      bidList = (json as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return BidHistoryResponse(
      success: json['success'] ?? true,
      bids: bidList,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': bids?.map((b) => b.toJson()).toList(),
    'pagination': pagination?.toJson(),
    'status': status,
  };

  bool get hasBids => (bids?.length ?? 0) > 0;
  int get bidCount => bids?.length ?? 0;
  List<BidHistory> get allBids => bids ?? [];
  
  double get highestBidAmount {
    if (bids == null || bids!.isEmpty) return 0.0;
    return bids!.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
  }
  
  BidHistory? get highestBid {
    if (bids == null || bids!.isEmpty) return null;
    return bids!.reduce((a, b) => (a.amount ?? 0.0) > (b.amount ?? 0.0) ? a : b);
  }
  
  BidHistory? get latestBid {
    if (bids == null || bids!.isEmpty) return null;
    return bids!.first;
  }
}


// ============================================
// 7. WISHLIST RESPONSE
// ============================================

WishlistResponse wishlistResponseFromJson(String str) => WishlistResponse.fromJson(json.decode(str));

String wishlistResponseToJson(WishlistResponse data) => json.encode(data.toJson());

class WishlistResponse {
  bool? success;
  String? message;

  WishlistResponse({
    this.success,
    this.message,
  });

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      success: json['success'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
  };
}
 

// ============================================
// 8. POLL DATA RESPONSE (MAIN AUCTION DATA)
// ============================================

PollDataResponse pollDataResponseFromJson(String str) =>
    PollDataResponse.fromJson(json.decode(str));

String pollDataResponseToJson(PollDataResponse data) =>
    json.encode(data.toJson());

class PollDataResponse {
  bool? success;
  String? auctionEndDate;
  String? auctionStartDate;
  double? startingBid;
  double? pointPerBid;
  double? pointPerBidCustom;
  bool? auctionEnded;
  bool? isEndingSoon;
  int? remainingSeconds;
  double? rating;
  int? reviewsCount;
  bool? isInWishlist;
  double? highestBid;
  String? highestBidFormatted;
  int? totalBids;
  String? lastBidderName;
  double? lastBidAmount;
  bool? isAuctionUpcoming;
  String? upcomingStatus;
  bool? myStatus;
  bool? userHasBid;
  int? buyNow;
  String? payLink;
  String? buyNowLink;

  // ═══ FIX: points balance comes back on every poll ═══
  int? balance;

  Winner? winner;
  List<Comment>? comments;
  List<Review>? reviews;
  List<BidHistoryItem>? bidHistory;

  PollDataResponse({
    this.success,
    this.auctionEndDate,
    this.auctionStartDate,
    this.startingBid,
    this.pointPerBid,
    this.pointPerBidCustom,
    this.auctionEnded,
    this.isEndingSoon,
    this.remainingSeconds,
    this.rating,
    this.reviewsCount,
    this.isInWishlist,
    this.highestBid,
    this.highestBidFormatted,
    this.totalBids,
    this.lastBidderName,
    this.lastBidAmount,
    this.isAuctionUpcoming,
    this.upcomingStatus,
    this.myStatus,
    this.userHasBid,
    this.buyNow,
    this.payLink,
    this.buyNowLink,
    this.balance, // ═══ FIX ═══
    this.winner,
    this.comments,
    this.reviews,
    this.bidHistory,
  });

  factory PollDataResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return PollDataResponse(
      success: _boolFromJson(json['success']) ?? true,
      auctionEndDate: (data['auction_end_date'] ??
              data['auctionEndDate'] ??
              json['auction_end_date'])
          ?.toString(),
      auctionStartDate: (data['auction_start_date'] ??
              data['auctionStartDate'] ??
              json['auction_start_date'])
          ?.toString(),
      startingBid:
          _doubleFromJson(data['starting_bid'] ?? data['startingBid']),
      pointPerBid:
          _doubleFromJson(data['point_per_bid'] ?? data['pointPerBid']),
      pointPerBidCustom: _doubleFromJson(
          data['point_per_bid_custom'] ?? data['pointPerBidCustom']),
      auctionEnded:
          _boolFromJson(data['auction_ended'] ?? data['auctionEnded']),
      isEndingSoon:
          _boolFromJson(data['is_ending_soon'] ?? data['isEndingSoon']),
      remainingSeconds:
          _intFromJson(data['remaining_seconds'] ?? data['remainingSeconds']),
      rating: _doubleFromJson(data['rating']),
      reviewsCount:
          _intFromJson(data['reviews_count'] ?? data['reviewsCount']),
      isInWishlist: _boolFromJson(
              data['is_in_wishlist'] ?? data['isInWishlist']) ??
          false,
      highestBid:
          _doubleFromJson(data['highest_bid'] ?? data['highestBid']),
      highestBidFormatted: data['highest_bid_formatted'],
      totalBids: _intFromJson(data['total_bids'] ?? data['totalBids']),
      lastBidderName:
          (data['last_bidder_name'] ?? data['lastBidderName'])?.toString(),
      lastBidAmount: _doubleFromJson(
          data['last_bid_amount'] ?? data['lastBidAmount']),
      isAuctionUpcoming: _boolFromJson(data['is_auction_upcoming'] ??
              data['isAuctionUpcoming']) ??
          false,
      upcomingStatus:
          (data['upcoming_status'] ?? data['upcomingStatus'])?.toString(),
      userHasBid: _boolFromJson(data['user_has_bid'] ??
              data['userHasBid'] ??
              json['user_has_bid'] ??
              json['userHasBid']) ??
          false,
      myStatus:
          _boolFromJson(data['my_status'] ?? data['myStatus']),
      buyNow: _intFromJson(data['buy_now'] ?? data['buyNow']),
      payLink: (data['pay_link'] ?? data['payLink'])?.toString(),
      buyNowLink: (data['buy_now_link'] ??
              data['buyNowLink'] ??
              json['buy_now_link'] ??
              json['buyNowLink'])
          ?.toString(),

      // ═══ FIX: balance can be on data OR on the root json ═══
      balance: _intFromJson(
        data['balance'] ??
            data['user_balance'] ??
            data['points_balance'] ??
            data['points'] ??
            json['balance'] ??
            json['user_balance'] ??
            json['points_balance'] ??
            json['points'],
      ),

      winner: data['winner'] != null ? Winner.fromJson(data['winner']) : null,
      comments: data['comments'] != null
          ? List<Comment>.from(data['comments'].map((x) => Comment.fromJson(x)))
          : [],
      reviews: data['reviews'] != null
          ? List<Review>.from(data['reviews'].map((x) => Review.fromJson(x)))
          : [],
      bidHistory: data['bid_history'] != null
          ? List<BidHistoryItem>.from(
              data['bid_history'].map((x) => BidHistoryItem.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'auction_end_date': auctionEndDate,
        'auction_start_date': auctionStartDate,
        'starting_bid': startingBid,
        'point_per_bid': pointPerBid,
        'point_per_bid_custom': pointPerBidCustom,
        'auction_ended': auctionEnded,
        'is_ending_soon': isEndingSoon,
        'remaining_seconds': remainingSeconds,
        'rating': rating,
        'reviews_count': reviewsCount,
        'is_in_wishlist': isInWishlist,
        'highest_bid': highestBid,
        'highest_bid_formatted': highestBidFormatted,
        'total_bids': totalBids,
        'last_bidder_name': lastBidderName,
        'last_bid_amount': lastBidAmount,
        'is_auction_upcoming': isAuctionUpcoming,
        'upcoming_status': upcomingStatus,
        'my_status': myStatus,
        'user_has_bid': userHasBid,
        'buy_now': buyNow,
        'pay_link': payLink,
        'buy_now_link': buyNowLink,
        'balance': balance, // ═══ FIX ═══
        'winner': winner?.toJson(),
        'comments': comments?.map((x) => x.toJson()).toList(),
        'reviews': reviews?.map((x) => x.toJson()).toList(),
        'bid_history': bidHistory?.map((x) => x.toJson()).toList(),
      };

  // ============ SNAKE_CASE GETTERS ============
  String? get auction_end_date => auctionEndDate;
  String? get auction_start_date => auctionStartDate;
  double? get starting_bid => startingBid;
  double? get point_per_bid => pointPerBid;
  double? get point_per_bid_custom => pointPerBidCustom;
  bool? get auction_ended => auctionEnded;
  bool? get is_ending_soon => isEndingSoon;
  int? get remaining_seconds => remainingSeconds;
  int? get reviews_count => reviewsCount;
  bool? get is_in_wishlist => isInWishlist;
  String? get upcoming_status => upcomingStatus;
  bool? get my_status => myStatus;
  int? get buy_now => buyNow;
  String? get pay_link => payLink;

  // ============ HELPERS ============
  bool get isAuctionEnded => auctionEnded ?? false;
  bool get isEndingSoonValue => isEndingSoon ?? false;
  double get highestBidValue => highestBid ?? 0.0;
  String get highestBidDisplay => highestBidFormatted ?? '\$0.00';
  int get totalBidsCount => totalBids ?? 0;
  bool get hasBids => (totalBids ?? 0) > 0;
  bool get hasWinner => winner != null;
  bool get hasComments => (comments?.length ?? 0) > 0;
  bool get hasReviews => (reviews?.length ?? 0) > 0;
  bool get hasBidHistory => (bidHistory?.length ?? 0) > 0;
  bool get isUpcoming => upcomingStatus == 'Upcoming';
  bool get isLive => upcomingStatus == 'Live' || upcomingStatus == null;
  bool get isEnded => upcomingStatus == 'Ended';
  bool get isUserWinning => myStatus ?? false;
  bool get isBuyNowAvailable => buyNow == 1;
  bool get hasPaymentLink => payLink != null && payLink!.isNotEmpty;
}

// ============================================
// 9. SUPPORTING MODELS (Comment, Review, Winner, BidHistoryItem, BidHistory, Pagination)
// ============================================

class Comment {
  int? id;
  int? userId;
  String? userName;
  String? userAvatar;
  String? comment;
  String? likes;
  int? offers;
  String? createdAt;

  Comment({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.comment,
    this.likes,
    this.offers,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? json['comment_id'],
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      comment: json['comment'],
      likes: json['likes']?.toString(),
      offers: _intFromJson(json['offers'] ?? json['offer']) ?? 0,
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'user_avatar': userAvatar,
    'comment': comment,
    'likes': likes,
    'offers': offers,
    'created_at': createdAt,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get user_avatar => userAvatar;
  String? get created_at => createdAt;
  
  int get likesCount => int.tryParse(likes ?? '0') ?? 0;
  bool get isOffer => offers == 1;
}


class Review {
  int? id;
  int? userId;
  String? userName;
  String? userAvatar;
  int? rating;
  String? comment;
  String? createdAt;
  List<String>? photos;

  Review({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.rating,
    this.comment,
    this.createdAt,
    this.photos,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'] ?? json['customer_name'],
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'] ?? json['createdAt'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'user_avatar': userAvatar,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt,
    'photos': photos,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get user_avatar => userAvatar;
  String? get created_at => createdAt;
}


class Winner {
  int? userId;
  String? userName;
  double? amount;
  String? avatar;

  Winner({
    this.userId,
    this.userName,
    this.amount,
    this.avatar,
  });

  factory Winner.fromJson(Map<String, dynamic> json) {
    return Winner(
      userId: _intFromJson(json['user_id'] ?? json['userId'] ?? json['id']),
      userName:
          (json['user_name'] ?? json['userName'] ?? json['name'])?.toString(),
      amount: _doubleFromJson(json['amount']),
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'amount': amount,
    'avatar': avatar,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
}


class BidHistoryItem {
  int? userId;
  String? userName;
  double? amount;
  String? createdAt; 

  BidHistoryItem({
    this.userId,
    this.userName,
    this.amount,
    this.createdAt,
  });

  factory BidHistoryItem.fromJson(Map<String, dynamic> json) {
    return BidHistoryItem(
      userId: _intFromJson(json['user_id'] ?? json['userId']),
      userName: (json['user_name'] ?? json['userName'] ?? json['name'])
          ?.toString(),
      amount: _doubleFromJson(json['amount']),
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'amount': amount,
    'created_at': createdAt,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get created_at => createdAt;
  
  String get formattedAmount => '\$${amount?.toStringAsFixed(2) ?? '0.00'}';
}


class BidHistory {
  int? id;
  int? userId;
  String? userName;
  double? amount;
  String? amountFormatted;
  String? createdAt;

  BidHistory({
    this.id,
    this.userId,
    this.userName,
    this.amount,
    this.amountFormatted,
    this.createdAt,
  });

  factory BidHistory.fromJson(Map<String, dynamic> json) {
    double? amountValue;
    if (json['amount'] != null) {
      if (json['amount'] is double) {
        amountValue = json['amount'];
      } else if (json['amount'] is int) {
        amountValue = (json['amount'] as int).toDouble();
      } else if (json['amount'] is String) {
        amountValue = double.tryParse(json['amount']);
      }
    }

    return BidHistory(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      amount: amountValue,
      amountFormatted: json['amount_formatted'] ?? json['amountFormatted'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'amount': amount,
    'amount_formatted': amountFormatted,
    'created_at': createdAt,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get amount_formatted => amountFormatted;
  String? get created_at => createdAt;
  
  String get formattedAmount => amountFormatted ?? '\$${(amount ?? 0.0).toStringAsFixed(2)}';
  String get displayName => userName ?? 'Unknown User';
}


class Pagination {
  int? total;
  int? perPage;
  int? currentPage;
  int? lastPage;

  Pagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'per_page': perPage,
    'current_page': currentPage,
    'last_page': lastPage,
  };

  // Snake case getters
  int? get per_page => perPage;
  int? get current_page => currentPage;
  int? get last_page => lastPage;
  
  // Helper methods
  bool get hasMorePages => (currentPage ?? 1) < (lastPage ?? 1);
  int get totalPages => lastPage ?? 1;
  int get nextPage => hasMorePages ? (currentPage ?? 1) + 1 : (currentPage ?? 1);
}
