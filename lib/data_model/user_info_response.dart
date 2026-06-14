// To parse this JSON data, do
//
//     final userInfoResponse = userInfoResponseFromJson(jsonString);

import 'dart:convert';

UserInfoResponse userInfoResponseFromJson(String str) => UserInfoResponse.fromJson(json.decode(str));

String userInfoResponseToJson(UserInfoResponse data) => json.encode(data.toJson());

class UserInfoResponse {
  UserInfoResponse({
    this.data,
    this.success,
    this.status,
  });

  List<UserInformation>? data;
  bool? success;
  int? status;

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) => UserInfoResponse(
    // Handle both list and single object responses
    data: json["data"] != null 
        ? (json["data"] is List 
            ? List<UserInformation>.from(json["data"].map((x) => UserInformation.fromJson(x)))
            : [UserInformation.fromJson(json["data"])])
        : [],
    success: json["success"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "data": data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : [],
    "success": success,
    "status": status,
  };
}

class UserInformation {
  UserInformation({
    this.id,
    this.name,
    this.email,
    this.avatar,
    this.address,
    this.country,
    this.state,
    this.city,
    this.postalCode,
    this.phone,
    this.balance,
    this.referralCode,
    this.remainingUploads,
    this.packageId,
    this.packageName,
    this.notifications,
    this.unreadNotificationsCount,
    this.affiliateLogs,
    this.totalAffiliateEarnings,
    this.affiliateWithdrawRequests,
    this.totalWithdrawnAmount,
    this.pendingWithdrawAmount,
    this.addresses,
    this.addressCount,
    this.defaultAddressCount,
    this.customerPackagePayments,
    this.totalPackagePayments,
    this.wishlist,
    this.wishlistCount,
    this.auctionBids,
    this.auctionBidsCount,
    this.distinctAuctionBids,
    this.distinctAuctionBidsCount,
    this.affiliateId,
    this.paypalEmail,
    this.bankName,
    this.accountHolder,
    this.ifscCode,
    this.accountNumber,
    this.affiliateBalance,
    this.affiliateStatus,
  });

  int? id;
  String? name;
  String? email;
  String? avatar;
  String? address;
  String? country;
  String? state;
  String? city;
  String? postalCode;
  String? phone;
  double? balance;
  String? referralCode;
  dynamic? remainingUploads;
  dynamic? packageId;
  String? packageName;
  List<Notification>? notifications;
  int? unreadNotificationsCount;
  List<AffiliateLog>? affiliateLogs;
  double? totalAffiliateEarnings;
  List<AffiliateWithdrawRequest>? affiliateWithdrawRequests;
  double? totalWithdrawnAmount;
  double? pendingWithdrawAmount;
  List<Address>? addresses;
  int? addressCount;
  int? defaultAddressCount;
  List<CustomerPackagePayment>? customerPackagePayments;
  double? totalPackagePayments;
  List<WishlistItem>? wishlist;
  int? wishlistCount;
  List<AuctionBid>? auctionBids;
  int? auctionBidsCount;
  List<DistinctAuctionBid>? distinctAuctionBids;
  int? distinctAuctionBidsCount;
  String? affiliateId;
  String? paypalEmail;
  String? bankName;
  String? accountHolder;
  String? accountNumber;
  String? ifscCode;
  double? affiliateBalance;
  int? affiliateStatus;

