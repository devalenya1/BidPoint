// data_model/comment_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'comment_response.g.dart';

@JsonSerializable()
class CommentResponse {
  bool? success;
  List<Comment>? comments;

  CommentResponse({this.success, this.comments});

  factory CommentResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CommentResponseToJson(this);
}

@JsonSerializable()
class Comment {
  int? id;
  int? user_id;
  String? user_name;
  String? user_avatar;
  String? comment;
  int? likes;
  String? created_at;

  Comment({
    this.id,
    this.user_id,
    this.user_name,
    this.user_avatar,
    this.comment,
    this.likes,
    this.created_at,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}