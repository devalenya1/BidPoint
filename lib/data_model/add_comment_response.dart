// data_model/add_comment_response.dart
import 'dart:convert';
import 'poll_data_response.dart'; // Use Comment from here

AddCommentResponse addCommentResponseFromJson(String str) => AddCommentResponse.fromJson(json.decode(str));

String addCommentResponseToJson(AddCommentResponse data) => json.encode(data.toJson());

class AddCommentResponse {
  bool? success;
  String? message;
  Comment? comment;

  AddCommentResponse({
    this.success,
    this.message,
    this.comment,
  });

  factory AddCommentResponse.fromJson(Map<String, dynamic> json) {
    return AddCommentResponse(
      success: json['success'],
      message: json['message'],
      comment: json['data'] != null ? Comment.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'comment': comment?.toJson(),
  };
}