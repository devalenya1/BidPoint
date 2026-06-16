// data_model/review_response.dart
import 'package:json_annotation/json_annotation.dart';

// part 'review_response.g.dart';

@JsonSerializable()
class ReviewResponse {
  bool? success;
  List<Review>? reviews;

  ReviewResponse({
    this.success,
    this.reviews,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == null && json['reviews'] != null) {
      return ReviewResponse(
        success: true,
        reviews: (json['reviews'] as List)
            .map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    }
    return _$ReviewResponseFromJson(json);
  }
  
  Map<String, dynamic> toJson() => _$ReviewResponseToJson(this);
}

@JsonSerializable()
class Review {
  int? id;
  int? userId;
  String? userName;
  int? rating;
  String? comment;
  String? createdAt;

  Review({
    this.id,
    this.userId,
    this.userName,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      rating: json['rating'] is int ? json['rating'] : (json['rating'] as double?)?.toInt(),
      comment: json['comment'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }
  
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}