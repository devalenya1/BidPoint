// data_model/add_comment_response.dart
import 'dart:convert';
import 'comment_response.dart';

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
      comment: json['comment'] != null ? Comment.fromJson(json['comment']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'comment': comment?.toJson(),
  };
}