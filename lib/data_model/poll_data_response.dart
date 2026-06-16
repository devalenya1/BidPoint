// data_model/poll_data_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'poll_data_response.g.dart';

@JsonSerializable()
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

  factory PollDataResponse.fromJson(Map<String, dynamic> json) =>
      _$PollDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PollDataResponseToJson(this);
}

@JsonSerializable()
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

  factory BidData.fromJson(Map<String, dynamic> json) =>
      _$BidDataFromJson(json);
  Map<String, dynamic> toJson() => _$BidDataToJson(this);
}