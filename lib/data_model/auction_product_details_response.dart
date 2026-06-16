// To parse this JSON data, do
//
//     final auctionProductDetailsResponse = auctionProductDetailsResponseFromJson(jsonString);

import 'dart:convert';
import 'package:flutter/material.dart';

AuctionProductDetailsResponse auctionProductDetailsResponseFromJson(
        String str) =>
    AuctionProductDetailsResponse.fromJson(json.decode(str));

String auctionProductDetailsResponseToJson(
        AuctionProductDetailsResponse data) =>
    json.encode(data.toJson());

class AuctionProductDetailsResponse {
  AuctionProductDetailsResponse({
    this.auctionProduct,
    this.success,
    this.status,
  });

  List<AuctionDetailProducts>? auctionProduct;
  bool? success;
  int? status;

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  List<AuctionDetailProducts>? get auction_product => auctionProduct;
  // ============ END SNAKE_CASE GETTERS ============

  factory AuctionProductDetailsResponse.fromJson(Map<String, dynamic> json) =>
      AuctionProductDetailsResponse(
        auctionProduct: json["data"] != null
            ? List<AuctionDetailProducts>.from(
                json["data"].map((x) => AuctionDetailProducts.fromJson(x)))
            : [],
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": auctionProduct != null
            ? List<dynamic>.from(auctionProduct!.map((x) => x.toJson()))
            : [],
        "success": success,
        "status": status,
      };
}

class AuctionDetailProducts {
  AuctionDetailProducts({
    // Basic Product Info
    this.id,
    this.name,
    this.slug,
    this.addedBy,
    this.sellerId,
    this.shopId,
    this.shopSlug,
    this.shopName,
    this.shopLogo,
    this.photos,
    this.thumbnailImage,
    this.tags,
    this.priceHighLow,
    this.choiceOptions,
    this.colors,
    this.hasDiscount,
    this.discount,
    this.strokedPrice,
    this.mainPrice,
    this.calculablePrice,
    this.currencySymbol,
    this.currentStock,
    this.unit,
    this.rating,
    this.ratingCount,
    this.earnPoint,
    this.description,
    this.downloads,
    this.videoLink,
    this.link,
    this.brand,
    this.wholesale,
    this.estShippingTime,
    // Auction Related
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
    this.videos,
    // Additional fields that might be needed
    this.totalBids,
    this.highestBidder,
    this.reviewsCount,
    this.isInWishlist,
  });

  // Basic Product Info
  int? id;
  String? name;
  String? slug;
  String? addedBy;
  int? sellerId;
  int? shopId;
  String? shopSlug;
  String? shopName;
  String? shopLogo;
  List<Photo>? photos;
  String? thumbnailImage;
  List<String>? tags;
  String? priceHighLow;
  List<ChoiceOption>? choiceOptions;
  List<dynamic>? colors;
  bool? hasDiscount;
  dynamic discount;
  String? strokedPrice;
  String? mainPrice;
  dynamic calculablePrice;
  String? currencySymbol;
  int? currentStock;
  String? unit;
  int? rating;
  int? ratingCount;
  int? earnPoint;
  String? description;
  String? downloads;
  dynamic videoLink;
  String? link;
  Brand? brand;
  List<Wholesale>? wholesale;
  int? estShippingTime;
  
  // Auction Related
  dynamic auctionEndDate;
  dynamic auctionStartDate;
  String? startingBid;
  String? minBidPrice;
  String? highestBid;
  int? swipeRight;
  int? swipeLeft;
  int? pointPerBid;
  int? pointPerBidCustom;
  int? pointMultiplierSystem;
  int? auctionProduct;
  List<Video>? videos;
  
  // Additional fields
  int? totalBids;
  String? highestBidder;
  int? reviewsCount;
  bool? isInWishlist;