  factory UserInformation.fromJson(Map<String, dynamic> json) => UserInformation(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    avatar: json["avatar"],
    address: json["address"],
    country: json["country"],
    state: json["state"],
    city: json["city"],
    postalCode: json["postal_code"],
    phone: json["phone"],
    balance: json["balance"]?.toDouble(),
    referralCode: json["referral_code"],
    remainingUploads: json["remaining_uploads"],
    packageId: json["package_id"],
    packageName: json["package_name"],
    
    // Notifications
    notifications: json["notifications"] != null 
        ? List<Notification>.from(json["notifications"].map((x) => Notification.fromJson(x)))
        : [],
    unreadNotificationsCount: json["unread_notifications_count"],
    
    // Affiliate Logs
    affiliateLogs: json["affiliate_logs"] != null
        ? List<AffiliateLog>.from(json["affiliate_logs"].map((x) => AffiliateLog.fromJson(x)))
        : [],
    totalAffiliateEarnings: json["total_affiliate_earnings"]?.toDouble(),
    
    // Affiliate Withdraw Requests
    affiliateWithdrawRequests: json["affiliate_withdraw_requests"] != null
        ? List<AffiliateWithdrawRequest>.from(json["affiliate_withdraw_requests"].map((x) => AffiliateWithdrawRequest.fromJson(x)))
        : [],
    totalWithdrawnAmount: json["total_withdrawn_amount"]?.toDouble(),
    pendingWithdrawAmount: json["pending_withdraw_amount"]?.toDouble(),
    
    // Addresses
    addresses: json["addresses"] != null
        ? List<Address>.from(json["addresses"].map((x) => Address.fromJson(x)))
        : [],
    addressCount: json["address_count"],
    defaultAddressCount: json["default_address_count"],
    
    // Customer Package Payments
    customerPackagePayments: json["customer_package_payments"] != null
        ? List<CustomerPackagePayment>.from(json["customer_package_payments"].map((x) => CustomerPackagePayment.fromJson(x)))
        : [],
    totalPackagePayments: json["total_package_payments"]?.toDouble(),
    
    // Wishlist
    wishlist: json["wishlist"] != null
        ? List<WishlistItem>.from(json["wishlist"].map((x) => WishlistItem.fromJson(x)))
        : [],
    wishlistCount: json["wishlist_count"],
    
    // Auction Bids
    auctionBids: json["auction_bids"] != null
        ? List<AuctionBid>.from(json["auction_bids"].map((x) => AuctionBid.fromJson(x)))
        : [],
    auctionBidsCount: json["auction_bids_count"],
    
    // Distinct Auction Bids
    distinctAuctionBids: json["distinct_auction_bids"] != null
        ? List<DistinctAuctionBid>.from(json["distinct_auction_bids"].map((x) => DistinctAuctionBid.fromJson(x)))
        : [],
    distinctAuctionBidsCount: json["distinct_auction_bids_count"],
    
    // Affiliate Info
    affiliateId: json["affiliate_id"]?.toString(),
    paypalEmail: json["paypal_email"],
    bankName: json["bank_name"],
    accountHolder: json["account_holder"],
    accountNumber: json["account_number"],
    ifscCode: json["ifsc_code"],
    affiliateBalance: json["affiliate_balance"]?.toDouble(),
    affiliateStatus: json["affiliate_status"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "avatar": avatar,
    "address": address,
    "country": country,
    "state": state,
    "city": city,
    "postal_code": postalCode,
    "phone": phone,
    "balance": balance,
    "referral_code": referralCode,
    "remaining_uploads": remainingUploads,
    "package_id": packageId,
    "package_name": packageName,
    "notifications": notifications != null ? List<dynamic>.from(notifications!.map((x) => x.toJson())) : [],
    "unread_notifications_count": unreadNotificationsCount,
    "affiliate_logs": affiliateLogs != null ? List<dynamic>.from(affiliateLogs!.map((x) => x.toJson())) : [],
    "total_affiliate_earnings": totalAffiliateEarnings,
    "affiliate_withdraw_requests": affiliateWithdrawRequests != null ? List<dynamic>.from(affiliateWithdrawRequests!.map((x) => x.toJson())) : [],
    "total_withdrawn_amount": totalWithdrawnAmount,
    "pending_withdraw_amount": pendingWithdrawAmount,
    "addresses": addresses != null ? List<dynamic>.from(addresses!.map((x) => x.toJson())) : [],
    "address_count": addressCount,
    "default_address_count": defaultAddressCount,
    "customer_package_payments": customerPackagePayments != null ? List<dynamic>.from(customerPackagePayments!.map((x) => x.toJson())) : [],
    "total_package_payments": totalPackagePayments,
    "wishlist": wishlist != null ? List<dynamic>.from(wishlist!.map((x) => x.toJson())) : [],
    "wishlist_count": wishlistCount,
    "auction_bids": auctionBids != null ? List<dynamic>.from(auctionBids!.map((x) => x.toJson())) : [],
    "auction_bids_count": auctionBidsCount,
    "distinct_auction_bids": distinctAuctionBids != null ? List<dynamic>.from(distinctAuctionBids!.map((x) => x.toJson())) : [],
    "distinct_auction_bids_count": distinctAuctionBidsCount,
    "affiliate_id": affiliateId,
    "paypal_email": paypalEmail,
    "bank_name": bankName,
    "account_holder": accountHolder,
    "ifsc_code": ifscCode,
    "account_number": accountNumber,
    "affiliate_balance": affiliateBalance,
    "affiliate_status": affiliateStatus,
  };
}

class Notification {
  Notification({
    this.id,
    this.type,
    this.title,
    this.message,
    this.readAt,
    this.createdAt,
    this.isRead,
  });

