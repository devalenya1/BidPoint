// product_detail_response.dart
import 'dart:convert';
import 'package:flutter/material.dart';

ProductDetailResponse productDetailResponseFromJson(String str) =>
    ProductDetailResponse.fromJson(json.decode(str));

String productDetailResponseToJson(ProductDetailResponse data) =>
    json.encode(data.toJson());

class ProductDetailResponse {
  List<DetailedProduct>? data;
  bool? success;
  int? status;

  ProductDetailResponse({
    this.data,
    this.success,
    this.status,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      data: json["data"] != null
          ? List<DetailedProduct>.from(
              json["data"].map((x) => DetailedProduct.fromJson(x)))
          : [],
      success: json["success"] ?? false,
      status: json["status"] ?? 200,
    );
  }

  Map<String, dynamic> toJson() => {
        "data": data != null
            ? List<dynamic>.from(data!.map((x) => x.toJson()))
            : [],
        "success": success,
        "status": status,
      };
}

class DetailedProduct {
  // Basic Information
  int? id;
  String? name;
  String? addedBy;
  int? sellerId;
  int? shopId;
  String? shopSlug;
  String? shopName;
  String? shopLogo;
  String? thumbnailImage;
  List<String>? tags;
  String? priceHighLow;
  String? unit;
  double? rating;
  int? ratingCount;
  double? earnPoint;
  String? description;
  String? downloads;
  dynamic videoLink; // Can be String or List
  String? link;
  int? estShippingTime;
  
  // Price Related
  List<Photo>? photos;
  List<Video>? videos;
  bool? hasDiscount;
  dynamic discount;
  String? strokedPrice;
  String? mainPrice;
  double? calculablePrice;
  String? currencySymbol;
  int? currentStock;
  
  // Product Options
  List<ChoiceOption>? choiceOptions;
  List<dynamic>? colors;
  
  // Brand
  Brand? brand;
  
  // Wholesale
  List<Wholesale>? wholesale;
  
  // Auction Related
  dynamic auctionEndDate; // Can be "Ended" (String) or timestamp (int)
  dynamic auctionStartDate; // Can be "Upcoming" (String) or timestamp (int)
  String? startingBid;
  String? minBidPrice;
  String? highestBid;
  int? swipeRight;
  int? swipeLeft;
  int? pointPerBid;
  int? pointPerBidCustom;
  int? pointMultiplierSystem;
  int? auctionProduct;

  DetailedProduct({
    this.id,
    this.name,
    this.addedBy,
    this.sellerId,
    this.shopId,
    this.shopSlug,
    this.shopName,
    this.shopLogo,
    this.thumbnailImage,
    this.tags,
    this.priceHighLow,
    this.unit,
    this.rating,
    this.ratingCount,
    this.earnPoint,
    this.description,
    this.downloads,
    this.videoLink,
    this.link,
    this.estShippingTime,
    this.photos,
    this.videos,
    this.hasDiscount,
    this.discount,
    this.strokedPrice,
    this.mainPrice,
    this.calculablePrice,
    this.currencySymbol,
    this.currentStock,
    this.choiceOptions,
    this.colors,
    this.brand,
    this.wholesale,
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
  });

