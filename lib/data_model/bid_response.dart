// data_model/bid_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'bid_response.dart';

@JsonSerializable()
class BidResponse {
  bool? success;
  String? message;
  dynamic bid;
  int? points_deducted;
  double? remaining_balance;
  double? next_min_bid;
  double? current_highest;
  bool? time_extended;
  int? extended_by;
  String? new_end_date;

  BidResponse({
    this.success,
    this.message,
    this.bid,
    this.points_deducted,
    this.remaining_balance,
    this.next_min_bid,
    this.current_highest,
    this.time_extended,
    this.extended_by,
    this.new_end_date,
  });

  factory BidResponse.fromJson(Map<String, dynamic> json) =>
      _$BidResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BidResponseToJson(this);
}