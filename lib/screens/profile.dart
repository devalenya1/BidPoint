import 'dart:async';
import 'dart:convert';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/repositories/api-request.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/address.dart';
import 'package:active_ecommerce_flutter/screens/change_language.dart';
import 'package:active_ecommerce_flutter/screens/classified_ads/classified_ads.dart';
import 'package:active_ecommerce_flutter/screens/classified_ads/my_classified_ads.dart';
import 'package:active_ecommerce_flutter/screens/club_point.dart';
import 'package:active_ecommerce_flutter/screens/coupons.dart';
import 'package:active_ecommerce_flutter/screens/currency_change.dart';
import 'package:active_ecommerce_flutter/screens/digital_product/digital_products.dart';
import 'package:active_ecommerce_flutter/screens/digital_product/purchased_digital_produts.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/screens/followed_sellers.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:active_ecommerce_flutter/screens/order_list.dart';
import 'package:active_ecommerce_flutter/screens/profile_edit.dart';
import 'package:active_ecommerce_flutter/screens/refund_request.dart';
import 'package:active_ecommerce_flutter/screens/top_selling_products.dart';
import 'package:active_ecommerce_flutter/screens/uploads/upload_file.dart';
import 'package:active_ecommerce_flutter/screens/wallet.dart';
import 'package:active_ecommerce_flutter/screens/wishlist.dart';
import 'package:active_ecommerce_flutter/screens/notification_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../repositories/auth_repository.dart';
import '../data_model/user_info_response.dart';
import 'auction_purchase_history.dart';
import 'coming_soon_page.dart';
import 'invite_history_page.dart';
import 'payment_settings_page.dart';
import 'terms_conditions_page.dart';
import 'package:flutter/services.dart';

class Profile extends StatefulWidget {
  Profile({Key? key, this.show_back_button = false}) : super(key: key);

  bool show_back_button;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _mainScrollController = ScrollController();
  bool _pointsVisible = true;
  
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  UserInformation? _userInfo;
  
  // ============ COUNTERS ============
  int? _cartCounter = 0;
  String _cartCounterString = "00";
  int? _wishlistCounter = 0;
  String _wishlistCounterString = "00";
  int? _orderCounter = 0;
  String _orderCounterString = "00";
  late BuildContext loadingcontext;
  bool _auctionExpand = false;
  
