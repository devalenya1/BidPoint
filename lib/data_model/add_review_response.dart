// // data_model/add_review_response.dart
// import 'dart:convert';

// AddReviewResponse addReviewResponseFromJson(String str) => AddReviewResponse.fromJson(json.decode(str));

// String addReviewResponseToJson(AddReviewResponse data) => json.encode(data.toJson());

// class AddReviewResponse {
//   bool? success;
//   String? message;

//   AddReviewResponse({
//     this.success,
//     this.message,
//   });

//   factory AddReviewResponse.fromJson(Map<String, dynamic> json) {
//     return AddReviewResponse(
//       success: json['success'],
//       message: json['message'],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'success': success,
//     'message': message,
//   };
// }