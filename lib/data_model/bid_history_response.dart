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
  int? userId;
  String? userName;
  double? amount;
  String? createdAt;

  BidHistory({
    this.id,
    this.userId,
    this.userName,
    this.amount,
    this.createdAt,
  });

  factory BidHistory.fromJson(Map<String, dynamic> json) =>
      _$BidHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$BidHistoryToJson(this);
}