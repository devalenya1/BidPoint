// product_mini_response.dart
import 'dart:convert';
import 'package:flutter/material.dart';

ProductMiniResponse productMiniResponseFromJson(String str) =>
    ProductMiniResponse.fromJson(json.decode(str));

String productMiniResponseToJson(ProductMiniResponse data) =>
    json.encode(data.toJson());

class ProductMiniResponse {
  List<Product>? products;
  PaginationLinks? links;
  Meta? meta;
  bool? success;
  int? status;

  ProductMiniResponse({
    this.products,
    this.links,
    this.meta,
    this.success,
    this.status,
  });

  factory ProductMiniResponse.fromJson(Map<String, dynamic> json) {
    return ProductMiniResponse(
      products: json["data"] != null
          ? List<Product>.from(json["data"].map((x) => Product.fromJson(x)))
          : [],
      links: json["links"] != null ? PaginationLinks.fromJson(json["links"]) : null,
      meta: json["meta"] != null ? Meta.fromJson(json["meta"]) : null,
      success: json["success"] ?? false,
      status: json["status"] ?? 200,
    );
  }

  Map<String, dynamic> toJson() => {
        "data": products != null ? List<dynamic>.from(products!.map((x) => x.toJson())) : [],
        "links": links?.toJson(),
        "meta": meta?.toJson(),
        "success": success,
        "status": status,
      };
}

class Product {
  int? id;
  String? slug;
  String? name;
  String? thumbnailImage;
  bool? hasDiscount;
  String? discount;
  String? strokedPrice;
  String? mainPrice;
  double? rating;
  int? reviewCount;
  int? sales;
  bool? isWholesale;
  
  // Auction related fields
  dynamic auctionEndDate; // Can be "Ended" (String) or timestamp (int)
  dynamic auctionStartDate; // Can be "Upcoming" (String) or timestamp (int)
  String? startingBid;
  String? minBidPrice;
  String? highestBid; // Can be empty string or price string
  
  // Swipe and points fields
  int? swipeRight;
  int? swipeLeft;
  int? pointPerBid;
  int? pointPerBidCustom;
  int? pointMultiplierSystem;
  int? auctionProduct;
  
  Links? links;

