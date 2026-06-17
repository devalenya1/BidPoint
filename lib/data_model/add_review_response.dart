// data_model/add_review_response.dart
import 'dart:convert';

class AddReviewResponse {
  bool? success;
  String? message;

  AddReviewResponse({
    this.success,
    this.message,
  });

  factory AddReviewResponse.fromJson(Map<String, dynamic> json) {
    return AddReviewResponse(
      success: json['success'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
  };
}