// To parse this JSON data, do
//
//     final productMiniResponse = productMiniResponseFromJson(jsonString);
// https://app.quicktype.io/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';

ProductMiniResponse productMiniResponseFromJson(String str) =>
    ProductMiniResponse.fromJson(json.decode(str));

String productMiniResponseToJson(ProductMiniResponse data) =>
    json.encode(data.toJson());

class ProductMiniResponse {
  ProductMiniResponse({
    this.products,
    this.meta,
    this.success,
    this.status,
  });

  List<Product>? products;
  bool? success;
  int? status;
  Meta? meta;

  factory ProductMiniResponse.fromJson(Map<String, dynamic> json) =>
      ProductMiniResponse(
        products: json["data"] != null
            ? List<Product>.from(json["data"].map((x) => Product.fromJson(x)))
            : [],
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": products != null
            ? List<dynamic>.from(products!.map((x) => x.toJson()))
            : [],
        "meta": meta?.toJson(),
        "success": success,
        "status": status,
      };
}

class Product {
  Product({
    this.id,
    this.slug,
    this.name,
    this.description,
    this.thumbnailImage,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount,
    this.discount,
    this.rating,
    this.reviewCount,
    this.sales,
    this.isWholesale,
    // Auction related fields
    this.auctionEndDate,
    this.auctionStartDate,
    this.startingBid,
    this.minBidPrice,
    this.highestBid,
    // Swipe and points fields
    this.swipeRight,
    this.swipeLeft,
    this.pointPerBid,
    this.pointPerBidCustom,
    this.pointMultiplierSystem,
    this.auctionProduct,
    this.links,
  });

  int? id;
  String? slug;
  String? name;
  String? description;
  String? thumbnailImage;
  String? mainPrice;
  String? strokedPrice;
  bool? hasDiscount;
  var discount;
  double? rating;
  int? reviewCount;
  int? sales;
  bool? isWholesale;
  
  // Auction related fields
  dynamic auctionEndDate; // Can be "Ended" (String) or timestamp (int)
  dynamic auctionStartDate; // Can be "Upcoming" (String) or timestamp (int)
  String? startingBid;     // Now returns plain string like "10.00"
  String? minBidPrice;     // Now returns plain string like "11.24"
  String? highestBid;      // Now returns plain string like "10.24"
  
  // Swipe and points fields
  int? swipeRight;
  int? swipeLeft;
  int? pointPerBid;
  int? pointPerBidCustom;
  int? pointMultiplierSystem;
  int? auctionProduct;
  