  // ============ SNAKE_CASE GETTERS FOR BACKWARDS COMPATIBILITY ============
  String? get added_by => addedBy;
  int? get seller_id => sellerId;
  int? get shop_id => shopId;
  String? get shop_slug => shopSlug;
  String? get shop_name => shopName;
  String? get shop_logo => shopLogo;
  String? get thumbnail_image => thumbnailImage;
  String? get price_high_low => priceHighLow;
  List<ChoiceOption>? get choice_options => choiceOptions;
  bool? get has_discount => hasDiscount;
  String? get stroked_price => strokedPrice;
  String? get main_price => mainPrice;
  dynamic get calculable_price => calculablePrice;
  String? get currency_symbol => currencySymbol;
  int? get current_stock => currentStock;
  int? get rating_count => ratingCount;
  int? get earn_point => earnPoint;
  dynamic get video_link => videoLink;
  int? get total_bids => totalBids;
  String? get highest_bidder => highestBidder;
  int? get reviews_count => reviewsCount;
  bool? get is_in_wishlist => isInWishlist;
  int? get point_per_bid => pointPerBid;
  int? get point_per_bid_custom => pointPerBidCustom;
  int? get point_multiplier_system => pointMultiplierSystem;
  int? get swipe_right => swipeRight;
  int? get swipe_left => swipeLeft;
  int? get auction_product => auctionProduct;
  String? get starting_bid => startingBid;
  String? get min_bid_price => minBidPrice;
  String? get highest_bid => highestBid;
  dynamic get auction_end_date => auctionEndDate;
  dynamic get auction_start_date => auctionStartDate;
  // ============ END SNAKE_CASE GETTERS ============

  factory AuctionDetailProducts.fromJson(Map<String, dynamic> json) =>
      AuctionDetailProducts(
        // Basic Product Info
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        addedBy: json["added_by"],
        sellerId: json["seller_id"],
        shopId: json["shop_id"],
        shopSlug: json["shop_slug"],
        shopName: json["shop_name"],
        shopLogo: json["shop_logo"],
        estShippingTime: json["est_shipping_time"],
        photos: json["photos"] != null
            ? List<Photo>.from(json["photos"].map((x) => Photo.fromJson(x)))
            : [],
        thumbnailImage: json["thumbnail_image"],
        tags: json["tags"] != null
            ? List<String>.from(json["tags"].map((x) => x))
            : [],
        priceHighLow: json["price_high_low"],
        choiceOptions: json["choice_options"] != null
            ? List<ChoiceOption>.from(
                json["choice_options"].map((x) => ChoiceOption.fromJson(x)))
            : [],
        colors: json["colors"] != null
            ? List<dynamic>.from(json["colors"].map((x) => x))
            : [],
        hasDiscount: json["has_discount"],
        discount: json["discount"],
        strokedPrice: json["stroked_price"],
        mainPrice: json["main_price"],
        calculablePrice: json["calculable_price"],
        currencySymbol: json["currency_symbol"],
        currentStock: json["current_stock"],
        unit: json["unit"],
        rating: json["rating"]?.toInt(),
        ratingCount: json["rating_count"],
        earnPoint: json["earn_point"]?.toInt(),
        description: json["description"] == null || json["description"] == ""
            ? "No Description is available"
            : json['description'],
        downloads: json["downloads"],
        videoLink: json["video_link"],
        link: json["link"],
        brand: json["brand"] != null ? Brand.fromJson(json["brand"]) : null,
        wholesale: json["wholesale"] != null
            ? List<Wholesale>.from(
                json["wholesale"].map((x) => Wholesale.fromJson(x)))
            : [],
        // Auction Related
        auctionEndDate: json["auction_end_date"],
        auctionStartDate: json["auction_start_date"],
        startingBid: json["starting_bid"],
        minBidPrice: json["min_bid_price"],
        highestBid: json["highest_bid"],
        swipeRight: json["swipe_right"],
        swipeLeft: json["swipe_left"],
        pointPerBid: json["point_per_bid"],
        pointPerBidCustom: json["point_per_bid_custom"],
        pointMultiplierSystem: json["point_multiplier_system"],
        auctionProduct: json["auction_product"],
        videos: json["videos"] != null
            ? List<Video>.from(json["videos"].map((x) => Video.fromJson(x)))
            : [],
        // Additional fields
        totalBids: json["total_bids"],
        highestBidder: json["highest_bidder"],
        reviewsCount: json["reviews_count"],
        isInWishlist: json["is_in_wishlist"],
      );

