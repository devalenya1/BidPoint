// To parse this JSON data, do
//
//     final categoryResponse = categoryResponseFromJson(jsonString);

import 'dart:convert';

CategoryResponse categoryResponseFromJson(String str) =>
    CategoryResponse.fromJson(json.decode(str));

String categoryResponseToJson(CategoryResponse data) =>
    json.encode(data.toJson());

class CategoryResponse {
  CategoryResponse({
    this.categories,
    this.recentWinners,
    this.success,
    this.status,
  });

  List<Category>? categories;
  List<RecentWinner>? recentWinners;
  bool? success;
  int? status;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) => CategoryResponse(
        categories: json["data"] == null
            ? []
            : List<Category>.from(json["data"].map((x) => Category.fromJson(x))),
        recentWinners: json["recent_winners"] == null
            ? []
            : List<RecentWinner>.from(
                json["recent_winners"].map((x) => RecentWinner.fromJson(x))),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": categories == null
            ? []
            : List<dynamic>.from(categories!.map((x) => x.toJson())),
        "recent_winners": recentWinners == null
            ? []
            : List<dynamic>.from(recentWinners!.map((x) => x.toJson())),
        "success": success,
        "status": status,
      };
}

class Category {
  Category({
    this.id,
    this.name,
    this.slug,
    this.banner,
    this.coverImage,
    this.icon,
    this.numberOfChildren,
    this.links,
  });

  int? id;
  String? name;
  String? slug;
  String? banner;
  String? coverImage;
  String? icon;
  int? numberOfChildren;
  Links? links;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        banner: json["banner"],
        coverImage: json["cover_image"],
        icon: json["icon"],
        numberOfChildren: json["number_of_children"],
        links: json["links"] == null ? null : Links.fromJson(json["links"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "banner": banner,
        "cover_image": coverImage,
        "icon": icon,
        "number_of_children": numberOfChildren,
        "links": links?.toJson(),
      };
}

class Links {
  Links({
    this.products,
    this.subCategories,
  });

  String? products;
  String? subCategories;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        products: json["products"],
        subCategories: json["sub_categories"],
      );

  Map<String, dynamic> toJson() => {
        "products": products,
        "sub_categories": subCategories,
      };
}

/// 🏆 Recent winner entry returned alongside categories
class RecentWinner {
  RecentWinner({
    this.productId,
    this.productName,
    this.productSlug,
    this.thumbnail,
    this.purchasePrice,
    this.auctionEndDate,
    this.highestBid,
    this.bidAt,
    this.winnerId,
    this.winnerName,
    this.winnerAvatar,
    this.links,
  });

  int? productId;
  String? productName;
  String? productSlug;
  String? thumbnail;
  double? purchasePrice;
  int? auctionEndDate;
  double? highestBid;
  String? bidAt;
  int? winnerId;
  String? winnerName;
  String? winnerAvatar;
  WinnerLinks? links;

  factory RecentWinner.fromJson(Map<String, dynamic> json) => RecentWinner(
        productId: json["product_id"],
        productName: json["product_name"],
        productSlug: json["product_slug"],
        thumbnail: json["thumbnail"],
        purchasePrice: json["purchase_price"] == null
            ? null
            : (json["purchase_price"] as num).toDouble(),
        auctionEndDate: json["auction_end_date"],
        highestBid: json["highest_bid"] == null
            ? null
            : (json["highest_bid"] as num).toDouble(),
        bidAt: json["bid_at"],
        winnerId: json["winner_id"],
        winnerName: json["winner_name"],
        winnerAvatar: json["winner_avatar"],
        links: json["links"] == null ? null : WinnerLinks.fromJson(json["links"]),
      );

  Map<String, dynamic> toJson() => {
        "product_id": productId,
        "product_name": productName,
        "product_slug": productSlug,
        "thumbnail": thumbnail,
        "purchase_price": purchasePrice,
        "auction_end_date": auctionEndDate,
        "highest_bid": highestBid,
        "bid_at": bidAt,
        "winner_id": winnerId,
        "winner_name": winnerName,
        "winner_avatar": winnerAvatar,
        "links": links?.toJson(),
      };
}

class WinnerLinks {
  WinnerLinks({this.product});

  String? product;

  factory WinnerLinks.fromJson(Map<String, dynamic> json) => WinnerLinks(
        product: json["product"],
      );

  Map<String, dynamic> toJson() => {
        "product": product,
      };
}