// data_model/poll_data_response.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
 
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

// ============ SUPPORTING MODELS ============

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

  Review({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'] ?? json['createdAt'],
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
  };

  // Snake case getters
  int? get user_id => userId;
  String? get user_name => userName;
  String? get user_avatar => userAvatar;
  String? get created_at => createdAt;
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