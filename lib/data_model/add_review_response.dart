// data_model/add_review_response.dart
import 'package:json_annotation/json_annotation.dart';

// part 'add_review_response.g.dart';

@JsonSerializable()
class AddReviewResponse {
  bool? success;
  String? message;

  AddReviewResponse({
    this.success,
    this.message,
  });

  factory AddReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$AddReviewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AddReviewResponseToJson(this);
}