  Links? links;

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  String? get thumbnail_image => thumbnailImage;
  String? get main_price => mainPrice;
  String? get stroked_price => strokedPrice;
  bool? get has_discount => hasDiscount;
  // ============ END SNAKE_CASE GETTERS ============

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        slug: json["slug"],
        name: json["name"],
        description: json["description"],
        thumbnailImage: json["thumbnail_image"],
        mainPrice: json["main_price"],
        strokedPrice: json["stroked_price"],
        hasDiscount: json["has_discount"],
        discount: json["discount"],
        rating: json["rating"]?.toDouble(),
        reviewCount: json["review_count"],
        sales: json["sales"],
        isWholesale: json["is_wholesale"],
        // Auction related fields
        auctionEndDate: json["auction_end_date"],
        auctionStartDate: json["auction_start_date"],
        startingBid: json["starting_bid"],
        minBidPrice: json["min_bid_price"],
        highestBid: json["highest_bid"],
        // Swipe and points fields
        swipeRight: json["swipe_right"],
        swipeLeft: json["swipe_left"],
        pointPerBid: json["point_per_bid"],
        pointPerBidCustom: json["point_per_bid_custom"],
        pointMultiplierSystem: json["point_multiplier_system"],
        auctionProduct: json["auction_product"],
        links: json["links"] == null ? null : Links.fromJson(json["links"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "description": description,
        "thumbnail_image": thumbnailImage,
        "main_price": mainPrice,
        "stroked_price": strokedPrice,
        "has_discount": hasDiscount,
        "discount": discount,
        "rating": rating,
        "review_count": reviewCount,
        "sales": sales,
        "is_wholesale": isWholesale,
        "auction_end_date": auctionEndDate,
        "auction_start_date": auctionStartDate,
        "starting_bid": startingBid,
        "min_bid_price": minBidPrice,
        "highest_bid": highestBid,
        "swipe_right": swipeRight,
        "swipe_left": swipeLeft,
        "point_per_bid": pointPerBid,
        "point_per_bid_custom": pointPerBidCustom,
        "point_multiplier_system": pointMultiplierSystem,
        "auction_product": auctionProduct,
        "links": links?.toJson(),
      };

  // ============ HELPER METHODS FOR SAFE DATA ACCESS ============
  
  bool get isAuctionProduct => (auctionProduct ?? 0) == 1;
  
  bool get isAuctionEnded {
    if (!isAuctionProduct) return false;
    return auctionEndDate is String && auctionEndDate == 'Ended';
  }
  
  bool get isAuctionActive {
    if (!isAuctionProduct) return false;
    // Check if auctionEndDate is a valid timestamp
    if (auctionEndDate is int) {
      final endTimestamp = auctionEndDate as int;
      // If endTimestamp is 0 or negative, auction has ended
      if (endTimestamp <= 0) return false;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return endTimestamp > now && !isAuctionEnded;
    }
    return false;
  }
  
  // bool get isAuctionUpcoming {
  //   if (!isAuctionProduct) return false;
  //   if (auctionStartDate is String && auctionStartDate == 'Upcoming') return true;
  //   if (auctionStartDate is int) {
  //     final startTimestamp = auctionStartDate as int;
  //     if (startTimestamp <= 0) return false;
  //     final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  //     return startTimestamp > now;
  //   }
  //   return false;
  // }


  bool get isAuctionUpcoming {
    if (auctionStartDate == null) return false;
    
    // If it's a string 'Upcoming' from server
    if (auctionStartDate is String && auctionStartDate == 'Upcoming') {
      return true;
    }
    
    // If it's a timestamp, check if it's in the future
    if (auctionStartDate is int) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return auctionStartDate > now;
    }
    
    // If it's a string that can be parsed as int
    if (auctionStartDate is String) {
      final timestamp = int.tryParse(auctionStartDate);
      if (timestamp != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return timestamp > now;
      }
    }
    
    return false;
  }   
  
  String getAuctionStatus() {
    if (!isAuctionProduct) return 'Regular Product';
    if (isAuctionUpcoming) return 'Upcoming';
    if (isAuctionActive) return 'Live';
    if (isAuctionEnded) return 'Ended';
    return 'Unknown';
  }
  
  Color getAuctionStatusColor() {
    if (!isAuctionProduct) return Colors.grey;
    if (isAuctionUpcoming) return Colors.orange;
    if (isAuctionActive) return Colors.green;
    if (isAuctionEnded) return Colors.red;
    return Colors.grey;
  }
  
  // ============ PRICE HELPERS (NOW HANDLE PLAIN STRINGS) ============
  
  /// Parse a price string to double (handles both "10.24" and "$10.24")
  double parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // Remove any currency symbols or non-numeric characters except dot
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Format price with currency symbol
  String formatPrice(dynamic price) {
    final doubleValue = parsePrice(price);
    final symbol = SystemConfig.systemCurrency?.symbol ?? '\$';
    return '$symbol${doubleValue.toStringAsFixed(2)}';
  }
  
  String getDisplayPrice() {
    if (isAuctionProduct) {
      if (highestBid != null && highestBid!.isNotEmpty && parsePrice(highestBid) > 0) {
        return formatPrice(highestBid);
      }
      return formatPrice(startingBid);
    }
    return formatPrice(mainPrice);
  }
  
  String getOriginalPrice() {
    if (isAuctionProduct) {
      return formatPrice(startingBid);
    }
    return formatPrice(strokedPrice);
  }
  
  String getDiscountText() {
    if (hasDiscount == true && discount != null && discount.toString().isNotEmpty) {
      return discount.toString();
    }
    return '';
  }
  
  bool get hasDiscountValue => hasDiscount == true && discount != null && discount != '-0%';
  
  String getHighestBidText() {
    if (isAuctionProduct && highestBid != null && highestBid!.isNotEmpty) {
      return formatPrice(highestBid);
    }
    return 'No bids yet';
  }
  