  factory DetailedProduct.fromJson(Map<String, dynamic> json) {
    return DetailedProduct(
      id: json["id"] as int?,
      name: json["name"] as String?,
      addedBy: json["added_by"] as String?,
      sellerId: json["seller_id"] as int?,
      shopId: json["shop_id"] as int?,
      shopSlug: json["shop_slug"] as String?,
      shopName: json["shop_name"] as String?,
      shopLogo: json["shop_logo"] as String?,
      thumbnailImage: json["thumbnail_image"] as String?,
      tags: json["tags"] != null
          ? List<String>.from(json["tags"].map((x) => x.toString()))
          : [],
      priceHighLow: json["price_high_low"] as String?,
      unit: json["unit"] as String?,
      rating: (json["rating"] as num?)?.toDouble(),
      ratingCount: json["rating_count"] as int?,
      earnPoint: (json["earn_point"] as num?)?.toDouble(),
      description: json["description"] as String?,
      downloads: json["downloads"] as String?,
      videoLink: json["video_link"],
      link: json["link"] as String?,
      estShippingTime: json["est_shipping_time"] as int?,
      photos: json["photos"] != null
          ? List<Photo>.from(json["photos"].map((x) => Photo.fromJson(x)))
          : [],
      videos: json["videos"] != null
          ? List<Video>.from(json["videos"].map((x) => Video.fromJson(x)))
          : [],
      hasDiscount: json["has_discount"] as bool?,
      discount: json["discount"],
      strokedPrice: json["stroked_price"] as String?,
      mainPrice: json["main_price"] as String?,
      calculablePrice: (json["calculable_price"] as num?)?.toDouble(),
      currencySymbol: json["currency_symbol"] as String?,
      currentStock: json["current_stock"] as int?,
      choiceOptions: json["choice_options"] != null
          ? List<ChoiceOption>.from(
              json["choice_options"].map((x) => ChoiceOption.fromJson(x)))
          : [],
      colors: json["colors"] as List<dynamic>?,
      brand: json["brand"] != null ? Brand.fromJson(json["brand"]) : null,
      wholesale: json["wholesale"] != null
          ? List<Wholesale>.from(
              json["wholesale"].map((x) => Wholesale.fromJson(x)))
          : [],
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
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "added_by": addedBy,
        "seller_id": sellerId,
        "shop_id": shopId,
        "shop_slug": shopSlug,
        "shop_name": shopName,
        "shop_logo": shopLogo,
        "thumbnail_image": thumbnailImage,
        "tags": tags,
        "price_high_low": priceHighLow,
        "unit": unit,
        "rating": rating,
        "rating_count": ratingCount,
        "earn_point": earnPoint,
        "description": description,
        "downloads": downloads,
        "video_link": videoLink,
        "link": link,
        "est_shipping_time": estShippingTime,
        "photos": photos?.map((e) => e.toJson()).toList(),
        "videos": videos?.map((e) => e.toJson()).toList(),
        "has_discount": hasDiscount,
        "discount": discount,
        "stroked_price": strokedPrice,
        "main_price": mainPrice,
        "calculable_price": calculablePrice,
        "currency_symbol": currencySymbol,
        "current_stock": currentStock,
        "choice_options": choiceOptions?.map((e) => e.toJson()).toList(),
        "colors": colors,
        "brand": brand?.toJson(),
        "wholesale": wholesale?.map((e) => e.toJson()).toList(),
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
      };

  // ============ HELPER METHODS ============
  
  // Auction helpers
  bool get isAuctionProduct => (auctionProduct ?? 0) == 1;
  
  bool get isAuctionEnded {
    if (!isAuctionProduct) return false;
    return auctionEndDate is String && auctionEndDate == 'Ended';
  }
  
  bool get isAuctionActive {
    if (!isAuctionProduct) return false;
    if (auctionEndDate is int && (auctionEndDate as int) > 0) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return (auctionEndDate as int) > now && !isAuctionEnded;
    }
    return false;
  }
  
