import 'dart:convert';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/data_model/category.dart';
import 'package:active_ecommerce_flutter/data_model/product_details_response.dart';
import 'package:active_ecommerce_flutter/data_model/product_mini_response.dart';
import 'package:active_ecommerce_flutter/data_model/variant_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/repositories/api-request.dart';
import '../data_model/variant_price_response.dart';
import '../data_model/auction_models.dart';
import '../helpers/main_helpers.dart';
import 'package:active_ecommerce_flutter/middlewares/banned_user.dart';
import 'package:flutter/material.dart';

// Helper class to handle localization without context
class LocalizedMessages {
  // Default messages (English fallback)
  static const Map<String, String> _defaultMessages = {
    'failed_to_load_product_details': 'Failed to load product details',
    'failed_to_load_products': 'Failed to load products',
    'failed_to_load_wishlist': 'Failed to load wishlist',
    'failed_to_load_activities': 'Failed to load activities',
    'failed_to_load_comments': 'Failed to load comments',
    'failed_to_load_reviews': 'Failed to load reviews',
    'failed_to_load_bid_history': 'Failed to load bid history',
    'failed_to_add_to_wishlist': 'Failed to add to wishlist',
    'failed_to_remove_from_wishlist': 'Failed to remove from wishlist',
    'wishlist_update_failed': 'Wishlist update failed',
    'bid_placed_successfully': 'Bid placed successfully',
    'bid_placed_successfully_with_amount': 'Bid placed! Amount: {amount}',
    'bid_placed': 'Bid placed!',
    'failed_to_place_bid': 'Failed to place bid',
    'auction_time_extended': '⏰ Auction time extended!',
    'comment_added_successfully': 'Comment added successfully',
    'failed_to_add_comment': 'Failed to add comment',
    'review_submitted_successfully': 'Review submitted successfully',
    'failed_to_submit_review': 'Failed to submit review',
    'notify_me_success': 'You will be notified when this auction starts',
    'notify_me_failed': 'Failed to set notification',
    'message_sent_to_seller': 'Message sent to seller!',
    'failed_to_contact_seller': 'Failed to contact seller',
    'network_error': 'Network error. Please try again.',
    'something_went_wrong': 'Something went wrong',
    'remove_from_wishlist_success': 'Removed from wishlist successfully!',
    'add_to_wishlist_success': 'Added to wishlist successfully!',
  };

  static String getMessage(String key, [Map<String, String>? params]) {
    // Try to get from default messages, fallback to key
    String message = _defaultMessages[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((key, value) {
        message = message.replaceAll('{$key}', value);
      });
    }
    
    return message;
  }
}