  String getMinBidText() {
    if (isAuctionProduct && minBidPrice != null && minBidPrice!.isNotEmpty) {
      return formatPrice(minBidPrice);
    }
    return formatPrice(startingBid);
  }
  
  double getHighestBidValue() {
    if (isAuctionProduct && highestBid != null && highestBid!.isNotEmpty) {
      return parsePrice(highestBid);
    }
    return 0.0;
  }
  
  double getStartingBidValue() {
    if (isAuctionProduct && startingBid != null && startingBid!.isNotEmpty) {
      return parsePrice(startingBid);
    }
    return 0.0;
  }
  
  double getMinBidValue() {
    if (isAuctionProduct && minBidPrice != null && minBidPrice!.isNotEmpty) {
      return parsePrice(minBidPrice);
    }
    return 0.0;
  }
  
  bool get hasHighestBid => highestBid != null && highestBid!.isNotEmpty && parsePrice(highestBid) > 0;
  
  int get totalSwipes => (swipeRight ?? 0) + (swipeLeft ?? 0);
  
  double get averageRating => rating ?? 0.0;
  
  int get totalReviews => reviewCount ?? 0;
  
  int get totalSales => sales ?? 0;
  
  int get swipeRatio {
    final total = totalSwipes;
    if (total == 0) return 0;
    return ((swipeRight ?? 0) / total * 100).round();
  }
  
  String getPointPerBidText() {
    if (pointPerBidCustom != null && pointPerBidCustom! > 0) {
      return pointPerBidCustom.toString();
    }
    return pointPerBid?.toString() ?? '0';
  }
  
  String getProductUrl() {
    return links?.details ?? '';
  }
  
  DateTime? getAuctionEndDateTime() {
    if (auctionEndDate is int) {
      final timestamp = auctionEndDate as int;
      if (timestamp > 0) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }
    return null;
  }
  
  // DateTime? getAuctionStartDateTime() {
  //   if (auctionStartDate is int) {
  //     final timestamp = auctionStartDate as int;
  //     if (timestamp > 0) {
  //       return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  //     }
  //   }
  //   return null;
  // }

  DateTime? getAuctionStartDateTime() {
    if (auctionStartDate == null) return null;
    
    // If it's a string 'Upcoming', we don't have a real date
    if (auctionStartDate is String && auctionStartDate == 'Upcoming') {
      return null;
    }
    
    int timestamp;
    if (auctionStartDate is int) {
      timestamp = auctionStartDate;
    } else if (auctionStartDate is String) {
      timestamp = int.tryParse(auctionStartDate) ?? 0;
    } else {
      return null;
    }
    
    if (timestamp <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  String getFormattedAuctionEndDate() {
    final dateTime = getAuctionEndDateTime();
    if (dateTime != null) {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
    }
    return auctionEndDate?.toString() ?? 'N/A';
  }
  
  String getFormattedAuctionStartDate() {
    final dateTime = getAuctionStartDateTime();
    if (dateTime != null) {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
    }
    return auctionStartDate?.toString() ?? 'N/A';
  }
  
  // ============ GETTERS FOR DISPLAY ============
  
  String get displayName => name ?? 'Unknown Product';
  
  String get displayImage => thumbnailImage ?? '';
  
  bool get hasImage => thumbnailImage != null && thumbnailImage!.isNotEmpty;
  
  bool get isEnded => isAuctionEnded;
  
  bool get isLive => isAuctionActive;
  
  bool get isUpcoming => isAuctionUpcoming;
  
  String get statusText => getAuctionStatus();
  
  Color get statusColor => getAuctionStatusColor();
}

class Links {
  Links({
    this.details,
  });

  String? details;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        details: json["details"],
      );

  Map<String, dynamic> toJson() => {
        "details": details,
      };
}

class Meta {
  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  int? currentPage;
  int? from;
  int? lastPage;
  String? path;
  int? perPage;
  int? to;
  int? total;

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        currentPage: json["current_page"],
        from: json["from"],
        lastPage: json["last_page"],
        path: json["path"],
        perPage: json["per_page"],
        to: json["to"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "path": path,
        "per_page": perPage,
        "to": to,
        "total": total,
      };
}