  bool get isAuctionUpcoming {
    if (!isAuctionProduct) return false;
    if (auctionStartDate is String && auctionStartDate == 'Upcoming') return true;
    if (auctionStartDate is int && (auctionStartDate as int) > 0) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return (auctionStartDate as int) > now;
    }
    return false;
  }
  
  String getAuctionStatus() {
    if (!isAuctionProduct) return 'Regular Product';
    if (isAuctionUpcoming) return 'Upcoming';
    if (isAuctionActive) return 'Live Auction';
    if (isAuctionEnded) return 'Auction Ended';
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
      return startingBid ?? 'N/A';
    }
    return mainPrice ?? 'N/A';
  }
  
  String getOriginalPrice() {
    if (isAuctionProduct) {
      return startingBid ?? '';
    }
    return strokedPrice ?? '';
  }
  
  String getDiscountText() {
    if (hasDiscount == true && discount != null) {
      return discount.toString();
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
  
  // Swipe helpers
  int get totalSwipes => (swipeRight ?? 0) + (swipeLeft ?? 0);
  
  int get swipeRatio {
    final total = totalSwipes;
    if (total == 0) return 0;
    return ((swipeRight ?? 0) / total * 100).round();
  }
  
  // Points helpers
  int get effectivePointPerBid {
    if (pointPerBidCustom != null && pointPerBidCustom! > 0) {
      return pointPerBidCustom!;
    }
    return pointPerBid ?? 0;
  }
  
  String getPointPerBidText() {
    return effectivePointPerBid.toString();
  }
  
  // Stock helpers
  bool get isInStock => (currentStock ?? 0) > 0;
  
  String getStockStatus() {
    if (!isInStock) return 'Out of Stock';
    if ((currentStock ?? 0) < 10) return 'Low Stock';
    return 'In Stock';
  }
  
  Color getStockStatusColor() {
    if (!isInStock) return Colors.red;
    if ((currentStock ?? 0) < 10) return Colors.orange;
    return Colors.green;
  }
  
  // Rating helpers
  double get averageRating => rating ?? 0.0;
  
  int get totalReviews => ratingCount ?? 0;
  
  String getRatingText() {
    if (totalReviews == 0) return 'No reviews yet';
    return '$averageRating ★ ($totalReviews reviews)';
  }
  
  // Video helpers
  List<String> getVideoLinks() {
    if (videoLink is String && (videoLink as String).isNotEmpty) {
      return [videoLink as String];
    }
    if (videoLink is List) {
      return List<String>.from(videoLink);
    }
    return [];
  }
  
  bool get hasVideos => getVideoLinks().isNotEmpty || (videos?.isNotEmpty ?? false);
  
  // Date helpers
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
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    }
    return auctionEndDate?.toString() ?? 'N/A';
  }
  
  // Price helpers
  String getFormattedPrice(String? price) {
    if (price == null || price.isEmpty) return 'N/A';
    return price;
  }
  
  String getPriceRange() {
    return priceHighLow ?? getDisplayPrice();
  }
  
  // Description helper
  String getDisplayDescription() {
    if (description == null || description!.isEmpty) {
      return 'No description is available';
    }
    return description!;
  }
  
  // Shop helper
  bool get isInHouseProduct => addedBy == 'admin';
  
  String getShopDisplayName() {
    if (isInHouseProduct) return 'In House Product';
    return shopName ?? 'Unknown Shop';
  }
  
  // Wholesale helpers
  bool get hasWholesalePrices => wholesale != null && wholesale!.isNotEmpty;
  
  Wholesale? getWholesalePriceForQuantity(int quantity) {
    if (!hasWholesalePrices) return null;
    for (var wholesale in wholesale!) {
      final minQty = wholesale.minQty is int 
          ? wholesale.minQty 
          : int.tryParse(wholesale.minQty?.toString() ?? '0') ?? 0;
      final maxQty = wholesale.maxQty is int 
          ? wholesale.maxQty 
          : int.tryParse(wholesale.maxQty?.toString() ?? '0') ?? 0;
      
      if (quantity >= minQty && (maxQty == 0 || quantity <= maxQty)) {
        return wholesale;
      }
    }
    return null;
  }
  
  // Photo helpers
  List<String> getAllImageUrls() {
    final List<String> urls = [];
    if (thumbnailImage != null && thumbnailImage!.isNotEmpty) {
      urls.add(thumbnailImage!);
    }
    if (photos != null) {
      for (var photo in photos!) {
        if (photo.path != null && photo.path!.isNotEmpty) {
          urls.add(photo.path!);
        }
      }
    }
    return urls;
  }
  
  String getMainImageUrl() {
    if (photos != null && photos!.isNotEmpty && photos![0].path != null) {
      return photos![0].path!;
    }
    return thumbnailImage ?? '';
  }
}

class Photo {
  String? variant;
  String? path;

  Photo({this.variant, this.path});

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        variant: json["variant"] as String?,
        path: json["path"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "variant": variant,
        "path": path,
      };
}

class Video {
  String? path;
  String? thumbnail;

  Video({this.path, this.thumbnail});

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        path: json["path"] as String?,
        thumbnail: json["thumbnail"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "path": path,
        "thumbnail": thumbnail,
      };
}

class Brand {
  int? id;
  String? slug;
  String? name;
  String? logo;

  Brand({this.id, this.slug, this.name, this.logo});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json["id"] as int?,
        slug: json["slug"] as String?,
        name: json["name"] as String?,
        logo: json["logo"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "logo": logo,
      };
  
  bool get hasLogo => logo != null && logo!.isNotEmpty;
}

class ChoiceOption {
  String? name;
  String? title;
  List<String>? options;

  ChoiceOption({this.name, this.title, this.options});

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
        name: json["name"] as String?,
        title: json["title"] as String?,
        options: json["options"] != null
            ? List<String>.from(json["options"].map((x) => x.toString()))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "title": title,
        "options": options,
      };
}

class Wholesale {
  dynamic minQty;
  dynamic maxQty;
  dynamic price;

  Wholesale({this.minQty, this.maxQty, this.price});

  factory Wholesale.fromJson(Map<String, dynamic> json) => Wholesale(
        minQty: json["min_qty"],
        maxQty: json["max_qty"],
        price: json["price"],
      );

  Map<String, dynamic> toJson() => {
        "min_qty": minQty,
        "max_qty": maxQty,
        "price": price,
      };
  
  int get minQuantity {
    if (minQty is int) return minQty;
    return int.tryParse(minQty?.toString() ?? '0') ?? 0;
  }
  
  int get maxQuantity {
    if (maxQty is int) return maxQty;
    return int.tryParse(maxQty?.toString() ?? '0') ?? 0;
  }
  
  String get priceText {
    return price?.toString() ?? 'N/A';
  }
  
  String get quantityRangeText {
    if (maxQuantity == 0) {
      return '${minQuantity}+';
    }
    return '$minQuantity - $maxQuantity';
  }
}