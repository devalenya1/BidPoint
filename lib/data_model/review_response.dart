// data_model/review_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'review_response.dart';

@JsonSerializable()
class ReviewResponse {
  bool? success;
  List<Review>? reviews;

  ReviewResponse({this.success, this.reviews});

  factory ReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewResponseFromJson(json);
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

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}