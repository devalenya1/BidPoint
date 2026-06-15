// data_model/review_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'review_response.g.dart';

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
  int? user_id;
  String? user_name;
  int? rating;
  String? comment;
  String? created_at;

  Review({
    this.id,
    this.user_id,
    this.user_name,
    this.rating,
    this.comment,
    this.created_at,
  });

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}