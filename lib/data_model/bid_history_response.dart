// data_model/bid_history_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'bid_history_response.g.dart';

@JsonSerializable()
class BidHistoryResponse {
  bool? success;
  List<BidHistory>? bids;

  BidHistoryResponse({this.success, this.bids});

  factory BidHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$BidHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BidHistoryResponseToJson(this);
}

@JsonSerializable()
class BidHistory {
  int? id;
  int? user_id;
  String? user_name;
  double? amount;
  String? created_at;

  BidHistory({
    this.id,
    this.user_id,
    this.user_name,
    this.amount,
    this.created_at,
  });

  factory BidHistory.fromJson(Map<String, dynamic> json) =>
      _$BidHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$BidHistoryToJson(this);
}