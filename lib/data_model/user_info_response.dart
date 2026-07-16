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

// =============================================
// PAGINATION MODEL
// =============================================
class Pagination {
  int currentPage;
  int perPage;
  int total;
  int totalPages;
  bool hasNext;
  bool hasPrevious;
  int nextPage;
  int previousPage;

  Pagination({
    this.currentPage = 1,
    this.perPage = 10,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.nextPage = 2,
    this.previousPage = 0,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    currentPage: json["current_page"] ?? 1,
    perPage: json["per_page"] ?? 10,
    total: json["total"] ?? 0,
    totalPages: json["total_pages"] ?? 0,
    hasNext: json["has_next"] ?? false,
    hasPrevious: json["has_previous"] ?? false,
    nextPage: json["next_page"] ?? 2,
    previousPage: json["previous_page"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "per_page": perPage,
    "total": total,
    "total_pages": totalPages,
    "has_next": hasNext,
    "has_previous": hasPrevious,
    "next_page": nextPage,
    "previous_page": previousPage,
  };
}

// =============================================
// USER INFORMATION MODEL
// =============================================
class UserInformation {
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
  
  // ============ AFFILIATE LOGS ============
  List<AffiliateLog>? affiliateLogs;
  double? totalAffiliateEarnings;
  
  // Notifications with pagination
  List<Notification>? notifications;
  int? unreadNotificationsCount;
  Pagination? notificationsPagination;
  
  // =============================================
  // ✅ ADDED: Notification category counts
  // =============================================
  int? allNotificationCount;      // Total unread notifications
  int? auctionNotificationCount;  // Unread auction notifications
  int? paymentNotificationCount;  // Unread payment notifications
  int? systemNotificationCount;   // Unread system notifications
  
  // Point history with pagination
  List<PointHistory>? pointHistory;
  int? totalPoints;
  Pagination? pointsPagination;
  
  // Cash earning history with pagination
  List<CashHistory>? cashHistory;
  double? totalCashEarnings;
  Pagination? cashPagination;
  
  // Withdraw requests with pagination
  List<AffiliateWithdrawRequest>? affiliateWithdrawRequests;
  double? totalWithdrawnAmount;
  double? pendingWithdrawAmount;
  Pagination? withdrawPagination;
  
  int? unreadMessagesCount;
  List<Address>? addresses;
  int? addressCount;
  int? defaultAddressCount;
  List<CustomerPackagePayment>? customerPackagePayments;
  double? totalPackagePayments;
  
  // Wishlist with pagination
  List<WishlistItem>? wishlist;
  int? wishlistCount;
  WishlistPagination? wishlistPagination;
  
  // Auction Bids with pagination
  List<AuctionBid>? auctionBids;
  int? auctionBidsCount;
  AuctionBidsPagination? auctionBidsPagination;
  
  // Distinct Auction Bids with pagination
  List<DistinctAuctionBid>? distinctAuctionBids;
  int? distinctAuctionBidsCount;
  DistinctAuctionBidsPagination? distinctAuctionBidsPagination;
  
  // Affiliate Info
  String? affiliateId;
  String? paypalEmail;
  String? bankName;
  String? accountHolder;
  String? accountNumber;
  String? ifscCode;
  double? affiliateBalance;
  int? affiliateStatus;

  // =============================================
  // ✅ NEW: User has bid on product
  // =============================================
  bool? userHasBid;  // true if user has placed any bid on this product

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
    // ============ ADDED ============
    this.affiliateLogs,
    this.totalAffiliateEarnings,
    this.notifications,
    this.unreadNotificationsCount,
    this.notificationsPagination,
    // =============================================
    // ✅ ADDED: Notification category counts
    // =============================================
    this.allNotificationCount,
    this.auctionNotificationCount,
    this.paymentNotificationCount,
    this.systemNotificationCount,
    // =============================================
    this.pointHistory,
    this.totalPoints,
    this.pointsPagination,
    this.cashHistory,
    this.totalCashEarnings,
    this.cashPagination,
    this.affiliateWithdrawRequests,
    this.totalWithdrawnAmount,
    this.pendingWithdrawAmount,
    this.withdrawPagination,
    this.unreadMessagesCount,
    this.addresses,
    this.addressCount,
    this.defaultAddressCount,
    this.customerPackagePayments,
    this.totalPackagePayments,
    this.wishlist,
    this.wishlistCount,
    this.wishlistPagination,
    this.auctionBids,
    this.auctionBidsCount,
    this.auctionBidsPagination,
    this.distinctAuctionBids,
    this.distinctAuctionBidsCount,
    this.distinctAuctionBidsPagination,
    this.affiliateId,
    this.paypalEmail,
    this.bankName,
    this.accountHolder,
    this.accountNumber,
    this.ifscCode,
    this.affiliateBalance,
    this.affiliateStatus,
    // =============================================
    // ✅ NEW: User has bid on product
    // =============================================
    this.userHasBid,
  });

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
    
