// data_model/comment_response.dart
import 'dart:convert';

CommentResponse commentResponseFromJson(String str) => CommentResponse.fromJson(json.decode(str));

String commentResponseToJson(CommentResponse data) => json.encode(data.toJson());

class CommentResponse {
  bool? success;
  List<Comment>? comments;
  int? status;

  CommentResponse({
    this.success,
    this.comments,
    this.status,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    // Handle both formats: with 'data' wrapper or without
    List<Comment> commentList = [];
    
    // Check if data is directly in 'data' field
    if (json['data'] != null && json['data'] is List) {
      commentList = (json['data'] as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    } 
    // Check if comments are in 'comments' field
    else if (json['comments'] != null && json['comments'] is List) {
      commentList = (json['comments'] as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    // Check if the entire response is a list
    else if (json is List) {
      commentList = json
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return CommentResponse(
      success: json['success'] ?? true,
      comments: commentList,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': comments?.map((c) => c.toJson()).toList(),
  };

  // ============ HELPER METHODS ============
  
  bool get hasComments => (comments?.length ?? 0) > 0;
  
  int get commentCount => comments?.length ?? 0;
  
  List<Comment> get allComments => comments ?? [];
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
    // Handle likes - could be string or int
    int? likesValue;
    if (json['likes'] != null) {
      if (json['likes'] is int) {
        likesValue = json['likes'];
      } else if (json['likes'] is String) {
        likesValue = int.tryParse(json['likes']) ?? 0;
      }
    }

    return Comment(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      userAvatar: json['userAvatar'] ?? json['user_avatar'] ?? json['avatar'],
      comment: json['comment'],
      likes: likesValue,
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'user_avatar': userAvatar,
    'comment': comment,
    'likes': likes,
    'created_at': createdAt,
  };

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  int? get user_id => userId;
  String? get user_name => userName;
  String? get user_avatar => userAvatar;
  String? get created_at => createdAt;
  
  // ============ HELPER METHODS ============
  
  int get likesCount => likes ?? 0;
  
  String get displayName => userName ?? 'Unknown User';
  
  String get avatarUrl => userAvatar ?? '';
  
  bool get hasAvatar => userAvatar != null && userAvatar!.isNotEmpty;
  
  String get formattedCreatedAt {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt!);
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
    } catch (e) {
      return createdAt ?? '';
    }
  }
  
  String get timeAgo {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt!);
      final difference = DateTime.now().difference(date);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return createdAt ?? '';
    }
  }
}