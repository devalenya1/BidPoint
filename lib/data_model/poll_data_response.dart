// data_model/poll_data_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'poll_data_response.g.dart';

@JsonSerializable()
class PollDataResponse {
  bool? success;
  String? auction_end_date;
  double? point_per_bid;
  double? point_per_bid_custom;
  bool? auction_ended;
  Map<String, dynamic>? winner;
  bool? is_ending_soon;
  int? remaining_seconds;
  double? rating;
  int? reviews_count;
  BidData? bid_data;
  bool? is_in_wishlist;
  String? comments_html;
  String? reviews_html;
  String? bid_history_html;

  PollDataResponse({
    this.success,
    this.auction_end_date,
    this.point_per_bid,
    this.point_per_bid_custom,
    this.auction_ended,
    this.winner,
    this.is_ending_soon,
    this.remaining_seconds,
    this.rating,
    this.reviews_count,
    this.bid_data,
    this.is_in_wishlist,
    this.comments_html,
    this.reviews_html,
    this.bid_history_html,
  });

  factory PollDataResponse.fromJson(Map<String, dynamic> json) =>
      _$PollDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PollDataResponseToJson(this);
}

@JsonSerializable()
class BidData {
  double? highest_bid;
  int? total_bids;
  String? bidder_name;
  double? bid_amount;

  BidData({
    this.highest_bid,
    this.total_bids,
    this.bidder_name,
    this.bid_amount,
  });

  factory BidData.fromJson(Map<String, dynamic> json) =>
      _$BidDataFromJson(json);
  Map<String, dynamic> toJson() => _$BidDataToJson(this);
}