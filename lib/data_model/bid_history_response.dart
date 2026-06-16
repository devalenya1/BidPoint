// data_model/bid_history_response.dart
import 'package:json_annotation/json_annotation.dart';

// part 'bid_history_response.g.dart';

@JsonSerializable()
class BidHistoryResponse {
  bool? success;
  List<BidHistory>? bids;

  BidHistoryResponse({
    this.success,
    this.bids,
  });

  factory BidHistoryResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == null && json['bids'] != null) {
      return BidHistoryResponse(
        success: true,
        bids: (json['bids'] as List)
            .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
    }
    return _$BidHistoryResponseFromJson(json);
  }
  
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

  factory BidHistory.fromJson(Map<String, dynamic> json) {
    return BidHistory(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      amount: json['amount'] is double ? json['amount'] : (json['amount'] as int?)?.toDouble(),
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }
  
  Map<String, dynamic> toJson() => _$BidHistoryToJson(this);
}