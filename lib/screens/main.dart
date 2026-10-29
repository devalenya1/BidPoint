import 'dart:async';
import 'dart:io';

import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/main.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_flutter/presenter/cart_counter.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/activity_page.dart';
import 'package:active_ecommerce_flutter/screens/cart.dart';
import 'package:active_ecommerce_flutter/screens/category_list.dart';
import 'package:active_ecommerce_flutter/screens/home.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/points_page.dart';
import 'package:active_ecommerce_flutter/screens/profile.dart';
import 'package:active_ecommerce_flutter/data_model/user_info_response.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  final int initialIndex;

  const Main({
    Key? key,
    this.initialIndex = 0,
    bool go_back = true,
  }) : super(key: key);

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  int? _pendingIndex;

  BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();
  CartCounter counter = CartCounter();
  var _children = [];

  // ── User data for the fixed bottom bar's points + avatar ──
  UserInformation? _userInfo;
  bool _isLoadingUserInfo = true;
  Timer? _refreshTimer;

  fetchAll() {
    getCartCount();
  }

  // ── Fetch user info (same flow as profile.dart) ──
  Future<void> _fetchUserInfo() async {
    if (!is_logged_in.$) {
      if (mounted) setState(() => _isLoadingUserInfo = false);
      return;
    }
    try {
      final response = await ProfileRepository().getUserInfoResponse();
      if (response.success == true &&
          response.data != null &&
          response.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userInfo = response.data![0];
            _isLoadingUserInfo = false;
          });
          // Keep shared prefs in sync so PointsPage / Profile see the same balance
          points_balance.$ = _userInfo!.balance?.toString() ?? "0";
          points_balance.save();
          avatar_original.$ = _userInfo!.avatar ?? "";
          avatar_original.save();
        }
      } else {
        if (mounted) setState(() => _isLoadingUserInfo = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUserInfo = false);
    }
  }

  // ── Helper getters ──
  int get _pointsBalance {
    final balance = _userInfo?.balance ?? 0;
    return (balance is num) ? balance.toInt() : 0;
  }

  String get _avatarUrl => _userInfo?.avatar ?? avatar_original.$ ?? '';

  void onTapped(int i) {
    fetchAll();
    // Refresh balance whenever the user switches tabs
    _fetchUserInfo();

    if (!is_logged_in.$ && (i == 2 || i == 3 || i == 4)) {
      _pendingIndex = i;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Login(
            onLoginSuccess: () {
              if (mounted && _pendingIndex != null) {
                setState(() {
                  _currentIndex = _pendingIndex!;
                  _pendingIndex = null;
                });
                _fetchUserInfo();
              }
            },
          ),
        ),
      ).then((_) {
        if (mounted && is_logged_in.$ && _pendingIndex != null) {
          setState(() {
            _currentIndex = _pendingIndex!;
            _pendingIndex = null;
          });
          _fetchUserInfo();
        } else {
          _pendingIndex = null;
        }
      });
      return;
    }

    setState(() {
      _currentIndex = i;
    });
  }

  getCartCount() async {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  void initState() {
    // ⚠️ IMPORTANT: order MUST match _buildBpMobileBar:
    //   0 = Home       → _bpBarItem(index: 0)
    //   1 = Activity   → _bpBarItem(index: 1)
    //   2 = Categories → _bpBarItem(index: 2)
    //   3 = Points     → _bpPointsItem (onTapped(3))
    //   4 = Profile    → _bpProfileItem (onTapped(4))
    _children = [
      Home(),                       // 0
      ActivityPage(),               // 1
      CategoryList(                 // 2
        slug: "",
        is_base_category: true,
      ),
      PointsPage(),                 // 3
      Profile(),                    // 4
    ];

    _currentIndex = widget.initialIndex;

    fetchAll();
    _fetchUserInfo();

    // Auto-refresh balance every 30s while on Main
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchUserInfo(),
    );

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<bool> willPop() async {
    print(_currentIndex);
    if (_currentIndex != 0) {
      fetchAll();
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      print("Main will back");
      final shouldPop = (await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return Directionality(
            textDirection: app_language_rtl.$!
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: AlertDialog(
              content: Text(
                AppLocalizations.of(context)!.do_you_want_close_the_app,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Platform.isAndroid ? SystemNavigator.pop() : exit(0);
                  },
                  child: Text(AppLocalizations.of(context)!.yes_ucf),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.no_ucf),
                ),
              ],
            ),
          );
        },
      ))!;
      return shouldPop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: willPop,
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          extendBody: true,
          body: _children[_currentIndex],
          bottomNavigationBar: _buildBpMobileBar(context),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BIDPOINTS MOBILE BOTTOM BAR
  // Matches HTML .bp-mobilebar exactly — 5 equal 20% columns
  // ═══════════════════════════════════════════════════════════
  Widget _buildBpMobileBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFdce9f2), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A173A5A),
            blurRadius: 24,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 9.h),
          child: Row(
            children: [
              // 1/5 — Home
              _bpBarItem(
                index: 0,
                label: AppLocalizations.of(context)!.home_ucf,
                icon: Icons.home_outlined,
              ),
              // 2/5 — Activity
              _bpBarItem(
                index: 1,
                label: AppLocalizations.of(context)!.activity_ucf,
                icon: Icons.show_chart,
              ),
              // 3/5 — Categories
              _bpBarItem(
                index: 2,
                label: AppLocalizations.of(context)!.categories_ucf,
                icon: Icons.grid_view,
              ),
              // 4/5 — Points (with balance + "+")
              _bpPointsItem(context),
              // 5/5 — Profile (avatar)
              _bpProfileItem(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Standard icon + label item ──
  Widget _bpBarItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isActive = _currentIndex == index;
    final color =
        isActive ? MyTheme.accent_color : const Color(0xFF28516e);

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22.w,
              height: 20.w,
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Points item — balance + "+" + "points" small text ──
  Widget _bpPointsItem(BuildContext context) {
    final isActive = _currentIndex == 3;
    final color =
        isActive ? MyTheme.accent_color : const Color(0xFF28516e);

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTapped(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '◉',
              style: TextStyle(
                fontSize: 20.sp,
                color: const Color(0xFFdfad37),
                height: 1,
              ),
            ),
            SizedBox(height: 1.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _isLoadingUserInfo
                        ? '...'
                        : '$_pointsBalance',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF165076),
                    ),
                  ),
                  TextSpan(
                    text: '＋',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF05aa9d),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.points_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF6a8295),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile item — avatar circle + label ──
  Widget _bpProfileItem(BuildContext context) {
    final isActive = _currentIndex == 4;
    final color =
        isActive ? MyTheme.accent_color : const Color(0xFF28516e);
    final hasAvatar = _avatarUrl.isNotEmpty;

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTapped(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFeaf9f6),
                border: Border.all(
                  color: isActive
                      ? MyTheme.accent_color
                      : const Color(0xFF28516e),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasAvatar
                  ? Image.network(
                      _avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 14.sp,
                        color: const Color(0xFF28516e),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 14.sp,
                      color: const Color(0xFF28516e),
                    ),
            ),
            SizedBox(height: 3.h),
            Text(
              AppLocalizations.of(context)!.profile_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}