    // ============ ADDED ============
    affiliateLogs: json["affiliate_logs"] != null
        ? List<AffiliateLog>.from(json["affiliate_logs"].map((x) => AffiliateLog.fromJson(x)))
        : [],
    totalAffiliateEarnings: json["total_affiliate_earnings"]?.toDouble(),
    
    // Notifications
    notifications: json["notifications"] != null 
        ? List<Notification>.from(json["notifications"].map((x) => Notification.fromJson(x)))
        : [],
    unreadNotificationsCount: json["unread_notifications_count"],
    notificationsPagination: json["notifications_pagination"] != null
        ? Pagination.fromJson(json["notifications_pagination"])
        : null,
    
    // =============================================
    // ✅ ADDED: Notification category counts
    // =============================================
    allNotificationCount: json["all"],
    auctionNotificationCount: json["auction"],
    paymentNotificationCount: json["payment"],
    systemNotificationCount: json["system"],
    // =============================================
    
    // Point History
    pointHistory: json["point_history"] != null
        ? List<PointHistory>.from(json["point_history"].map((x) => PointHistory.fromJson(x)))
        : [],
    totalPoints: json["total_points"],
    pointsPagination: json["points_pagination"] != null
        ? Pagination.fromJson(json["points_pagination"])
        : null,
    
    // Cash History
    cashHistory: json["cash_earning_history"] != null
        ? List<CashHistory>.from(json["cash_earning_history"].map((x) => CashHistory.fromJson(x)))
        : [],
    totalCashEarnings: json["total_cash_earnings"]?.toDouble(),
    cashPagination: json["cash_pagination"] != null
        ? Pagination.fromJson(json["cash_pagination"])
        : null,
    
    // Withdraw Requests
    affiliateWithdrawRequests: json["affiliate_withdraw_requests"] != null
        ? List<AffiliateWithdrawRequest>.from(json["affiliate_withdraw_requests"].map((x) => AffiliateWithdrawRequest.fromJson(x)))
        : [],
    totalWithdrawnAmount: json["total_withdrawn_amount"]?.toDouble(),
    pendingWithdrawAmount: json["pending_withdraw_amount"]?.toDouble(),
    withdrawPagination: json["withdraw_pagination"] != null
        ? Pagination.fromJson(json["withdraw_pagination"])
        : null,
    
    unreadMessagesCount: json["unread_messages_count"] ?? 0,
    
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
    
    // =============================================
    // WISHLIST WITH PAGINATION
    // =============================================
    wishlist: json["wishlist"] != null
        ? List<WishlistItem>.from(json["wishlist"].map((x) => WishlistItem.fromJson(x)))
        : [],
    wishlistCount: json["wishlist_count"],
    wishlistPagination: json["wishlist_pagination"] != null
        ? WishlistPagination.fromJson(json["wishlist_pagination"])
        : null,
    
