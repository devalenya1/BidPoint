// repositories/auction_products_repository.dart
import 'dart:convert';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/data_model/add_comment_response.dart';
import 'package:active_ecommerce_flutter/data_model/add_review_response.dart';
import 'package:active_ecommerce_flutter/data_model/auction_product_details_response.dart';
import 'package:active_ecommerce_flutter/data_model/bid_history_response.dart';
import 'package:active_ecommerce_flutter/data_model/bid_response.dart';
import 'package:active_ecommerce_flutter/data_model/comment_response.dart';
import 'package:active_ecommerce_flutter/data_model/poll_data_response.dart';
import 'package:active_ecommerce_flutter/data_model/review_response.dart';
import 'package:active_ecommerce_flutter/data_model/wishlist_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/repositories/api-request.dart';

class AuctionProductsRepository {
  
  // Get auction product details
  Future<AuctionProductDetailsResponse> getAuctionProductsDetails(String slug) async {
    String url = ("${AppConfig.BASE_URL}/auction-product/$slug");
    
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
      },
    );
    
    return auctionProductDetailsResponseFromJson(response.body);
  }
  
  // Place a bid
  Future<BidResponse> placeBidResponse(String productId, String amount) async {
    String url = ("${AppConfig.BASE_URL}/auction_product_bids/store");
    
    var postBody = jsonEncode({
      "product_id": int.parse(productId),
      "amount": double.parse(amount),
      "type": "custom"
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return BidResponse.fromJson(jsonDecode(response.body));
  }
  
  // Quick bid for swipe functionality
  Future<BidResponse> quickBid(String productId, String amount, {String type = "quick"}) async {
    String url = ("${AppConfig.BASE_URL}/auction/quick-bid");
    
    var postBody = jsonEncode({
      "product_id": int.parse(productId),
      "amount": double.parse(amount),
      "type": type
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return BidResponse.fromJson(jsonDecode(response.body));
  }
  
  // Poll data for real-time updates
  Future<PollDataResponse> pollData(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/product-poll/$productId");
    
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
      },
    );
    
    return PollDataResponse.fromJson(jsonDecode(response.body));
  }
  
  // Get comments
  Future<CommentResponse> getComments(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/comments/$productId");
    
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    
    // Handle both formats: direct list or wrapped in 'comments' key
    if (decoded.containsKey('comments') && decoded['comments'] is List) {
      return CommentResponse(
        success: true,
        comments: (decoded['comments'] as List)
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    } else if (decoded is List) {
      return CommentResponse(
        success: true,
        comments: (decoded as List)
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }
    
    return CommentResponse(success: false, comments: []);
  }
  
  // Get reviews
  Future<ReviewResponse> getReviews(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/reviews/$productId");
    
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    
    if (decoded.containsKey('reviews') && decoded['reviews'] is List) {
      return ReviewResponse(
        success: true,
        reviews: (decoded['reviews'] as List)
            .map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    } else if (decoded is List) {
      return ReviewResponse(
        success: true,
        reviews: (decoded as List)
            .map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    }
    
    return ReviewResponse(success: false, reviews: []);
  }
  
  // Get bid history
  Future<BidHistoryResponse> getBidHistory(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/bid-history/$productId");
    
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    
    if (decoded.containsKey('bids') && decoded['bids'] is List) {
      return BidHistoryResponse(
        success: true,
        bids: (decoded['bids'] as List)
            .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
    } else if (decoded is List) {
      return BidHistoryResponse(
        success: true,
        bids: (decoded as List)
            .map((b) => BidHistory.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
    }
    
    return BidHistoryResponse(success: false, bids: []);
  }
  
  // Add comment
  Future<AddCommentResponse> addComment(int productId, String comment) async {
    String url = ("${AppConfig.BASE_URL}/auction/add-comment");
    
    var postBody = jsonEncode({
      "product_id": productId,
      "comment": comment,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return AddCommentResponse.fromJson(jsonDecode(response.body));
  }
  
  // Add review
  Future<AddReviewResponse> addReview(int productId, int rating, String comment) async {
    String url = ("${AppConfig.BASE_URL}/auction/add-review");
    
    var postBody = jsonEncode({
      "product_id": productId,
      "rating": rating,
      "comment": comment,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return AddReviewResponse.fromJson(jsonDecode(response.body));
  }
  
  // Like comment
  Future<Map<String, dynamic>> likeComment(int commentId) async {
    String url = ("${AppConfig.BASE_URL}/auction/like-comment");
    
    var postBody = jsonEncode({
      "comment_id": commentId,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return jsonDecode(response.body);
  }
  
  // Add to wishlist
  Future<WishlistResponse> addToWishlist(int productId) async {
    String url = ("${AppConfig.BASE_URL}/wishlist/add");
    
    var postBody = jsonEncode({
      "product_id": productId,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return WishlistResponse.fromJson(jsonDecode(response.body));
  }
  
  // Remove from wishlist
  Future<WishlistResponse> removeFromWishlist(int productId) async {
    String url = ("${AppConfig.BASE_URL}/wishlist/remove");
    
    var postBody = jsonEncode({
      "product_id": productId,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return WishlistResponse.fromJson(jsonDecode(response.body));
  }
  
  // Contact seller
  Future<Map<String, dynamic>> contactSeller(int productId) async {
    String url = ("${AppConfig.BASE_URL}/product/contact-store");
    
    var postBody = jsonEncode({
      "id": productId,
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return jsonDecode(response.body);
  }


  Future<BidResponse> quickBid(String productId, String amount, {String type = "quick"}) async {
    String url = ("${AppConfig.BASE_URL}/auction/quick-bid");
    
    var postBody = jsonEncode({
      "product_id": int.parse(productId),
      "amount": double.parse(amount),
      "type": type
    });
    
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: postBody,
    );
    
    return BidResponse.fromJson(jsonDecode(response.body));
  }

}