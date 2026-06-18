// data_model/bid_history_response.dart
import 'dart:convert';

BidHistoryResponse bidHistoryResponseFromJson(String str) => BidHistoryResponse.fromJson(json.decode(str));

String bidHistoryResponseToJson(BidHistoryResponse data) => json.encode(data.toJson());

class BidHistoryResponse {
  bool? success;
  List<BidHistory>? bids;
  Pagination? pagination;
  int? status;

  BidHistoryResponse({
    this.success,
    this.bids,
    this.pagination,
    this.status,
  });

  factory BidHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<BidHistory> bidList = [];
    
    // Check if data is in 'data' field (server format)
    if (json['data'] != null && json['data'] is List) {
      bidList = (json['data'] as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    } 
    // Check if bids are in 'bids' field (fallback)
    else if (json['bids'] != null && json['bids'] is List) {
      bidList = (json['bids'] as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    }
    // Check if the entire response is a list
    else if (json is List) {
      bidList = (json as List)
          .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return BidHistoryResponse(
      success: json['success'] ?? true,
      bids: bidList,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': bids?.map((b) => b.toJson()).toList(),
    'pagination': pagination?.toJson(),
  };

  // ============ HELPER METHODS ============
  
  bool get hasBids => (bids?.length ?? 0) > 0;
  
  int get bidCount => bids?.length ?? 0;
  
  List<BidHistory> get allBids => bids ?? [];
  
  double get highestBidAmount {
    if (bids == null || bids!.isEmpty) return 0.0;
    return bids!.map((b) => b.amount ?? 0.0).reduce((a, b) => a > b ? a : b);
  }
  
  BidHistory? get highestBid {
    if (bids == null || bids!.isEmpty) return null;
    return bids!.reduce((a, b) => (a.amount ?? 0.0) > (b.amount ?? 0.0) ? a : b);
  }
  
  BidHistory? get latestBid {
    if (bids == null || bids!.isEmpty) return null;
    return bids!.first;
  }
}

class BidHistory {
  int? id;
  int? userId;
  String? userName;
  double? amount;
  String? amountFormatted;
  String? createdAt;

  BidHistory({
    this.id,
    this.userId,
    this.userName,
    this.amount,
    this.amountFormatted,
    this.createdAt,
  });

  factory BidHistory.fromJson(Map<String, dynamic> json) {
    // Handle amount - could be double or int
    double? amountValue;
    if (json['amount'] != null) {
      if (json['amount'] is double) {
        amountValue = json['amount'];
      } else if (json['amount'] is int) {
        amountValue = (json['amount'] as int).toDouble();
      } else if (json['amount'] is String) {
        amountValue = double.tryParse(json['amount']);
      }
    }

    return BidHistory(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      amount: amountValue,
      amountFormatted: json['amount_formatted'] ?? json['amountFormatted'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'amount': amount,
    'amount_formatted': amountFormatted,
    'created_at': createdAt,
  };

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  int? get user_id => userId;
  String? get user_name => userName;
  String? get amount_formatted => amountFormatted;
  String? get created_at => createdAt;
  
  // ============ HELPER METHODS ============
  
  String get formattedAmount => amountFormatted ?? '\$${(amount ?? 0.0).toStringAsFixed(2)}';
  
  String get displayName => userName ?? 'Unknown User';
  
  String get formattedCreatedAt {
    if (createdAt == null) return '';
    // If already formatted, return as is
    if (createdAt!.contains(',')) return createdAt!;
    
    try {
      final date = DateTime.parse(createdAt!);
      return '${date.day} ${_monthAbbr(date.month)} ${date.year}, ${_timeFormat(date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return createdAt ?? '';
    }
  }
  
  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  String _timeFormat(int hour) {
    if (hour == 0) return '12';
    if (hour > 12) return (hour - 12).toString();
    return hour.toString();
  }
}

class Pagination {
  int? total;
  int? perPage;
  int? currentPage;
  int? lastPage;

  Pagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'per_page': perPage,
    'current_page': currentPage,
    'last_page': lastPage,
  };

  // ============ SNAKE_CASE GETTERS ============
  int? get per_page => perPage;
  int? get current_page => currentPage;
  int? get last_page => lastPage;
  
  // ============ HELPER METHODS ============
  
  bool get hasMorePages => (currentPage ?? 1) < (lastPage ?? 1);
  
  int get totalPages => lastPage ?? 1;
  
  int get nextPage => hasMorePages ? (currentPage ?? 1) + 1 : (currentPage ?? 1);
}