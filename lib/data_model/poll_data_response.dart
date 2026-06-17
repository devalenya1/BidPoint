// data_model/poll_data_response.dart
import 'dart:convert';

class PollDataResponse {
  bool? success;
  String? auctionEndDate;
  double? pointPerBid;
  double? pointPerBidCustom;
  bool? auctionEnded;
  Map<String, dynamic>? winner;
  bool? isEndingSoon;
  int? remainingSeconds;
  double? rating;
  int? reviewsCount;
  BidData? bidData;
  bool? isInWishlist;
  String? commentsHtml;
  String? reviewsHtml;
  String? bidHistoryHtml;

  PollDataResponse({
    this.success,
    this.auctionEndDate,
    this.pointPerBid,
    this.pointPerBidCustom,
    this.auctionEnded,
    this.winner,
    this.isEndingSoon,
    this.remainingSeconds,
    this.rating,
    this.reviewsCount,
    this.bidData,
    this.isInWishlist,
    this.commentsHtml,
    this.reviewsHtml,
    this.bidHistoryHtml,
  });

  factory PollDataResponse.fromJson(Map<String, dynamic> json) {
    return PollDataResponse(
      success: json['success'],
      auctionEndDate: json['auction_end_date'] ?? json['auctionEndDate'],
      pointPerBid: (json['point_per_bid'] ?? json['pointPerBid'])?.toDouble(),
      pointPerBidCustom: (json['point_per_bid_custom'] ?? json['pointPerBidCustom'])?.toDouble(),
      auctionEnded: json['auction_ended'] ?? json['auctionEnded'],
      winner: json['winner'],
      isEndingSoon: json['is_ending_soon'] ?? json['isEndingSoon'],
      remainingSeconds: json['remaining_seconds'] ?? json['remainingSeconds'],
      rating: json['rating']?.toDouble(),
      reviewsCount: json['reviews_count'] ?? json['reviewsCount'],
      bidData: json['bid_data'] != null ? BidData.fromJson(json['bid_data']) : 
                (json['bidData'] != null ? BidData.fromJson(json['bidData']) : null),
      isInWishlist: json['is_in_wishlist'] ?? json['isInWishlist'],
      commentsHtml: json['comments_html'] ?? json['commentsHtml'],
      reviewsHtml: json['reviews_html'] ?? json['reviewsHtml'],
      bidHistoryHtml: json['bid_history_html'] ?? json['bidHistoryHtml'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'auction_end_date': auctionEndDate,
    'point_per_bid': pointPerBid,
    'point_per_bid_custom': pointPerBidCustom,
    'auction_ended': auctionEnded,
    'winner': winner,
    'is_ending_soon': isEndingSoon,
    'remaining_seconds': remainingSeconds,
    'rating': rating,
    'reviews_count': reviewsCount,
    'bid_data': bidData?.toJson(),
    'is_in_wishlist': isInWishlist,
    'comments_html': commentsHtml,
    'reviews_html': reviewsHtml,
    'bid_history_html': bidHistoryHtml,
  };

  // Snake case getters for backward compatibility
  String? get auction_end_date => auctionEndDate;
  double? get point_per_bid => pointPerBid;
  double? get point_per_bid_custom => pointPerBidCustom;
  bool? get auction_ended => auctionEnded;
  bool? get is_ending_soon => isEndingSoon;
  int? get remaining_seconds => remainingSeconds;
  int? get reviews_count => reviewsCount;
  BidData? get bid_data => bidData;
  bool? get is_in_wishlist => isInWishlist;
  String? get comments_html => commentsHtml;
  String? get reviews_html => reviewsHtml;
  String? get bid_history_html => bidHistoryHtml;
}

class BidData {
  double? highestBid;
  int? totalBids;
  String? bidderName;
  double? bidAmount;

  BidData({
    this.highestBid,
    this.totalBids,
    this.bidderName,
    this.bidAmount,
  });

  factory BidData.fromJson(Map<String, dynamic> json) {
    return BidData(
      highestBid: (json['highest_bid'] ?? json['highestBid'])?.toDouble(),
      totalBids: json['total_bids'] ?? json['totalBids'],
      bidderName: json['bidder_name'] ?? json['bidderName'],
      bidAmount: (json['bid_amount'] ?? json['bidAmount'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'highest_bid': highestBid,
    'total_bids': totalBids,
    'bidder_name': bidderName,
    'bid_amount': bidAmount,
  };

  // Snake case getters
  double? get highest_bid => highestBid;
  int? get total_bids => totalBids;
  String? get bidder_name => bidderName;
  double? get bid_amount => bidAmount;
}