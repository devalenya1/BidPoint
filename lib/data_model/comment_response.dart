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
  int? userId;
  String? userName;
  String? userAvatar;
  String? comment;
  int? likes;
  String? createdAt;

  Comment({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.comment,
    this.likes,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}