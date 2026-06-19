// // data_model/comment_response.dart
// import 'dart:convert';
// import 'poll_data_response.dart'; // Use Comment from here

// CommentResponse commentResponseFromJson(String str) => CommentResponse.fromJson(json.decode(str));

// String commentResponseToJson(CommentResponse data) => json.encode(data.toJson());

// class CommentResponse {
//   bool? success;
//   List<Comment>? comments; // Uses Comment from poll_data_response.dart
//   int? status;

//   CommentResponse({
//     this.success,
//     this.comments,
//     this.status,
//   });

//   factory CommentResponse.fromJson(Map<String, dynamic> json) {
//     List<Comment> commentList = [];
    
//     if (json['data'] != null && json['data'] is List) {
//       commentList = (json['data'] as List)
//           .map((c) => Comment.fromJson(c as Map<String, dynamic>))
//           .toList();
//     } else if (json['comments'] != null && json['comments'] is List) {
//       commentList = (json['comments'] as List)
//           .map((c) => Comment.fromJson(c as Map<String, dynamic>))
//           .toList();
//     } else if (json is List) {
//       commentList = (json as List)
//           .map((c) => Comment.fromJson(c as Map<String, dynamic>))
//           .toList();
//     }

//     return CommentResponse(
//       success: json['success'] ?? true,
//       comments: commentList,
//       status: json['status'],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'success': success,
//     'data': comments?.map((c) => c.toJson()).toList(),
//   };

//   bool get hasComments => (comments?.length ?? 0) > 0;
//   int get commentCount => comments?.length ?? 0;
//   List<Comment> get allComments => comments ?? [];
// }