class ProductRepository {
  Future<CatResponse> getCategoryRes() async {
    String url = ("${AppConfig.BASE_URL}/seller/products/categories");

    var reqHeader = {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    };

    final response = await ApiRequest.get(url: url, headers: reqHeader);

    return catResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFeaturedProducts({page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/featured?page=${page}");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    print(response.body);
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getBestSellingProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/best-seller");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Currency-Code": SystemConfig.systemCurrency!.code!,
      "Currency-Exchange-Rate":
          SystemConfig.systemCurrency!.exchangeRate.toString(),
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getInHouseProducts({page}) async {
    String url = ("${AppConfig.BASE_URL}/products/inhouse?page=$page");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getTodaysDealProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/todays-deal");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFlashDealProducts(id) async {
    String url = ("${AppConfig.BASE_URL}/flash-deal-products/$id");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getCategoryProducts(
      {String? id = "", name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/category/" +
        id.toString() +
        "?page=${page}&name=${name}");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getShopProducts(
      {int? id = 0, name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/seller/" +
        id.toString() +
        "?page=${page}&name=${name}");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getBrandProducts(
      {required String slug, name = "", page = 1}) async {
    String url =
        ("${AppConfig.BASE_URL}/products/brand/$slug?page=${page}&name=${name}");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getDigitalProducts({
    page = 1,
  }) async {
    String url = ("${AppConfig.BASE_URL}/products/digital?page=$page");
    print(url.toString());

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductDetailsResponse> getProductDetails({String? slug = ""}) async {
    String url = ("${AppConfig.BASE_URL}/products/details/" + slug.toString());
    print("Product Url: $url");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
    });
    print(response.body);

    return productDetailsResponseFromJson(response.body);
  }

  Future<ProductDetailsResponse> getDigitalProductDetails({int id = 0}) async {
    String url = ("${AppConfig.BASE_URL}/products/" + id.toString());
    print(url.toString());
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productDetailsResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getRelatedProducts({required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/related/$slug");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts(
      {required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/top-from-seller/$slug");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<VariantResponse> getVariantWiseInfo(
      {required String slug, color = '', variants = '', qty = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/variant/price");

    var postBody = jsonEncode(
        {'slug': slug, "color": color, "variants": variants, "quantity": qty});

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: postBody);

    return variantResponseFromJson(response.body);
  }

  Future<VariantPriceResponse> getVariantPrice({id, quantity}) async {
    String url = ("${AppConfig.BASE_URL}/varient-price");

    var post_body = jsonEncode({"id": id, "quantity": quantity});
    print(url.toString());
    print(post_body.toString());
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: post_body);

    return variantPriceResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFilteredProducts(
      {name = "",
      sort_key = "",
      page = 1,
      brands = "",
      categories = "",
      min = "",
      max = ""}) async {
    String url = ("${AppConfig.BASE_URL}/products/search" +
        "?page=$page&name=${name}&sort_key=${sort_key}&brands=${brands}&categories=${categories}&min=${min}&max=${max}");

    print(url.toString());
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  // ============ AUCTION METHODS ============
  
  Future<ProductMiniResponse> getHotAuctions({int page = 1}) async {
    String url = "${AppConfig.BASE_URL}/products/hot-auctions?page=${page}";
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getEndingSoonProducts({int page = 1}) async {
    String url = "${AppConfig.BASE_URL}/products/ending-soon?page=${page}";
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return productMiniResponseFromJson(response.body);
  }


  Future<ProductMiniResponse> getEndingSoonProducts({int page = 1}) async {
    String url = "${AppConfig.BASE_URL}/products/ended?page=${page}";
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getUpcomingProducts({int page = 1}) async {
    String url = "${AppConfig.BASE_URL}/products/upcoming?page=${page}";
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return productMiniResponseFromJson(response.body);
  }

  // ============ AUCTION BIDDING METHODS ============
  
  Future<PollDataResponse> pollProductData(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/product-poll/$productId");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
        "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
      },
    );
    return pollDataResponseFromJson(response.body);
  }

  Future<BidResponse> placeBid(String productId, String amount, {String type = "custom"}) async {
    String url = ("${AppConfig.BASE_URL}/auction_product_bids/store");
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
    return bidResponseFromJson(response.body);
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
    return bidResponseFromJson(response.body);
  }

  // ============ COMMENTS ============
  
  Future<CommentResponse> getProductComments(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/comments/$productId");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return commentResponseFromJson(response.body);
  }

  Future<AddCommentResponse> addProductComment(int productId, String comment) async {
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
    return addCommentResponseFromJson(response.body);
  }

  Future<Map<String, dynamic>> likeProductComment(int commentId) async {
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

  // ============ REVIEWS ============
  
  Future<ReviewResponse> getProductReviews(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/reviews/$productId");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return reviewResponseFromJson(response.body);
  }

  Future<AddReviewResponse> addProductReview(int productId, int rating, String comment) async {
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
    return addReviewResponseFromJson(response.body);
  }

  // ============ BID HISTORY ============
  
  Future<BidHistoryResponse> getProductBidHistory(int productId) async {
    String url = ("${AppConfig.BASE_URL}/auction/bid-history/$productId");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return bidHistoryResponseFromJson(response.body);
  }

  // ============ WISHLIST ============
  
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
    return wishlistResponseFromJson(response.body);
  }

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
    return wishlistResponseFromJson(response.body);
  }


  // ============ WISHLIST STATUS ============
  Future<Map<String, dynamic>> getWishlistStatus(int productId) async {
    String url = "${AppConfig.BASE_URL}/wishlist/status/$productId";
    
    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'isInWishlist': data['is_in_wishlist'] ?? false,
          'message': data['message'] ?? '',
        };
      } else {
        return {
          'success': false,
          'isInWishlist': false,
          'message': LocalizedMessages.getMessage('failed_to_load_wishlist'),
        };
      }
    } catch (e) {
      print('Error getting wishlist status: $e');
      return {
        'success': false,
        'isInWishlist': false,
        'message': LocalizedMessages.getMessage('network_error'),
      };
    }
  }

  // Get wishlist status for multiple products (for batch checking)
  Future<Map<String, bool>> getWishlistStatusBatch(List<int> productIds) async {
    String url = "${AppConfig.BASE_URL}/wishlist/status-batch";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Authorization": is_logged_in.$ ? "Bearer ${access_token.$}" : "",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "product_ids": productIds,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, bool>.from(data['data']);
        }
      }
      return {};
    } catch (e) {
      print('Error getting batch wishlist status: $e');
      return {};
    }
  }

  Future<WishlistResponse> toggleWishlist(int productId) async {
    String url = "${AppConfig.BASE_URL}/wishlist/toggle";
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
    return wishlistResponseFromJson(response.body);
  }

  // ============ NOTIFY ME ============
  
  Future<Map<String, dynamic>> notifyMeForAuction(int productId) async {
    String url = "${AppConfig.BASE_URL}/auction/notify-me";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "product_id": productId,
        })
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? LocalizedMessages.getMessage('notify_me_success'),
          'status': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('notify_me_failed'),
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error in notifyMeForAuction: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error'),
        'status': 500,
      };
    }
  }

  // Contact seller
  Future<Map<String, dynamic>> contactSeller(int productId) async {
    String url = "${AppConfig.BASE_URL}/product/contact-store";
    
    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: jsonEncode({
          "product_id": productId,
        })
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? LocalizedMessages.getMessage('message_sent_to_seller'),
          'status': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': LocalizedMessages.getMessage('failed_to_contact_seller'),
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error in contactSeller: $e");
      return {
        'success': false,
        'message': LocalizedMessages.getMessage('network_error'),
        'status': 500,
      };
    }
  }
}