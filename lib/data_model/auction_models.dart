import 'dart:convert';

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
  });

  factory BidResponse.fromJson(Map<String, dynamic> json) {
    final successValue = json['success'] ?? json['result'];
    return BidResponse(
      success: successValue is bool ? successValue : null,
      result: json['result'],
      message: json['message'],
      bid: json['bid'],
      pointsDeducted: json['points_deducted'] ?? json['pointsDeducted'],
      remainingBalance: (json['remaining_balance'] ?? json['remainingBalance'])?.toDouble(),
      nextMinBid: (json['next_min_bid'] ?? json['nextMinBid'])?.toDouble(),
      currentHighest: (json['current_highest'] ?? json['currentHighest'])?.toDouble(),
      timeExtended: json['time_extended'] ?? json['timeExtended'],
      extendedBy: json['extended_by'] ?? json['extendedBy'],
      newEndDate: json['new_end_date'] ?? json['newEndDate'],
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
  };

  // Snake case getters for backward compatibility
  int? get points_deducted => pointsDeducted;
  double? get remaining_balance => remainingBalance;
  double? get next_min_bid => nextMinBid;
  double? get current_highest => currentHighest;
  bool? get time_extended => timeExtended;
  int? get extended_by => extendedBy;
  String? get new_end_date => newEndDate;
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

PollDataResponse pollDataResponseFromJson(String str) => PollDataResponse.fromJson(json.decode(str));

String pollDataResponseToJson(PollDataResponse data) => json.encode(data.toJson());

class PollDataResponse {
  bool? success;
  String? auctionEndDate;
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
  Winner? winner;
  List<Comment>? comments;
  List<Review>? reviews;
  List<BidHistoryItem>? bidHistory;

  PollDataResponse({
    this.success,
    this.auctionEndDate,
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
    this.winner,
    this.comments,
    this.reviews,
    this.bidHistory,
  });

  factory PollDataResponse.fromJson(Map<String, dynamic> json) {
    return PollDataResponse(
      success: json['success'],
      auctionEndDate: json['auction_end_date'],
      pointPerBid: (json['point_per_bid'] ?? json['pointPerBid'])?.toDouble(),
      pointPerBidCustom: (json['point_per_bid_custom'] ?? json['pointPerBidCustom'])?.toDouble(),
      auctionEnded: json['auction_ended'],
      isEndingSoon: json['is_ending_soon'],
      remainingSeconds: json['remaining_seconds'],
      rating: json['rating']?.toDouble(),
      reviewsCount: json['reviews_count'],
      isInWishlist: json['is_in_wishlist'],
      highestBid: (json['highest_bid'] ?? json['highestBid'])?.toDouble(),
      highestBidFormatted: json['highest_bid_formatted'],
      totalBids: json['total_bids'],
      lastBidderName: json['last_bidder_name'],
      lastBidAmount: (json['last_bid_amount'] ?? json['lastBidAmount'])?.toDouble(),
      winner: json['winner'] != null ? Winner.fromJson(json['winner']) : null,
      comments: json['comments'] != null 
          ? List<Comment>.from(json['comments'].map((x) => Comment.fromJson(x)))
          : [],
      reviews: json['reviews'] != null 
          ? List<Review>.from(json['reviews'].map((x) => Review.fromJson(x)))
          : [],
      bidHistory: json['bid_history'] != null 
          ? List<BidHistoryItem>.from(json['bid_history'].map((x) => BidHistoryItem.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'auction_end_date': auctionEndDate,
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
    'winner': winner?.toJson(),
    'comments': comments?.map((x) => x.toJson()).toList(),
    'reviews': reviews?.map((x) => x.toJson()).toList(),
    'bid_history': bidHistory?.map((x) => x.toJson()).toList(),
  };

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  String? get auction_end_date => auctionEndDate;
  double? get point_per_bid => pointPerBid;
  double? get point_per_bid_custom => pointPerBidCustom;
  bool? get auction_ended => auctionEnded;
  bool? get is_ending_soon => isEndingSoon;
  int? get remaining_seconds => remainingSeconds;
  int? get reviews_count => reviewsCount;
  bool? get is_in_wishlist => isInWishlist;
  String? get comments_html => null;
  String? get reviews_html => null;
  String? get bid_history_html => null;
  
  // ============ HELPER METHODS ============
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
  String? createdAt;

  Comment({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.comment,
    this.likes,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      comment: json['comment'],
      likes: json['likes']?.toString(),
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
    'created_at': createdAt,
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get user_avatar => userAvatar;
  String? get created_at => createdAt;
  
  int get likesCount => int.tryParse(likes ?? '0') ?? 0;
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
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      amount: (json['amount'])?.toDouble(),
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
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      amount: (json['amount'])?.toDouble(),
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