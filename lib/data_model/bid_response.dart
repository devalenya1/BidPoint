// data_model/bid_response.dart
import 'package:json_annotation/json_annotation.dart';

// part 'bid_response.g.dart';

@JsonSerializable()
class BidResponse {
  bool? success;
  bool? result; // Add this for backward compatibility
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
    this.result,
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

  factory BidResponse.fromJson(Map<String, dynamic> json) {
    // Handle both 'success' and 'result' fields
    final successValue = json['success'] ?? json['result'];
    return _$BidResponseFromJson(json)..success = successValue is bool ? successValue : null;
  }
  
  Map<String, dynamic> toJson() => _$BidResponseToJson(this);
}