  Map<String, dynamic> toJson() => {
        // Basic Product Info
        "id": id,
        "name": name,
        "slug": slug,
        "added_by": addedBy,
        "seller_id": sellerId,
        "shop_id": shopId,
        "est_shipping_time": estShippingTime,
        "shop_slug": shopSlug,
        "shop_name": shopName,
        "shop_logo": shopLogo,
        "photos": photos != null
            ? List<dynamic>.from(photos!.map((x) => x.toJson()))
            : [],
        "thumbnail_image": thumbnailImage,
        "tags": tags != null ? List<dynamic>.from(tags!.map((x) => x)) : [],
        "price_high_low": priceHighLow,
        "choice_options": choiceOptions != null
            ? List<dynamic>.from(choiceOptions!.map((x) => x.toJson()))
            : [],
        "colors": colors != null ? List<dynamic>.from(colors!.map((x) => x)) : [],
        "has_discount": hasDiscount,
        "discount": discount,
        "stroked_price": strokedPrice,
        "main_price": mainPrice,
        "calculable_price": calculablePrice,
        "currency_symbol": currencySymbol,
        "current_stock": currentStock,
        "unit": unit,
        "rating": rating,
        "rating_count": ratingCount,
        "earn_point": earnPoint,
        "description": description,
        "downloads": downloads,
        "video_link": videoLink,
        "link": link,
        "brand": brand?.toJson(),
        "wholesale": wholesale != null
            ? List<dynamic>.from(wholesale!.map((x) => x.toJson()))
            : [],
        // Auction Related
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
        "videos": videos != null
            ? List<dynamic>.from(videos!.map((x) => x.toJson()))
            : [],
        // Additional fields
        "total_bids": totalBids,
        "highest_bidder": highestBidder,
        "reviews_count": reviewsCount,
        "is_in_wishlist": isInWishlist,
      };

  // ============ HELPER METHODS ============
  
  // Auction helpers
  bool get isAuctionProduct => (auctionProduct ?? 0) == 1;
  
  bool get isAuctionEnded {
    if (!isAuctionProduct) return false;
    if (auctionEndDate is String && auctionEndDate == 'Ended') return true;
    if (auctionEndDate is int && (auctionEndDate as int) <= 0) return true;
    if (auctionEndDate is int && (auctionEndDate as int) > 0) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return (auctionEndDate as int) <= now;
    }
    return false;
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
      return startingBid ?? '0';
    }
    return mainPrice ?? '0';
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
    return startingBid ?? '0';
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
  double get averageRating => (rating ?? 0).toDouble();
  
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
    return auctionEndDate?.toString() ?? '0';
  }
  
  // Price helpers
  String getFormattedPrice(String? price) {
    if (price == null || price.isEmpty) return '0';
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
  
  // Currency helper
  String formatPrice(double? price) {
    if (price == null) return '0.00';
    final symbol = currencySymbol ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
  }
  
  String formatPriceFromString(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) return '0.00';
    final price = double.tryParse(priceStr);
    return formatPrice(price);
  }
}

class Photo {
  Photo({
    this.variant,
    this.path,
  });

  String? variant;
  String? path;

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        variant: json["variant"],
        path: json["path"],
      );

  Map<String, dynamic> toJson() => {
        "variant": variant,
        "path": path,
      };
}

class Video {
  Video({
    this.path,
    this.thumbnail,
  });

  String? path;
  String? thumbnail;

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        path: json["path"],
        thumbnail: json["thumbnail"],
      );

  Map<String, dynamic> toJson() => {
        "path": path,
        "thumbnail": thumbnail,
      };
}

class Brand {
  Brand({
    this.id,
    this.slug,
    this.name,
    this.logo,
  });

  int? id;
  String? slug;
  String? name;
  String? logo;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json["id"],
        slug: json["slug"],
        name: json["name"],
        logo: json["logo"],
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
  ChoiceOption({
    this.name,
    this.title,
    this.options,
  });

  String? name;
  String? title;
  List<String>? options;

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
        name: json["name"],
        title: json["title"],
        options: json["options"] != null
            ? List<String>.from(json["options"].map((x) => x))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "title": title,
        "options": options != null
            ? List<dynamic>.from(options!.map((x) => x))
            : [],
      };
}

class Wholesale {
  dynamic minQty;
  dynamic maxQty;
  dynamic price;

  Wholesale({
    this.minQty,
    this.maxQty,
    this.price,
  });

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
  
  double get priceValue {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    return double.tryParse(price?.toString() ?? '0') ?? 0.0;
  }
  
  String get priceText {
    return priceValue.toStringAsFixed(2);
  }
  
  String get quantityRangeText {
    if (maxQuantity == 0) {
      return '${minQuantity}+';
    }
    return '$minQuantity - $maxQuantity';
  }
}