
import 'dart:convert';

CategoryResponse categoryResponseFromJson(String str) =>
    CategoryResponse.fromJson(json.decode(str));

String categoryResponseToJson(CategoryResponse data) =>
    json.encode(data.toJson());

class CategoryResponse {
  CategoryResponse({
    this.categories,
    this.featuredCategories,
    this.hotCategories,
    this.auctionStatusCategories,
    this.recentWinners,
    this.success,
    this.status,
  });

  List<Category>? categories;
  List<Category>? featuredCategories;
  List<Category>? hotCategories;
  List<Category>? auctionStatusCategories;
  List<RecentWinner>? recentWinners;
  bool? success;
  int? status;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categories: json["data"] == null
          ? []
          : List<Category>.from(
              json["data"].map((x) => Category.fromJson(x)),
            ),

      featuredCategories: json["featured_categories"] == null
          ? []
          : List<Category>.from(
              json["featured_categories"].map(
                (x) => Category.fromJson(x),
              ),
            ),

      hotCategories: json["hot_categories"] == null
          ? []
          : List<Category>.from(
              json["hot_categories"].map(
                (x) => Category.fromJson(x),
              ),
            ),

      auctionStatusCategories:
          json["auction_status_categories"] == null
              ? []
              : List<Category>.from(
                  json["auction_status_categories"].map(
                    (x) => Category.fromJson(x),
                  ),
                ),

      recentWinners: json["recent_winners"] == null
          ? []
          : List<RecentWinner>.from(
              json["recent_winners"].map(
                (x) => RecentWinner.fromJson(x),
              ),
            ),

      success: json["success"],
      status: json["status"],
    );
  }

  Map<String, dynamic> toJson() => {
        "data": categories?.map((x) => x.toJson()).toList() ?? [],

        "featured_categories":
            featuredCategories?.map((x) => x.toJson()).toList() ?? [],

        "hot_categories":
            hotCategories?.map((x) => x.toJson()).toList() ?? [],

        "auction_status_categories":
            auctionStatusCategories?.map((x) => x.toJson()).toList() ?? [],

        "recent_winners":
            recentWinners?.map((x) => x.toJson()).toList() ?? [],

        "success": success,
        "status": status,
      };
}

// ======================================================
// CATEGORY MODEL
// ======================================================

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
        id: json["id"] is num ? (json["id"] as num).toInt() : null,
        name: json["name"]?.toString(),
        slug: json["slug"]?.toString(),
        banner: json["banner"]?.toString(),
        coverImage: json["cover_image"]?.toString(),
        icon: json["icon"]?.toString(),

        numberOfChildren: json["number_of_children"] is num
            ? (json["number_of_children"] as num).toInt()
            : null,

        links: json["links"] == null
            ? null
            : Links.fromJson(json["links"]),
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

// ======================================================
// CATEGORY LINKS
// ======================================================

class Links {
  Links({
    this.products,
    this.subCategories,
  });

  String? products;
  String? subCategories;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        products: json["products"]?.toString(),
        subCategories: json["sub_categories"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "products": products,
        "sub_categories": subCategories,
      };
}

// ======================================================
// RECENT WINNERS
// ======================================================

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
        productId: json["product_id"] is num
            ? (json["product_id"] as num).toInt()
            : null,

        productName: json["product_name"]?.toString(),
        productSlug: json["product_slug"]?.toString(),
        thumbnail: json["thumbnail"]?.toString(),

        purchasePrice: json["purchase_price"] is num
            ? (json["purchase_price"] as num).toDouble()
            : null,

        auctionEndDate: json["auction_end_date"] is num
            ? (json["auction_end_date"] as num).toInt()
            : null,

        highestBid: json["highest_bid"] is num
            ? (json["highest_bid"] as num).toDouble()
            : null,

        bidAt: json["bid_at"]?.toString(),

        winnerId: json["winner_id"] is num
            ? (json["winner_id"] as num).toInt()
            : null,

        winnerName: json["winner_name"]?.toString(),
        winnerAvatar: json["winner_avatar"]?.toString(),

        links: json["links"] == null
            ? null
            : WinnerLinks.fromJson(json["links"]),
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

// ======================================================
// WINNER LINKS
// ======================================================

class WinnerLinks {
  WinnerLinks({this.product});

  String? product;

  factory WinnerLinks.fromJson(Map<String, dynamic> json) =>
      WinnerLinks(
        product: json["product"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "product": product,
      };
}