  // ============ INIT ============
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      fetchAll();
    } else {
      _loadFromSharedPreferences();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  // ============ FETCH ALL DATA ============
  fetchAll() {
    fetchCounters();
    _fetchUserData();
  }

  // ============ FETCH USER DATA ============
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        if (_userInfo != null) {
          user_name.$ = _userInfo!.name ?? "";
          user_name.save();
          user_email.$ = _userInfo!.email ?? "";
          user_email.save();
          user_phone.$ = _userInfo!.phone ?? "";
          user_phone.save();
          avatar_original.$ = _userInfo!.avatar ?? "";
          avatar_original.save();
          points_balance.$ = _userInfo!.balance?.toString() ?? "0";
          points_balance.save();
          affiliate_balance.$ = _userInfo!.affiliateBalance?.toString() ?? "0";
          affiliate_balance.save();
        }
      } else {
        _loadFromSharedPreferences();
      }
    } catch (e) {
      print("Error loading user data: $e");
      _loadFromSharedPreferences();
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  void _loadFromSharedPreferences() {
    setState(() {
      _userInfo = UserInformation(
        name: user_name.$ ?? "",
        email: user_email.$ ?? "",
        phone: user_phone.$ ?? "",
        avatar: avatar_original.$ ?? "",
        balance: double.tryParse(points_balance.$ ?? "0") ?? 0.0,
        affiliateBalance: double.tryParse(affiliate_balance.$ ?? "0") ?? 0.0,
      );
    });
  }

  // ============ FETCH COUNTERS ============
  fetchCounters() async {
    var profileCountersResponse = await ProfileRepository().getProfileCountersResponse();

    _cartCounter = profileCountersResponse.cart_item_count;
    _wishlistCounter = profileCountersResponse.wishlist_item_count;
    _orderCounter = profileCountersResponse.order_count;

    _cartCounterString = counterText(_cartCounter.toString(), default_length: 2);
    _wishlistCounterString = counterText(_wishlistCounter.toString(), default_length: 2);
    _orderCounterString = counterText(_orderCounter.toString(), default_length: 2);

    setState(() {});
  }

  // ============ COUNTER TEXT HELPER ============
  String counterText(String txt, {default_length = 3}) {
    var blank_zeros = default_length == 3 ? "000" : "00";
    var leading_zeros = "";
    if (default_length == 3 && txt.length == 1) {
      leading_zeros = "00";
    } else if (default_length == 3 && txt.length == 2) {
      leading_zeros = "0";
    } else if (default_length == 2 && txt.length == 1) {
      leading_zeros = "0";
    }

    var newtxt = (txt == "" || txt == null.toString()) ? blank_zeros : txt;

    if (default_length > txt.length) {
      newtxt = leading_zeros + newtxt;
    }

    return newtxt;
  }

  // ============ RESET ============
  reset() {
    _cartCounter = 0;
    _cartCounterString = "00";
    _wishlistCounter = 0;
    _wishlistCounterString = "00";
    _orderCounter = 0;
    _orderCounterString = "00";
    setState(() {});
  }

  // ============ DELETE ACCOUNT ============
  deleteAccountReq() async {
    loading();
    var response = await AuthRepository().getAccountDeleteResponse();

    if (response.result) {
      AuthHelper().clearUserData();
      Navigator.pop(loadingcontext);
      context.go("/");
    }
    ToastComponent.showDialog(response.message);
  }

  // ============ LOADING DIALOG ============
  loading() {
    showDialog(
        context: context,
        builder: (context) {
          loadingcontext = context;
          return AlertDialog(
              content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(
                width: 10,
              ),
              Text("${AppLocalizations.of(context)!.please_wait_ucf}"),
            ],
          ));
        });
  }

  // ============ DELETE WARNING DIALOG ============
  deleteWarningDialog() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                LangText(context).local.delete_account_warning_title,
                style: TextStyle(fontSize: 15, color: MyTheme.dark_font_grey),
              ),
              content: Text(
                LangText(context).local.delete_account_warning_description,
                style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      pop(context);
                    },
                    child: Text(LangText(context).local.no_ucf)),
                TextButton(
                    onPressed: () {
                      pop(context);
                      deleteAccountReq();
                    },
                    child: Text(LangText(context).local.yes_ucf))
              ],
            ));
  }

  void pop(BuildContext context) {
    Navigator.pop(context);
  }

  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  // ============ NAVIGATION ============
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go("/");
    }
  }

  void _togglePointsVisibility() {
    setState(() {
      _pointsVisible = !_pointsVisible;
    });
  }

  // ============ LOGOUT - EXACTLY MATCHING ORIGINAL ============
  void _onTapLogout(BuildContext context) async {
    // Show confirmation dialog matching original style
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.logout_ucf,
          style: TextStyle(fontSize: 15, color: MyTheme.dark_font_grey),
        ),
        content: Text(
          AppLocalizations.of(context)!.are_you_sure_you_want_to_sign_out,
          style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.no_ucf,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ✅ EXACTLY MATCHING ORIGINAL LOGOUT FLOW
              AuthHelper().clearUserData();
              context.go("/");
            },
            child: Text(
              AppLocalizations.of(context)!.yes_ucf,
            ),
          )
        ],
      ),
    );
  }

  // ============ SHOW LOGIN WARNING ============
  void _showLoginWarning() {
    ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
      gravity: ToastGravity.CENTER,
      duration: Toast.LENGTH_LONG,
    );
  }

  // ============ BUILD METHODS ============
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.profile_ucf,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            // Debug icon - only visible in debug mode
            if (kDebugMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.bug_report, color: Colors.orange),
                onSelected: (value) {
                  if (value == 'debug_api') {
                    _debugShowApiResponse();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'debug_api',
                    child: Row(
                      children: [
                        Icon(Icons.api, size: 18),
                        SizedBox(width: 8),
                        Text('Debug API Response'),
                      ],
                    ),
                  ),
                ],
              ),
            // Logout button - only show when logged in
            if (is_logged_in.$)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                  onPressed: () => _onTapLogout(context),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () {
                    context.push("/users/login");
                  },
                  child: Text(
                    AppLocalizations.of(context)!.login_ucf,
                    style: const TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? _buildShimmer()
            : RefreshIndicator(
                color: MyTheme.accent_color,
                backgroundColor: Colors.white,
                onRefresh: _onPageRefresh,
                child: _buildBody(),
              ),
      ),
    );
  }

  // ============ SHIMMER LOADING ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      ShimmerHelper().buildBasicShimmer(height: 45, width: 45, radius: 45),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerHelper().buildBasicShimmer(height: 16, width: 120),
                            const SizedBox(height: 8),
                            ShimmerHelper().buildBasicShimmer(height: 12, width: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ShimmerHelper().buildBasicShimmer(height: 50, width: 80, radius: 20),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(6, (index) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerHelper().buildBasicShimmer(height: 60, radius: 16),
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============ BODY ============
  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 27),
      child: Column(
        children: [
          _buildProfileCard(),
          _buildCountersRow(),
          _buildHorizontalSettings(),
          _buildSettingAndAddonsHorizontalMenu(),
          _buildBottomVerticalCardList(),
        ],
      ),
    );
  }
  
  // ============ PROFILE CARD ============
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _userInfo?.avatar != null && _userInfo!.avatar!.isNotEmpty
                        ? Image.network(
                            _userInfo!.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userInfo?.name?.isNotEmpty == true ? _userInfo!.name! : AppLocalizations.of(context)!.guest_user,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.referral_earnings} ${FormatHelper.formatPrice(_userInfo?.affiliateBalance ?? 0.0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.referral_point,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: _togglePointsVisibility,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _pointsVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _pointsVisible 
                          ? (_userInfo?.balance?.toInt() ?? 0).toString() 
                          : '****',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.points_ucf,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ COUNTERS ROW ============
  Widget _buildCountersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCountersRowItem(
            _cartCounterString,
            AppLocalizations.of(context)!.in_your_cart_all_lower,
          ),
          _buildCountersRowItem(
            _wishlistCounterString,
            AppLocalizations.of(context)!.in_your_wishlist_all_lower,
          ),
          _buildCountersRowItem(
            _orderCounterString,
            AppLocalizations.of(context)!.your_ordered_all_lower,
          ),
        ],
      ),
    );
  }

  Widget _buildCountersRowItem(String counter, String title) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.symmetric(vertical: 14),
      width: DeviceInfo(context).width! / 3.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: MyTheme.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            counter,
            maxLines: 2,
            style: TextStyle(
                fontSize: 18,
                color: MyTheme.dark_font_grey,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            title,
            maxLines: 2,
            style: TextStyle(
              color: Color(0xff3E4447),
            ),
          ),
        ],
      ),
    );
  }

  // ============ HORIZONTAL SETTINGS ============
  Widget _buildHorizontalSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        margin: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHorizontalSettingItem(true, "assets/language.png",
                AppLocalizations.of(context)!.language_ucf, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ChangeLanguage();
                  },
                ),
              );
            }),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CurrencyChange();
                }));
              },
              child: Column(
                children: [
                  Image.asset(
                    "assets/currency.png",
                    height: 16,
                    width: 16,
                    color: MyTheme.accent_color,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    AppLocalizations.of(context)!.currency_ucf,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
            _buildHorizontalSettingItem(
                is_logged_in.$,
                "assets/edit.png",
                AppLocalizations.of(context)!.edit_profile_ucf,
                is_logged_in.$
                    ? () {
                        AIZRoute.push(context, ProfileEdit()).then((value) {
                          //onPopped(value);
                        });
                      }
                    : () => _showLoginWarning()),
            _buildHorizontalSettingItem(
                is_logged_in.$,
                "assets/location.png",
                AppLocalizations.of(context)!.address_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return Address();
                            },
                          ),
                        );
                      }
                    : () => _showLoginWarning()),
          ],
        ),
      ),
    );
  }

  InkWell _buildHorizontalSettingItem(
      bool isLogin, String img, String text, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(
            img,
            height: 16,
            width: 16,
            color: isLogin ? MyTheme.accent_color : MyTheme.blue_grey,
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: isLogin ? MyTheme.accent_color : MyTheme.blue_grey,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  // ============ SETTING AND ADDONS HORIZONTAL MENU ============
  Widget _buildSettingAndAddonsHorizontalMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 25),
        margin: EdgeInsets.only(top: 14),
        width: DeviceInfo(context).width,
        height: 208,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(6)),
        child: GridView(
          scrollDirection: Axis.horizontal,
          physics: const PageScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 50.0,
            crossAxisSpacing: 0.0,
            crossAxisCount: 3,
          ),
          shrinkWrap: true,
          cacheExtent: 5.0,
          children: [
            if (wallet_system_status.$)
              Container(
                child: _buildSettingAndAddonsHorizontalMenuItem(
                    "assets/wallet.png",
                    AppLocalizations.of(context)!.my_wallet_ucf, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Wallet()));
                }),
              ),
            _buildSettingAndAddonsHorizontalMenuItem(
                "assets/orders.png",
                AppLocalizations.of(context)!.orders_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => OrderList()));
                      }
                    : () => null),
            _buildSettingAndAddonsHorizontalMenuItem(
                "assets/heart.png",
                AppLocalizations.of(context)!.my_wishlist_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => Wishlist()));
                      }
                    : () => null),
            if (club_point_addon_installed.$)
              _buildSettingAndAddonsHorizontalMenuItem(
                  "assets/points.png",
                  AppLocalizations.of(context)!.club_point_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => Clubpoint()));
                        }
                      : () => null),
            _buildSettingAndAddonsHorizontalMenuItem(
                "assets/notification.png",
                "Notifications",
                is_logged_in.$
                    ? () {
                        Navigator.push(context,
                                MaterialPageRoute(builder: (context) => NotificationSettingsPage()))
                            .then((value) {
                          onPopped(value);
                        });
                      }
                    : () => null),
            if (refund_addon_installed.$)
              _buildSettingAndAddonsHorizontalMenuItem(
                  "assets/refund.png",
                  AppLocalizations.of(context)!.refund_requests_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => RefundRequest()));
                        }
                      : () => null),
            if (conversation_system_status.$)
              _buildSettingAndAddonsHorizontalMenuItem(
                  "assets/messages.png",
                  AppLocalizations.of(context)!.messages_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => MessengerList()));
                        }
                      : () => null),
            if (classified_product_status.$)
              _buildSettingAndAddonsHorizontalMenuItem(
                  "assets/classified_product.png",
                  AppLocalizations.of(context)!.classified_products,
                  is_logged_in.$
                      ? () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => MyClassifiedAds()));
                        }
                      : () => null),
            _buildSettingAndAddonsHorizontalMenuItem(
                "assets/download.png",
                AppLocalizations.of(context)!.downloads_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => PurchasedDigitalProducts()));
                      }
                    : () => null),
            _buildSettingAndAddonsHorizontalMenuItem(
                "assets/upload.png",
                "Upload file",
                is_logged_in.$
                    ? () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => UploadFile()));
                      }
                    : () => null),
          ],
        ),
      ),
    );
  }

  Container _buildSettingAndAddonsHorizontalMenuItem(
      String img, String text, Function() onTap) {
    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: is_logged_in.$
            ? onTap
            : () {
                _showLoginWarning();
              },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              img,
              width: 16,
              height: 16,
              color: is_logged_in.$
                  ? MyTheme.dark_font_grey
                  : MyTheme.medium_grey_50,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                  color: is_logged_in.$
                      ? MyTheme.dark_font_grey
                      : MyTheme.medium_grey_50,
                  fontSize: 11.5),
            )
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM VERTICAL CARD LIST ============
  Widget _buildBottomVerticalCardList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        margin: EdgeInsets.only(bottom: 120, top: 14),
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Column(
          children: [
            if (false)
              // ignore: dead_code
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomVerticalCardListItem(
                      "assets/coupon.png", LangText(context).local.coupons_ucf,
                      onPressed: () {}),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                  _buildBottomVerticalCardListItem("assets/favoriteseller.png",
                      LangText(context).local.favorite_seller_ucf,
                      onPressed: () {}),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBottomVerticalCardListItem("assets/products.png",
                    LangText(context).local.top_selling_products_ucf,
                    onPressed: () {
                  AIZRoute.push(context, TopSellingProducts());
                }),
                Divider(
                  thickness: 1,
                  color: MyTheme.light_grey,
                ),
              ],
            ),
            if (whole_sale_addon_installed.$)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomVerticalCardListItem(
                      "assets/wholesale.png", 'Wholesale', onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ComingSoonPage()));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBottomVerticalCardListItem("assets/blog.png", 'Blog List',
                    onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ComingSoonPage()));
                }),
                Divider(
                  thickness: 1,
                  color: MyTheme.light_grey,
                ),
              ],
            ),
            _buildBottomVerticalCardListItem("assets/download.png",
                LangText(context).local.all_digital_products_ucf, onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return DigitalProducts();
              }));
            }),
            Divider(
              thickness: 1,
              color: MyTheme.light_grey,
            ),
            _buildBottomVerticalCardListItem(
                "assets/coupon.png", LangText(context).local.coupons_ucf,
                onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Coupons();
              }));
            }),
            Divider(
              thickness: 1,
              color: MyTheme.light_grey,
            ),
            if (classified_product_status.$)
              Column(
                children: [
                  _buildBottomVerticalCardListItem(
                      "assets/my_clissified.png", 'My Classified Ads',
                      onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return MyClassifiedAds();
                    }));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (classified_product_status.$)
              Column(
                children: [
                  _buildBottomVerticalCardListItem(
                      "assets/classified_product.png", 'All Classified Ads',
                      onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return ClassifiedAds();
                    }));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (last_viewed_product_status.$ && is_logged_in.$)
              Column(
                children: [
                  _buildBottomVerticalCardListItem("assets/last_view_product.png",
                      LangText(context).local.last_view_product_ucf,
                      onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return ComingSoonPage();
                    }));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (auction_addon_installed.$)
              Column(
                children: [
                  Container(
                    height: _auctionExpand
                        ? is_logged_in.$
                            ? 140
                            : 77
                        : 40,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 10.0),
                    child: InkWell(
                      onTap: () {
                        _auctionExpand = !_auctionExpand;
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 24.0),
                                    child: Image.asset(
                                      "assets/auction.png",
                                      height: 16,
                                      width: 16,
                                      color: MyTheme.dark_font_grey,
                                    ),
                                  ),
                                  Text(
                                    LangText(context).local.auction_ucf,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: MyTheme.dark_font_grey),
                                  ),
                                ],
                              ),
                              Icon(
                                _auctionExpand
                                    ? Icons.keyboard_arrow_down
                                    : Icons.navigate_next_rounded,
                                size: 20,
                                color: MyTheme.dark_font_grey,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Visibility(
                            visible: _auctionExpand,
                            child: Container(
                              padding: const EdgeInsets.only(left: 40),
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => OneContext().push(
                                      MaterialPageRoute(
                                        builder: (_) => ComingSoonPage(),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '-',
                                          style: TextStyle(
                                            color: MyTheme.dark_font_grey,
                                          ),
                                        ),
                                        Text(
                                          " ${LangText(context).local.on_auction_products_ucf}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: MyTheme.dark_font_grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  if (is_logged_in.$)
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () => OneContext().push(
                                            MaterialPageRoute(
                                              builder: (_) => ComingSoonPage(),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '-',
                                                style: TextStyle(
                                                  color: MyTheme.dark_font_grey,
                                                ),
                                              ),
                                              Text(
                                                " ${LangText(context).local.bidded_products_ucf}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: MyTheme.dark_font_grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        GestureDetector(
                                          onTap: () => OneContext().push(
                                            MaterialPageRoute(
                                              builder: (_) => AuctionPurchaseHistory(),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '-',
                                                style: TextStyle(
                                                  color: MyTheme.dark_font_grey,
                                                ),
                                              ),
                                              Text(
                                                " ${LangText(context).local.purchase_history_ucf}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: MyTheme.dark_font_grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (vendor_system.$)
              Column(
                children: [
                  _buildBottomVerticalCardListItem("assets/shop.png",
                      LangText(context).local.browse_all_sellers_ucf,
                      onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return Filter(
                        selected_filter: "sellers",
                      );
                    }));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (is_logged_in.$ && (vendor_system.$))
              Column(
                children: [
                  _buildBottomVerticalCardListItem("assets/follow_seller.png",
                      LangText(context).local.followed_sellers_ucf,
                      onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return FollowedSellers();
                    }));
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
            if (is_logged_in.$)
              Column(
                children: [
                  _buildBottomVerticalCardListItem("assets/delete.png",
                      LangText(context).local.delete_my_account, onPressed: () {
                    deleteWarningDialog();
                  }),
                  Divider(
                    thickness: 1,
                    color: MyTheme.light_grey,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Container _buildBottomVerticalCardListItem(String img, String label,
      {Function()? onPressed, bool isDisable = false}) {
    return Container(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            alignment: Alignment.center,
            padding: EdgeInsets.zero),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Image.asset(
                img,
                height: 16,
                width: 16,
                color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============ DEBUG METHODS ============
  Future<void> _debugShowApiResponse() async {
    if (!kDebugMode) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      String url = "${AppConfig.BASE_URL}/customer/info";
      String token = access_token.$ ?? "";
      String appLanguage = app_language.$!;
      
      final startTime = DateTime.now();
      
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Authorization": "Bearer $token", 
          "App-Language": appLanguage
        },
      );
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                response.statusCode == 200 ? Icons.check_circle : Icons.error,
                color: response.statusCode == 200 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              const Text('API Debug Info'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 550),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "✅ REACHED SERVER - Response received in ${responseTime}ms",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: response.statusCode == 200 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              response.statusCode == 200 ? Icons.check_circle : Icons.error,
                              size: 16,
                              color: response.statusCode == 200 ? Colors.green[800] : Colors.red[800],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Status Code: ${response.statusCode}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: response.statusCode == 200 ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          response.statusCode == 200 
                              ? "✅ Success - API responded correctly"
                              : response.statusCode == 401 
                                  ? "🔐 Unauthorized - Token may be expired. Try logging out and back in."
                                  : response.statusCode == 404
                                      ? "📍 Not Found - Wrong API endpoint. Check BASE_URL."
                                      : response.statusCode == 500
                                          ? "⚠️ Server Error - Issue on server side"
                                          : "⚠️ Error - Something went wrong",
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.link, size: 14),
                            SizedBox(width: 6),
                            Text(
                              "Full Endpoint URL:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: SelectableText(
                            url,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.key, size: 14),
                            SizedBox(width: 6),
                            Text(
                              "Access Token Used:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Token exists: ${token.isNotEmpty ? "✅ Yes" : "❌ No"}",
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (token.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  "Full Token:",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                SelectableText(
                                  token,
                                  style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Request Headers Sent:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Authorization: Bearer ${token.isNotEmpty ? (token.length > 30 ? token.substring(0, 30) + "..." : token) : "None"}"),
                              Text("App-Language: $appLanguage"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.code, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Raw Server Response:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              response.body.isNotEmpty ? response.body : "(Empty response body)",
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                final debugInfo = """
=== API DEBUG INFO ===
Endpoint: $url
Status Code: ${response.statusCode}
Response Time: ${responseTime}ms
Token Used: $token
Headers: Authorization: Bearer $token, App-Language: $appLanguage
Raw Response: ${response.body}
""";
                Clipboard.setData(ClipboardData(text: debugInfo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debug info copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      
    } catch (e, stackTrace) {
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Network/Parse Error'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "❌ FAILED TO REACH SERVER - Check your internet connection",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Attempted Endpoint:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 4),
                      SelectableText(
                        "${AppConfig.BASE_URL}/customer/info",
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Error: ${e.toString()}",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    stackTrace.toString(),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}