    // =============================================
    // AUCTION BIDS WITH PAGINATION
    // =============================================
    auctionBids: json["auction_bids"] != null
        ? List<AuctionBid>.from(json["auction_bids"].map((x) => AuctionBid.fromJson(x)))
        : [],
    auctionBidsCount: json["auction_bids_count"],
    auctionBidsPagination: json["auction_bids_pagination"] != null
        ? AuctionBidsPagination.fromJson(json["auction_bids_pagination"])
        : null,
    
    // =============================================
    // DISTINCT AUCTION BIDS WITH PAGINATION
    // =============================================
    distinctAuctionBids: json["distinct_auction_bids"] != null
        ? List<DistinctAuctionBid>.from(json["distinct_auction_bids"].map((x) => DistinctAuctionBid.fromJson(x)))
        : [],
    distinctAuctionBidsCount: json["distinct_auction_bids_count"],
    distinctAuctionBidsPagination: json["distinct_auction_bids_pagination"] != null
        ? DistinctAuctionBidsPagination.fromJson(json["distinct_auction_bids_pagination"])
        : null,
    
    // Affiliate Info
    affiliateId: json["affiliate_id"]?.toString(),
    paypalEmail: json["paypal_email"],
    bankName: json["bank_name"],
    accountHolder: json["account_holder"],
    accountNumber: json["account_number"],
    ifscCode: json["ifsc_code"],
    affiliateBalance: json["affiliate_balance"]?.toDouble(),
    affiliateStatus: json["affiliate_status"],
    
    // =============================================
    // ✅ NEW: User has bid on product
    // =============================================
    userHasBid: json["user_has_bid"],
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
    // ============ ADDED ============
    "affiliate_logs": affiliateLogs != null ? List<dynamic>.from(affiliateLogs!.map((x) => x.toJson())) : [],
    "total_affiliate_earnings": totalAffiliateEarnings,
    "notifications": notifications != null ? List<dynamic>.from(notifications!.map((x) => x.toJson())) : [],
    "unread_notifications_count": unreadNotificationsCount,
    "notifications_pagination": notificationsPagination?.toJson(),
    // =============================================
    // ✅ ADDED: Notification category counts
    // =============================================
    "all": allNotificationCount,
    "auction": auctionNotificationCount,
    "payment": paymentNotificationCount,
    "system": systemNotificationCount,
    // =============================================
    "point_history": pointHistory != null ? List<dynamic>.from(pointHistory!.map((x) => x.toJson())) : [],
    "total_points": totalPoints,
    "points_pagination": pointsPagination?.toJson(),
    "cash_earning_history": cashHistory != null ? List<dynamic>.from(cashHistory!.map((x) => x.toJson())) : [],
    "total_cash_earnings": totalCashEarnings,
    "cash_pagination": cashPagination?.toJson(),
    "affiliate_withdraw_requests": affiliateWithdrawRequests != null ? List<dynamic>.from(affiliateWithdrawRequests!.map((x) => x.toJson())) : [],
    "total_withdrawn_amount": totalWithdrawnAmount,
    "pending_withdraw_amount": pendingWithdrawAmount,
    "withdraw_pagination": withdrawPagination?.toJson(),
    "unread_messages_count": unreadMessagesCount,
    "addresses": addresses != null ? List<dynamic>.from(addresses!.map((x) => x.toJson())) : [],
    "address_count": addressCount,
    "default_address_count": defaultAddressCount,
    "customer_package_payments": customerPackagePayments != null ? List<dynamic>.from(customerPackagePayments!.map((x) => x.toJson())) : [],
    "total_package_payments": totalPackagePayments,
    // =============================================
    // WISHLIST WITH PAGINATION
    // =============================================
    "wishlist": wishlist != null ? List<dynamic>.from(wishlist!.map((x) => x.toJson())) : [],
    "wishlist_count": wishlistCount,
    "wishlist_pagination": wishlistPagination?.toJson(),
    // =============================================
    // AUCTION BIDS WITH PAGINATION
    // =============================================
    "auction_bids": auctionBids != null ? List<dynamic>.from(auctionBids!.map((x) => x.toJson())) : [],
    "auction_bids_count": auctionBidsCount,
    "auction_bids_pagination": auctionBidsPagination?.toJson(),
    // =============================================
    // DISTINCT AUCTION BIDS WITH PAGINATION
    // =============================================
    "distinct_auction_bids": distinctAuctionBids != null ? List<dynamic>.from(distinctAuctionBids!.map((x) => x.toJson())) : [],
    "distinct_auction_bids_count": distinctAuctionBidsCount,
    "distinct_auction_bids_pagination": distinctAuctionBidsPagination?.toJson(),
    // Affiliate Info
    "affiliate_id": affiliateId,
    "paypal_email": paypalEmail,
    "bank_name": bankName,
    "account_holder": accountHolder,
    "ifsc_code": ifscCode,
    "account_number": accountNumber,
    "affiliate_balance": affiliateBalance,
    "affiliate_status": affiliateStatus,
    // =============================================
    // ✅ NEW: User has bid on product
    // =============================================
    "user_has_bid": userHasBid,
  };
}

