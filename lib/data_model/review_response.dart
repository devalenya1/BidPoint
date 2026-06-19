// // data_model/review_response.dart
// import 'dart:convert';
// import 'poll_data_response.dart'; // Use Review from here

// ReviewResponse reviewResponseFromJson(String str) => ReviewResponse.fromJson(json.decode(str));

// String reviewResponseToJson(ReviewResponse data) => json.encode(data.toJson());

// class ReviewResponse {
//   bool? success;
//   List<Review>? reviews; // Uses Review from poll_data_response.dart

//   ReviewResponse({
//     this.success,
//     this.reviews,
//   });

//   factory ReviewResponse.fromJson(Map<String, dynamic> json) {
//     if (json['success'] == null && json['reviews'] != null) {
//       return ReviewResponse(
//         success: true,
//         reviews: (json['reviews'] as List)
//             .map((r) => Review.fromJson(r as Map<String, dynamic>))
//             .toList(),
//       );
//     }
//     return ReviewResponse(
//       success: json['success'],
//       reviews: json['reviews'] != null
//           ? (json['reviews'] as List)
//               .map((r) => Review.fromJson(r as Map<String, dynamic>))
//               .toList()
//           : [],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'success': success,
//     'reviews': reviews?.map((r) => r.toJson()).toList(),
//   };
// }