  int? id;
  String? type;
  String? title;
  String? message;
  dynamic? readAt;
  DateTime? createdAt;
  bool? isRead;

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json["id"],
    type: json["type"],
    title: json["title"],
    message: json["message"],
    readAt: json["read_at"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    isRead: json["is_read"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "title": title,
    "message": message,
    "read_at": readAt,
    "created_at": createdAt?.toIso8601String(),
    "is_read": isRead,
  };
}

class AffiliateLog {
  AffiliateLog({
    this.id,
    this.bonusType,
    this.cameFrom,
    this.amount,
    this.formattedAmount,
    this.status,
    this.orderId,
    this.referredByUser,
    this.createdAt,
  });

  int? id;
  String? bonusType;
  String? cameFrom;
  double? amount;
  double? formattedAmount;
  int? status;
  dynamic? orderId;
  int? referredByUser;
  DateTime? createdAt;

  factory AffiliateLog.fromJson(Map<String, dynamic> json) => AffiliateLog(
    id: json["id"],
    bonusType: json["bonus_type"],
    cameFrom: json["came_from"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"]?.toDouble(),
    status: json["status"],
    orderId: json["order_id"],
    referredByUser: json["referred_by_user"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "bonus_type": bonusType,
    "came_from": cameFrom,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "status": status,
    "order_id": orderId,
    "referred_by_user": referredByUser,
    "created_at": createdAt?.toIso8601String(),
  };
}

class AffiliateWithdrawRequest {
  AffiliateWithdrawRequest({
    this.id,
    this.amount,
    this.formattedAmount,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  double? amount;
  double? formattedAmount;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory AffiliateWithdrawRequest.fromJson(Map<String, dynamic> json) => AffiliateWithdrawRequest(
    id: json["id"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"]?.toDouble(),
    status: json["status"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "status": status,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class Address {
  Address({
    this.id,
    this.address,
    this.countryId,
    this.countryName,
    this.stateId,
    this.stateName,
    this.cityId,
    this.cityName,
    this.areaId,
    this.areaName,
    this.longitude,
    this.latitude,
    this.postalCode,
    this.phone,
    this.setDefault,
    this.setBilling,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  String? address;
  int? countryId;
  String? countryName;
  dynamic? stateId;
  String? stateName;
  dynamic? cityId;
  String? cityName;
  dynamic? areaId;
  String? areaName;
  dynamic? longitude;
  dynamic? latitude;
  String? postalCode;
  String? phone;
  bool? setDefault;
  bool? setBilling;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json["id"],
    address: json["address"],
    countryId: json["country_id"],
    countryName: json["country_name"],
    stateId: json["state_id"],
    stateName: json["state_name"],
    cityId: json["city_id"],
    cityName: json["city_name"],
    areaId: json["area_id"],
    areaName: json["area_name"],
    longitude: json["longitude"],
    latitude: json["latitude"],
    postalCode: json["postal_code"],
    phone: json["phone"],
    setDefault: json["set_default"],
    setBilling: json["set_billing"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "address": address,
    "country_id": countryId,
    "country_name": countryName,
    "state_id": stateId,
    "state_name": stateName,
    "city_id": cityId,
    "city_name": cityName,
    "area_id": areaId,
    "area_name": areaName,
    "longitude": longitude,
    "latitude": latitude,
    "postal_code": postalCode,
    "phone": phone,
    "set_default": setDefault,
    "set_billing": setBilling,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class CustomerPackagePayment {
  CustomerPackagePayment({
    this.id,
    this.customerPackageId,
    this.packageName,
    this.paymentMethod,
    this.amount,
    this.formattedAmount,
    this.paymentDetails,
    this.approval,
    this.offlinePayment,
    this.reciept,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int? customerPackageId;
  String? packageName;
  String? paymentMethod;
  double? amount;
  double? formattedAmount;
  PaymentDetails? paymentDetails;
  int? approval;
  int? offlinePayment;
  dynamic? reciept;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory CustomerPackagePayment.fromJson(Map<String, dynamic> json) => CustomerPackagePayment(
    id: json["id"],
    customerPackageId: json["customer_package_id"],
    packageName: json["package_name"],
    paymentMethod: json["payment_method"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"]?.toDouble(),
    paymentDetails: json["payment_details"] != null ? PaymentDetails.fromJson(json["payment_details"]) : null,
    approval: json["approval"],
    offlinePayment: json["offline_payment"],
    reciept: json["reciept"],
    status: json["status"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "customer_package_id": customerPackageId,
    "package_name": packageName,
    "payment_method": paymentMethod,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "payment_details": paymentDetails?.toJson(),
    "approval": approval,
    "offline_payment": offlinePayment,
    "reciept": reciept,
    "status": status,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class PaymentDetails {
  PaymentDetails({
    this.paypalTransactionId,
    this.paypalIntent,
    this.paypalStatus,
    this.paypalPayerEmail,
    this.paypalPayerName,
    this.paypalAmount,
    this.paypalCurrency,
    this.paypalCaptureId,
    this.paypalCaptureStatus,
    this.paypalFee,
    this.paypalNetAmount,
    this.paypalCreateTime,
    this.paypalUpdateTime,
    this.paypalDebugId,
  });

  String? paypalTransactionId;
  String? paypalIntent;
  String? paypalStatus;
  String? paypalPayerEmail;
  String? paypalPayerName;
  String? paypalAmount;
  String? paypalCurrency;
  String? paypalCaptureId;
  String? paypalCaptureStatus;
  String? paypalFee;
  String? paypalNetAmount;
  String? paypalCreateTime;
  String? paypalUpdateTime;
  String? paypalDebugId;

  factory PaymentDetails.fromJson(Map<String, dynamic> json) => PaymentDetails(
    paypalTransactionId: json["paypal_transaction_id"],
    paypalIntent: json["paypal_intent"],
    paypalStatus: json["paypal_status"],
    paypalPayerEmail: json["paypal_payer_email"],
    paypalPayerName: json["paypal_payer_name"],
    paypalAmount: json["paypal_amount"],
    paypalCurrency: json["paypal_currency"],
    paypalCaptureId: json["paypal_capture_id"],
    paypalCaptureStatus: json["paypal_capture_status"],
    paypalFee: json["paypal_fee"],
    paypalNetAmount: json["paypal_net_amount"],
    paypalCreateTime: json["paypal_create_time"],
    paypalUpdateTime: json["paypal_update_time"],
    paypalDebugId: json["paypal_debug_id"],
  );

  Map<String, dynamic> toJson() => {
    "paypal_transaction_id": paypalTransactionId,
    "paypal_intent": paypalIntent,
    "paypal_status": paypalStatus,
    "paypal_payer_email": paypalPayerEmail,
    "paypal_payer_name": paypalPayerName,
    "paypal_amount": paypalAmount,
    "paypal_currency": paypalCurrency,
    "paypal_capture_id": paypalCaptureId,
    "paypal_capture_status": paypalCaptureStatus,
    "paypal_fee": paypalFee,
    "paypal_net_amount": paypalNetAmount,
    "paypal_create_time": paypalCreateTime,
    "paypal_update_time": paypalUpdateTime,
    "paypal_debug_id": paypalDebugId,
  };
}

class WishlistItem {
  WishlistItem({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.highestBid,
    this.slug,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int? productId;
  String? productName;
  String? productImage;
  double? productPrice;
  double? highestBid;
  String? slug;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    productPrice: json["product_price"]?.toDouble(),
    highestBid: json["highest_bid"]?.toDouble(),
    slug: json["slug"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "product_image": productImage,
    "product_price": productPrice,
    "highest_bid": highestBid,
    "slug": slug,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class AuctionBid {
  AuctionBid({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.amount,
    this.formattedAmount,
    this.dayOfBid,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int? productId;
  String? productName;
  String? productImage;
  double? amount;
  double? formattedAmount;
  String? dayOfBid;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory AuctionBid.fromJson(Map<String, dynamic> json) => AuctionBid(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"]?.toDouble(),
    dayOfBid: json["day_of_bid"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "product_image": productImage,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "day_of_bid": dayOfBid,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class DistinctAuctionBid {
  DistinctAuctionBid({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.amount,
    this.formattedAmount,
    this.dayOfBid,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int? productId;
  String? productName;
  String? productImage;
  double? amount;
  double? formattedAmount;
  String? dayOfBid;
  String? createdAt;
  String? updatedAt;

  factory DistinctAuctionBid.fromJson(Map<String, dynamic> json) => DistinctAuctionBid(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"]?.toDouble(),
    dayOfBid: json["day_of_bid"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "product_image": productImage,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "day_of_bid": dayOfBid,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}