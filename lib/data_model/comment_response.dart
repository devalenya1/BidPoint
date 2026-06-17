// data_model/comment_response.dart
import 'dart:convert';

class CommentResponse {
  bool? success;
  List<Comment>? comments;

  CommentResponse({
    this.success,
    this.comments,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == null && json['comments'] != null) {
      return CommentResponse(
        success: true,
        comments: (json['comments'] as List)
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }
    return CommentResponse(
      success: json['success'],
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'comments': comments?.map((c) => c.toJson()).toList(),
  };
}

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

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      userAvatar: json['userAvatar'] ?? json['user_avatar'] ?? json['avatar'],
      comment: json['comment'],
      likes: json['likes'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'comment': comment,
    'likes': likes,
    'createdAt': createdAt,
  };
}