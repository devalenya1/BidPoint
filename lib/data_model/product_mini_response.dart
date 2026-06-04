// To parse this JSON data, do
//
//     final productMiniResponse = productMiniResponseFromJson(jsonString);
//https://app.quicktype.io/
import 'dart:convert';

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
        products:
            List<Product>.from(json["data"]?.map((x) => Product.fromJson(x))),
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(products!.map((x) => x.toJson())),
        "meta": meta == null ? null : meta!.toJson(),
        "success": success,
        "status": status,
      };
}

class Product {
  Product({
    this.id,
    this.slug,
    this.name,
    this.thumbnail_image,
    this.main_price,
    this.stroked_price,
    this.has_discount,
    this.discount,
    this.rating,
    this.sales,
    this.links,
    this.isWholesale,
    // this.auction_end_date,
    // this.starting_bid,
    // this.min_bid_price,
    // this.highest_bid,
    // this.swipe_right,
    // this.swipe_left,
    // this.point_per_bid,
    // this.auction_start_date,
    // this.point_per_bid_custom,
    // this.point_multiplier_system,
    // this.auction_product,
  });

  int? id;
  String? slug;
  String? name;
  String? thumbnail_image;
  String? main_price;
  String? stroked_price;
  bool? has_discount;
  var discount;
  int? rating;
  int? sales;
  Links? links;
  bool? isWholesale;
  
  // var auction_end_date;
  // String? starting_bid;
  // String? min_bid_price;
  // String? highest_bid;
  // String? swipe_right;
  // String? swipe_left;
  // String? point_per_bid;
  // var auction_start_date;
  // String? point_per_bid_custom;
  // String? point_multiplier_system;
  // String? auction_product;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        slug: json["slug"],
        name: json["name"],
        thumbnail_image: json["thumbnail_image"],
        main_price: json["main_price"],
        stroked_price: json["stroked_price"],
        has_discount: json["has_discount"],
        discount: json["discount"],
        rating: json["rating"]?.toInt(),
        sales: json["sales"],
        links: json["links"] != null ? Links.fromJson(json["links"]) : null,
        isWholesale: json["is_wholesale"],
        // auction_end_date: json["auction_end_date"],
        // starting_bid: json["starting_bid"],
        // min_bid_price: json["min_bid_price"],
        // highest_bid: json["highest_bid"],
        // swipe_right: json["swipe_right"],
        // swipe_left: json["swipe_left"],
        // point_per_bid: json["point_per_bid"],
        // auction_start_date: json["auction_start_date"],
        // point_per_bid_custom: json["point_per_bid_custom"],
        // point_multiplier_system: json["point_multiplier_system"],
        // auction_product: json["auction_product"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "thumbnail_image": thumbnail_image,
        "main_price": main_price,
        "stroked_price": stroked_price,
        "has_discount": has_discount,
        "discount": discount,
        "rating": rating,
        "sales": sales,
        "links": links!.toJson(),
        "is_wholesale": isWholesale,        
        // "auction_end_date": auction_end_date,
        // "auction_start_date": auction_start_date,
        // "starting_bid": starting_bid,
        // "min_bid_price": min_bid_price,
        // "highest_bid": highest_bid,
        // "swipe_right": swipe_right,
        // "swipe_left": swipe_left,
        // "point_per_bid": point_per_bid,
        // "point_per_bid_custom": point_per_bid_custom,
        // "point_multiplier_system": point_multiplier_system,
        // "auction_product": auction_product,
      };
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
