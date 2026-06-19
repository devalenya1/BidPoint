// // data_model/bid_response.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:active_ecommerce_flutter/helpers/system_config.dart';

// BidResponse bidResponseFromJson(String str) => BidResponse.fromJson(json.decode(str));

// String bidResponseToJson(BidResponse data) => json.encode(data.toJson());

// class BidResponse {
//   bool? success;
//   bool? result;
//   String? message;
//   dynamic bid;
//   int? points_deducted;
//   double? remaining_balance;
//   double? next_min_bid;
//   double? current_highest;
//   bool? time_extended;
//   int? extended_by;
//   String? new_end_date;

//   BidResponse({
//     this.success,
//     this.result,
//     this.message,
//     this.bid,
//     this.points_deducted,
//     this.remaining_balance,
//     this.next_min_bid,
//     this.current_highest,
//     this.time_extended,
//     this.extended_by,
//     this.new_end_date,
//   });

//   factory BidResponse.fromJson(Map<String, dynamic> json) {
//     final successValue = json['success'] ?? json['result'];
//     return BidResponse(
//       success: successValue is bool ? successValue : null,
//       result: json['result'],
//       message: json['message'],
//       bid: json['bid'],
//       points_deducted: json['points_deducted'],
//       remaining_balance: json['remaining_balance']?.toDouble(),
//       next_min_bid: json['next_min_bid']?.toDouble(),
//       current_highest: json['current_highest']?.toDouble(),
//       time_extended: json['time_extended'],
//       extended_by: json['extended_by'],
//       new_end_date: json['new_end_date'],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'success': success,
//     'result': result,
//     'message': message,
//     'bid': bid,
//     'points_deducted': points_deducted,
//     'remaining_balance': remaining_balance,
//     'next_min_bid': next_min_bid,
//     'current_highest': current_highest,
//     'time_extended': time_extended,
//     'extended_by': extended_by,
//     'new_end_date': new_end_date,
//   };
// }