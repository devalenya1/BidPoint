// data_model/add_comment_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'comment_response.dart';

part 'add_comment_response.g.dart';

@JsonSerializable()
class AddCommentResponse {
  bool? success;
  Comment? comment;

  AddCommentResponse({this.success, this.comment});

  factory AddCommentResponse.fromJson(Map<String, dynamic> json) =>
      _$AddCommentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AddCommentResponseToJson(this);
}