  Product({
    this.id,
    this.slug,
    this.name,
    this.thumbnailImage,
    this.hasDiscount,
    this.discount,
    this.strokedPrice,
    this.mainPrice,
    this.rating,
    this.reviewCount,
    this.sales,
    this.isWholesale,
    this.auctionEndDate,
    this.auctionStartDate,
    this.startingBid,
    this.minBidPrice,
    this.highestBid,
    this.swipeRight,
    this.swipeLeft,
    this.pointPerBid,
    this.pointPerBidCustom,
    this.pointMultiplierSystem,
    this.auctionProduct,
    this.links,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"] as int?,
      slug: json["slug"] as String?,
      name: json["name"] as String?,
      thumbnailImage: json["thumbnail_image"] as String?,
      hasDiscount: json["has_discount"] as bool?,
      discount: json["discount"] as String?,
      strokedPrice: json["stroked_price"] as String?,
      mainPrice: json["main_price"] as String?,
      rating: (json["rating"] as num?)?.toDouble(),
      reviewCount: json["review_count"] as int?,
      sales: json["sales"] as int?,
      isWholesale: json["is_wholesale"] as bool?,
      auctionEndDate: json["auction_end_date"],
      auctionStartDate: json["auction_start_date"],
      startingBid: json["starting_bid"] as String?,
      minBidPrice: json["min_bid_price"] as String?,
      highestBid: json["highest_bid"] as String?,
      swipeRight: json["swipe_right"] as int?,
      swipeLeft: json["swipe_left"] as int?,
      pointPerBid: json["point_per_bid"] as int?,
      pointPerBidCustom: json["point_per_bid_custom"] as int?,
      pointMultiplierSystem: json["point_multiplier_system"] as int?,
      auctionProduct: json["auction_product"] as int?,
      links: json["links"] != null ? Links.fromJson(json["links"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "thumbnail_image": thumbnailImage,
        "has_discount": hasDiscount,
        "discount": discount,
        "stroked_price": strokedPrice,
        "main_price": mainPrice,
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
    if (auctionEndDate is int && auctionEndDate > 0) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return auctionEndDate > now && !isAuctionEnded;
    }
    return false;
  }
  
  bool get isAuctionUpcoming {
    if (!isAuctionProduct) return false;
    if (auctionStartDate is String && auctionStartDate == 'Upcoming') return true;
    if (auctionStartDate is int && auctionStartDate > 0) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return auctionStartDate > now;
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
  
  String getDisplayPrice() {
    if (isAuctionProduct) {
      if (highestBid != null && highestBid!.isNotEmpty) {
        return highestBid!;
      }
      return startingBid ?? '0.00';
    }
    return mainPrice ?? '0.00';
  }
  
  String getOriginalPrice() {
    if (isAuctionProduct) {
      return startingBid ?? '';
    }
    return strokedPrice ?? '';
  }
  
  String getDiscountText() {
    if (hasDiscount == true && discount != null && discount!.isNotEmpty) {
      return discount!;
    }
    return '';
  }
  
  bool get hasDiscountValue => hasDiscount == true && discount != null && discount != '-0%';
  
  String getHighestBidText() {
    if (isAuctionProduct && highestBid != null && highestBid!.isNotEmpty) {
      return highestBid!;
    }
    return 'No bids yet';
  }
  
  String getMinBidText() {
    if (isAuctionProduct && minBidPrice != null && minBidPrice!.isNotEmpty) {
      return minBidPrice!;
    }
    return startingBid ?? 'N/A';
  }
  
  bool get hasHighestBid => highestBid != null && highestBid!.isNotEmpty;
  
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
    if (auctionEndDate is int && (auctionEndDate as int) > 0) {
      return DateTime.fromMillisecondsSinceEpoch((auctionEndDate as int) * 1000);
    }
    return null;
  }
  
  DateTime? getAuctionStartDateTime() {
    if (auctionStartDate is int && (auctionStartDate as int) > 0) {
      return DateTime.fromMillisecondsSinceEpoch((auctionStartDate as int) * 1000);
    }
    return null;
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
}

class Links {
  String? details;

  Links({this.details});

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        details: json["details"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "details": details,
      };
}

class PaginationLinks {
  String? first;
  String? last;
  String? prev;
  String? next;

  PaginationLinks({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory PaginationLinks.fromJson(Map<String, dynamic> json) => PaginationLinks(
        first: json["first"] as String?,
        last: json["last"] as String?,
        prev: json["prev"] as String?,
        next: json["next"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "first": first,
        "last": last,
        "prev": prev,
        "next": next,
      };
  
  bool get hasNextPage => next != null && next!.isNotEmpty;
  
  bool get hasPreviousPage => prev != null && prev!.isNotEmpty;
}

class Meta {
  int? currentPage;
  int? from;
  int? lastPage;
  List<MetaLink>? links;
  String? path;
  int? perPage;
  int? to;
  int? total;

  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.links,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        currentPage: json["current_page"] as int?,
        from: json["from"] as int?,
        lastPage: json["last_page"] as int?,
        links: json["links"] != null
            ? List<MetaLink>.from(json["links"].map((x) => MetaLink.fromJson(x)))
            : [],
        path: json["path"] as String?,
        perPage: json["per_page"] as int?,
        to: json["to"] as int?,
        total: json["total"] as int?,
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "links": links != null ? List<dynamic>.from(links!.map((x) => x.toJson())) : [],
        "path": path,
        "per_page": perPage,
        "to": to,
        "total": total,
      };
  
  bool get hasNextPage => (currentPage ?? 0) < (lastPage ?? 0);
  
  bool get hasPreviousPage => (currentPage ?? 1) > 1;
  
  int get nextPage => (currentPage ?? 0) + 1;
  
  int get previousPage => (currentPage ?? 1) - 1;
  
  String get rangeText {
    if (from != null && to != null && total != null) {
      return 'Showing $from to $to of $total results';
    }
    return '';
  }
}

class MetaLink {
  String? url;
  String? label;
  bool? active;

  MetaLink({
    this.url,
    this.label,
    this.active,
  });

  factory MetaLink.fromJson(Map<String, dynamic> json) => MetaLink(
        url: json["url"] as String?,
        label: json["label"] as String?,
        active: json["active"] as bool?,
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
      };
}