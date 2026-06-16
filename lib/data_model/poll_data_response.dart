// data_model/poll_data_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'poll_data_response.g.dart';

@JsonSerializable()
class PollDataResponse {
  bool? success;
  
  // Snake_case fields matching server response
  @JsonKey(name: 'auction_end_date')
  String? auctionEndDate;
  
  @JsonKey(name: 'point_per_bid')
  double? pointPerBid;
  
  @JsonKey(name: 'point_per_bid_custom')
  double? pointPerBidCustom;
  
  @JsonKey(name: 'auction_ended')
  bool? auctionEnded;
  
  Map<String, dynamic>? winner;
  
  @JsonKey(name: 'is_ending_soon')
  bool? isEndingSoon;
  
  @JsonKey(name: 'remaining_seconds')
  int? remainingSeconds;
  
  double? rating;
  
  @JsonKey(name: 'reviews_count')
  int? reviewsCount;
  
  @JsonKey(name: 'bid_data')
  BidData? bidData;
  
  @JsonKey(name: 'is_in_wishlist')
  bool? isInWishlist;
  
  @JsonKey(name: 'comments_html')
  String? commentsHtml;
  
  @JsonKey(name: 'reviews_html')
  String? reviewsHtml;
  
  @JsonKey(name: 'bid_history_html')
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

  factory PollDataResponse.fromJson(Map<String, dynamic> json) =>
      _$PollDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PollDataResponseToJson(this);
}

@JsonSerializable()
class BidData {
  @JsonKey(name: 'highest_bid')
  double? highestBid;
  
  @JsonKey(name: 'total_bids')
  int? totalBids;
  
  @JsonKey(name: 'bidder_name')
  String? bidderName;
  
  @JsonKey(name: 'bid_amount')
  double? bidAmount;

  BidData({
    this.highestBid,
    this.totalBids,
    this.bidderName,
    this.bidAmount,
  });

  factory BidData.fromJson(Map<String, dynamic> json) =>
      _$BidDataFromJson(json);
  Map<String, dynamic> toJson() => _$BidDataToJson(this);
}