// =============================================
// NOTIFICATION MODEL
// =============================================
class Notification {
  int? id;
  String? type;
  String? title;
  String? message;
  dynamic? readAt;
  DateTime? createdAt;
  bool? isRead;
  
  // =============================================
  // ✅ ADDED: Product ID and Slug for navigation
  // =============================================
  int? productId;
  String? slug;

  Notification({
    this.id,
    this.type,
    this.title,
    this.message,
    this.readAt,
    this.createdAt,
    this.isRead,
    this.productId,
    this.slug,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json["id"],
    type: json["type"],
    title: json["title"],
    message: json["message"],
    readAt: json["read_at"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    isRead: json["read_at"] != null,
    productId: json["product_id"] ?? 0,
    slug: json["slug"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "title": title,
    "message": message,
    "read_at": readAt,
    "created_at": createdAt?.toIso8601String(),
    "is_read": isRead,
    "product_id": productId,
    "slug": slug,
  };
}

// =============================================
// POINT HISTORY MODEL
// =============================================
class PointHistory {
  int? id;
  String? bonusType;
  String? cameFrom;
  int? amount;
  String? formattedAmount;
  int? status;
  dynamic? orderId;
  int? referredByUser;
  DateTime? createdAt;
  bool? isCredit;
  bool? isDebit;

  PointHistory({
    this.id,
    this.bonusType,
    this.cameFrom,
    this.amount,
    this.formattedAmount,
    this.status,
    this.orderId,
    this.referredByUser,
    this.createdAt,
    this.isCredit,
    this.isDebit,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) => PointHistory(
    id: json["id"],
    bonusType: json["bonus_type"],
    cameFrom: json["came_from"],
    amount: json["amount"],
    formattedAmount: json["formatted_amount"],
    status: json["status"],
    orderId: json["order_id"],
    referredByUser: json["referred_by_user"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    isCredit: json["is_credit"] ?? false,
    isDebit: json["is_debit"] ?? false,
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
    "is_credit": isCredit,
    "is_debit": isDebit,
  };
}

// =============================================
// CASH HISTORY MODEL
// =============================================
class CashHistory {
  int? id;
  String? bonusType;
  String? cameFrom;
  double? amount;
  String? formattedAmount;
  int? status;
  dynamic? orderId;
  int? referredByUser;
  DateTime? createdAt;
  bool? isCredit;
  bool? isDebit;

  CashHistory({
    this.id,
    this.bonusType,
    this.cameFrom,
    this.amount,
    this.formattedAmount,
    this.status,
    this.orderId,
    this.referredByUser,
    this.createdAt,
    this.isCredit,
    this.isDebit,
  });

  factory CashHistory.fromJson(Map<String, dynamic> json) => CashHistory(
    id: json["id"],
    bonusType: json["bonus_type"],
    cameFrom: json["came_from"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
    status: json["status"],
    orderId: json["order_id"],
    referredByUser: json["referred_by_user"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    isCredit: json["is_credit"] ?? false,
    isDebit: json["is_debit"] ?? false,
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
    "is_credit": isCredit,
    "is_debit": isDebit,
  };
}

// =============================================
// AFFILIATE LOG MODEL
// =============================================
class AffiliateLog {
  int? id;
  String? bonusType;
  String? cameFrom;
  double? amount;
  String? formattedAmount;
  int? status;
  dynamic? orderId;
  int? referredByUser;
  DateTime? createdAt;

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

  factory AffiliateLog.fromJson(Map<String, dynamic> json) => AffiliateLog(
    id: json["id"],
    bonusType: json["bonus_type"],
    cameFrom: json["came_from"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
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

// =============================================
// AFFILIATE WITHDRAW REQUEST MODEL
// =============================================
class AffiliateWithdrawRequest {
  int? id;
  double? amount;
  String? formattedAmount;
  int? status;
  String? statusLabel;
  DateTime? createdAt;
  DateTime? updatedAt;

  AffiliateWithdrawRequest({
    this.id,
    this.amount,
    this.formattedAmount,
    this.status,
    this.statusLabel,
    this.createdAt,
    this.updatedAt,
  });

  factory AffiliateWithdrawRequest.fromJson(Map<String, dynamic> json) => AffiliateWithdrawRequest(
    id: json["id"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
    status: json["status"],
    statusLabel: json["status_label"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "status": status,
    "status_label": statusLabel,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

// =============================================
// ADDRESS MODEL
// =============================================
class Address {
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

// =============================================
// CUSTOMER PACKAGE PAYMENT MODEL
// =============================================
class CustomerPackagePayment {
  int? id;
  int? customerPackageId;
  String? packageName;
  String? paymentMethod;
  double? amount;
  String? formattedAmount;
  PaymentDetails? paymentDetails;
  int? approval;
  int? offlinePayment;
  dynamic? reciept;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

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

  factory CustomerPackagePayment.fromJson(Map<String, dynamic> json) => CustomerPackagePayment(
    id: json["id"],
    customerPackageId: json["customer_package_id"],
    packageName: json["package_name"],
    paymentMethod: json["payment_method"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
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

// =============================================
// WISHLIST MODEL WITH PAGINATION
// =============================================
class WishlistItem {
  int? id;
  int? productId;
  String? productName;
  String? productImage;
  double? productPrice;
  double? highestBid;
  double? userBidAmount;
  int? pointPerBid;
  String? slug;
  bool? isAuction;
  String? auctionEndDate;
  bool? isLive;
  bool? endingSoon;
  bool? outbid;
  bool? isWinning;
  DateTime? createdAt;
  DateTime? updatedAt;

  WishlistItem({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.highestBid,
    this.userBidAmount,
    this.pointPerBid,
    this.slug,
    this.isAuction,
    this.auctionEndDate,
    this.isLive,
    this.endingSoon,
    this.outbid,
    this.isWinning,
    this.createdAt,
    this.updatedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    productPrice: json["product_price"]?.toDouble(),
    highestBid: json["highest_bid"]?.toDouble(),
    userBidAmount: json["user_bid_amount"]?.toDouble(),
    pointPerBid: json["point_per_bid"],
    slug: json["slug"],
    isAuction: json["is_auction"] ?? false,
    auctionEndDate: json["auction_end_date"] != null ? json["auction_end_date"].toString() : null,
    isLive: json["is_live"] ?? false,
    endingSoon: json["ending_soon"] ?? false,
    outbid: json["outbid"] ?? false,
    isWinning: json["is_winning"] ?? false,
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
    "user_bid_amount": userBidAmount,
    "point_per_bid": pointPerBid,
    "slug": slug,
    "is_auction": isAuction,
    "auction_end_date": auctionEndDate,
    "is_live": isLive,
    "ending_soon": endingSoon,
    "outbid": outbid,
    "is_winning": isWinning,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

// =============================================
// WISHLIST PAGINATION
// =============================================
class WishlistPagination {
  int currentPage;
  int perPage;
  int total;
  int totalPages;
  bool hasNext;
  bool hasPrevious;
  int nextPage;
  int previousPage;

  WishlistPagination({
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.nextPage = 0,
    this.previousPage = 0,
  });

  factory WishlistPagination.fromJson(Map<String, dynamic> json) => WishlistPagination(
    currentPage: json["current_page"] ?? 1,
    perPage: json["per_page"] ?? 20,
    total: json["total"] ?? 0,
    totalPages: json["total_pages"] ?? 0,
    hasNext: json["has_next"] ?? false,
    hasPrevious: json["has_previous"] ?? false,
    nextPage: json["next_page"] ?? 0,
    previousPage: json["previous_page"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "per_page": perPage,
    "total": total,
    "total_pages": totalPages,
    "has_next": hasNext,
    "has_previous": hasPrevious,
    "next_page": nextPage,
    "previous_page": previousPage,
  };
}

// =============================================
// AUCTION BID MODEL WITH PAGINATION
// =============================================
class AuctionBid {
  int? id;
  int? productId;
  String? productName;
  String? productImage;
  String? productSlug;
  double? amount;
  String? formattedAmount;
  String? dayOfBid;
  int? pointPerBid;
  String? auctionEndDate;
  double? highestBid;
  bool? isWinning;
  bool? highestBidder;
  bool? recentlyEnded;
  // =============================================
  // ✅ NEW FIELDS
  // =============================================
  int? activityStatus;
  String? payLink;
  DateTime? createdAt;
  DateTime? updatedAt;

  AuctionBid({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.productSlug,
    this.amount,
    this.formattedAmount,
    this.dayOfBid,
    this.pointPerBid,
    this.auctionEndDate,
    this.highestBid,
    this.isWinning,
    this.highestBidder,
    this.recentlyEnded,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    this.activityStatus,
    this.payLink,
    this.createdAt,
    this.updatedAt,
  });

  factory AuctionBid.fromJson(Map<String, dynamic> json) => AuctionBid(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    productSlug: json["product_slug"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
    dayOfBid: json["day_of_bid"],
    pointPerBid: json["point_per_bid"],
    auctionEndDate: json["auction_end_date"] != null ? json["auction_end_date"].toString() : null,
    highestBid: json["highest_bid"]?.toDouble(),
    isWinning: json["is_winning"] ?? false,
    highestBidder: json["highest_biddder"] ?? false,
    recentlyEnded: json["recently_ended"] ?? false,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    activityStatus: json["activity_status"],
    payLink: json["pay_link"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "product_image": productImage,
    "product_slug": productSlug,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "day_of_bid": dayOfBid,
    "point_per_bid": pointPerBid,
    "auction_end_date": auctionEndDate,
    "highest_bid": highestBid,
    "is_winning": isWinning,
    "highest_biddder": highestBidder,
    "recently_ended": recentlyEnded,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    "activity_status": activityStatus,
    "pay_link": payLink,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

// =============================================
// AUCTION BIDS PAGINATION
// =============================================
class AuctionBidsPagination {
  int currentPage;
  int perPage;
  int total;
  int totalPages;
  bool hasNext;
  bool hasPrevious;
  int nextPage;
  int previousPage;

  AuctionBidsPagination({
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.nextPage = 0,
    this.previousPage = 0,
  });

  factory AuctionBidsPagination.fromJson(Map<String, dynamic> json) => AuctionBidsPagination(
    currentPage: json["current_page"] ?? 1,
    perPage: json["per_page"] ?? 20,
    total: json["total"] ?? 0,
    totalPages: json["total_pages"] ?? 0,
    hasNext: json["has_next"] ?? false,
    hasPrevious: json["has_previous"] ?? false,
    nextPage: json["next_page"] ?? 0,
    previousPage: json["previous_page"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "per_page": perPage,
    "total": total,
    "total_pages": totalPages,
    "has_next": hasNext,
    "has_previous": hasPrevious,
    "next_page": nextPage,
    "previous_page": previousPage,
  };
}

// =============================================
// DISTINCT AUCTION BID MODEL WITH PAGINATION
// =============================================
class DistinctAuctionBid {
  int? id;
  int? productId;
  String? productName;
  String? productImage;
  String? productSlug;
  double? amount;
  String? formattedAmount;
  String? dayOfBid;
  String? auctionEndDate;
  double? highestBid;
  bool? isWinning;
  bool? highestBidder;
  bool? recentlyEnded;
  // =============================================
  // ✅ NEW FIELDS
  // =============================================
  int? activityStatus;
  String? payLink;
  String? createdAt;
  String? updatedAt;

  DistinctAuctionBid({
    this.id,
    this.productId,
    this.productName,
    this.productImage,
    this.productSlug,
    this.amount,
    this.formattedAmount,
    this.dayOfBid,
    this.auctionEndDate,
    this.highestBid,
    this.isWinning,
    this.highestBidder,
    this.recentlyEnded,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    this.activityStatus,
    this.payLink,
    this.createdAt,
    this.updatedAt,
  });

  factory DistinctAuctionBid.fromJson(Map<String, dynamic> json) => DistinctAuctionBid(
    id: json["id"],
    productId: json["product_id"],
    productName: json["product_name"],
    productImage: json["product_image"],
    productSlug: json["product_slug"],
    amount: json["amount"]?.toDouble(),
    formattedAmount: json["formatted_amount"],
    dayOfBid: json["day_of_bid"],
    auctionEndDate: json["auction_end_date"]?.toString(),
    highestBid: json["highest_bid"]?.toDouble(),
    isWinning: json["is_winning"] ?? false,
    highestBidder: json["highest_bidder"] ?? false,
    recentlyEnded: json["recently_ended"] ?? false,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    activityStatus: json["activity_status"],
    payLink: json["pay_link"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "product_image": productImage,
    "product_slug": productSlug,
    "amount": amount,
    "formatted_amount": formattedAmount,
    "day_of_bid": dayOfBid,
    "auction_end_date": auctionEndDate,
    "highest_bid": highestBid,
    "is_winning": isWinning,
    "highest_bidder": highestBidder,
    "recently_ended": recentlyEnded,
    // =============================================
    // ✅ NEW FIELDS
    // =============================================
    "activity_status": activityStatus,
    "pay_link": payLink,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}

// =============================================
// DISTINCT AUCTION BIDS PAGINATION
// =============================================
class DistinctAuctionBidsPagination {
  int currentPage;
  int perPage;
  int total;
  int totalPages;
  bool hasNext;
  bool hasPrevious;
  int nextPage;
  int previousPage;

  DistinctAuctionBidsPagination({
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.nextPage = 0,
    this.previousPage = 0,
  });

  factory DistinctAuctionBidsPagination.fromJson(Map<String, dynamic> json) => DistinctAuctionBidsPagination(
    currentPage: json["current_page"] ?? 1,
    perPage: json["per_page"] ?? 20,
    total: json["total"] ?? 0,
    totalPages: json["total_pages"] ?? 0,
    hasNext: json["has_next"] ?? false,
    hasPrevious: json["has_previous"] ?? false,
    nextPage: json["next_page"] ?? 0,
    previousPage: json["previous_page"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "per_page": perPage,
    "total": total,
    "total_pages": totalPages,
    "has_next": hasNext,
    "has_previous": hasPrevious,
    "next_page": nextPage,
    "previous_page": previousPage,
  };
}

// =============================================
// WISHLIST PAGINATED RESPONSE WRAPPER (TOP-LEVEL)
// =============================================
class WishlistPaginatedResponse {
  bool success;
  List<WishlistItem> data;
  WishlistPagination pagination;
  int wishlistCount;

  WishlistPaginatedResponse({
    required this.success,
    required this.data,
    required this.pagination,
    required this.wishlistCount,
  });

  factory WishlistPaginatedResponse.fromJson(Map<String, dynamic> json) => WishlistPaginatedResponse(
    success: json["success"] ?? true,
    data: json["wishlist"] != null 
        ? List<WishlistItem>.from(json["wishlist"].map((x) => WishlistItem.fromJson(x)))
        : [],
    pagination: json["wishlist_pagination"] != null
        ? WishlistPagination.fromJson(json["wishlist_pagination"])
        : WishlistPagination(currentPage: 1, perPage: 20, total: 0),
    wishlistCount: json["wishlist_count"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "wishlist": data.map((x) => x.toJson()).toList(),
    "wishlist_pagination": pagination.toJson(),
    "wishlist_count": wishlistCount,
  };
}

// =============================================
// AUCTION BIDS PAGINATED RESPONSE WRAPPER (TOP-LEVEL)
// =============================================
class AuctionBidsPaginatedResponse {
  bool success;
  List<AuctionBid> data;
  AuctionBidsPagination pagination;
  int auctionBidsCount;

  AuctionBidsPaginatedResponse({
    required this.success,
    required this.data,
    required this.pagination,
    required this.auctionBidsCount,
  });

  factory AuctionBidsPaginatedResponse.fromJson(Map<String, dynamic> json) => AuctionBidsPaginatedResponse(
    success: json["success"] ?? true,
    data: json["auction_bids"] != null 
        ? List<AuctionBid>.from(json["auction_bids"].map((x) => AuctionBid.fromJson(x)))
        : [],
    pagination: json["auction_bids_pagination"] != null
        ? AuctionBidsPagination.fromJson(json["auction_bids_pagination"])
        : AuctionBidsPagination(currentPage: 1, perPage: 20, total: 0),
    auctionBidsCount: json["auction_bids_count"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "auction_bids": data.map((x) => x.toJson()).toList(),
    "auction_bids_pagination": pagination.toJson(),
    "auction_bids_count": auctionBidsCount,
  };
}

// =============================================
// DISTINCT AUCTION BIDS PAGINATED RESPONSE WRAPPER (TOP-LEVEL)
// =============================================
class DistinctAuctionBidsPaginatedResponse {
  bool success;
  List<DistinctAuctionBid> data;
  DistinctAuctionBidsPagination pagination;
  int distinctAuctionBidsCount;

  DistinctAuctionBidsPaginatedResponse({
    required this.success,
    required this.data,
    required this.pagination,
    required this.distinctAuctionBidsCount,
  });

  factory DistinctAuctionBidsPaginatedResponse.fromJson(Map<String, dynamic> json) => DistinctAuctionBidsPaginatedResponse(
    success: json["success"] ?? true,
    data: json["distinct_auction_bids"] != null 
        ? List<DistinctAuctionBid>.from(json["distinct_auction_bids"].map((x) => DistinctAuctionBid.fromJson(x)))
        : [],
    pagination: json["distinct_auction_bids_pagination"] != null
        ? DistinctAuctionBidsPagination.fromJson(json["distinct_auction_bids_pagination"])
        : DistinctAuctionBidsPagination(currentPage: 1, perPage: 20, total: 0),
    distinctAuctionBidsCount: json["distinct_auction_bids_count"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "distinct_auction_bids": data.map((x) => x.toJson()).toList(),
    "distinct_auction_bids_pagination": pagination.toJson(),
    "distinct_auction_bids_count": distinctAuctionBidsCount,
  };
}