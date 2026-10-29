import 'dart:math' as math;

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/data_model/category_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/home_presenter.dart';
import 'package:active_ecommerce_flutter/repositories/category_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/category_products.dart';
import 'package:active_ecommerce_flutter/screens/all_products.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/screens/messenger_list.dart';
import 'package:active_ecommerce_flutter/screens/notifications_page.dart';
import 'package:active_ecommerce_flutter/screens/affiliate_page.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/ui_elements/hot_auction_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/ending_soon_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/upcoming_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data_model/user_info_response.dart';

class Home extends StatefulWidget {
  Home({
    Key? key,
    this.title,
    this.show_back_button = false,
    go_back = true,
  }) : super(key: key);

  final String? title;
  bool show_back_button;
  late bool go_back;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  HomePresenter homeData = HomePresenter();

  bool _isLoadingCounts = true;
  bool _isRefreshingCounts = false;
  UserInformation? _userInfo;

  final GlobalKey _howItWorksKey = GlobalKey();

  // ── Recent winners loaded from CategoryResponse
  List<RecentWinner> _recentWinners = [];
  bool _isLoadingWinners = true;
  final CategoryRepository _categoryRepository = CategoryRepository();

  int get _unreadNotificationCount {
    if (is_logged_in.$ != true) return 0;
    return _userInfo?.unreadNotificationsCount ?? 0;
  }

  int get _unreadMessageCount {
    if (is_logged_in.$ != true) return 0;
    return _userInfo?.unreadMessagesCount ?? 0;
  }

  bool get _shouldShowNotificationBadge {
    if (!is_logged_in.$) return false;
    if (_isLoadingCounts) return false;
    return _unreadNotificationCount > 0;
  }

  bool get _shouldShowMessageBadge {
    if (!is_logged_in.$) return false;
    if (_isLoadingCounts) return false;
    return _unreadMessageCount > 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _fetchRecentWinners();
    Future.delayed(Duration.zero).then((value) => change());
  }

  Future<void> _fetchRecentWinners() async {
    try {
      setState(() => _isLoadingWinners = true);
      final response = await _categoryRepository.getCategories();
      if (response.success == true) {
        setState(() {
          _recentWinners = response.recentWinners ?? [];
          _isLoadingWinners = false;
        });
      } else {
        setState(() => _isLoadingWinners = false);
      }
    } catch (e) {
      print('❌ Recent winners fetch error: $e');
      setState(() => _isLoadingWinners = false);
    }
  }

  Future<void> _fetchCounts() async {
    if (is_logged_in.$ != true) {
      setState(() => _isLoadingCounts = false);
      return;
    }
    try {
      setState(() => _isLoadingCounts = true);
      var response = await ProfileRepository().getUserInfoResponse();
      if (response.success == true &&
          response.data != null &&
          response.data!.isNotEmpty) {
        setState(() => _userInfo = response.data![0]);
        unread_notifications_count.$ = _userInfo!.unreadNotificationsCount ?? 0;
        unread_notifications_count.save();
      }
    } catch (e) {
      print("Error loading notification counts: $e");
      ToastComponent.showError(
          AppLocalizations.of(context)!.failed_to_load_notifications);
    } finally {
      setState(() => _isLoadingCounts = false);
    }
  }

  Future<void> _refreshCounts() async {
    setState(() => _isRefreshingCounts = true);
    await _fetchCounts();
    await _fetchRecentWinners();
    setState(() => _isRefreshingCounts = false);
  }

  change() => homeData.onRefresh();

  @override
  void dispose() {
    homeData.pirated_logo_controller.dispose();
    super.dispose();
  }

  void _redirectToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }

  void _handleSliderTap(String? url) {
    if (url == null || url.isEmpty) return;
    var cleanUrl = url.split(AppConfig.DOMAIN_PATH).last ?? "";
    if (cleanUrl.isEmpty) cleanUrl = url;

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CommonWebviewScreen(page_name: 'Slider', url: cleanUrl),
        ),
      );
    } else {
      if (cleanUrl.contains('/product/') ||
          cleanUrl.contains('/category/') ||
          cleanUrl.contains('/auction/')) {
        try {
          GoRouter.of(context).go(cleanUrl);
        } catch (e) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommonWebviewScreen(page_name: 'Slider', url: url),
            ),
          );
        }
      } else {
        String fullUrl = url;
        if (!fullUrl.startsWith('http://') &&
            !fullUrl.startsWith('https://')) {
          fullUrl = AppConfig.RAW_BASE_URL + url;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CommonWebviewScreen(page_name: 'Slider', url: fullUrl),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            appBar: buildAppBar(),
            body: ListenableBuilder(
              listenable: homeData,
              builder: (context, child) {
                return RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await homeData.onRefresh();
                    await _refreshCounts();
                  },
                  displacement: 0,
                  child: CustomScrollView(
                    controller: homeData.mainScrollController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: buildBidPointsHeroSection()),
                      SliverToBoxAdapter(
                          child: buildBidPointsCategoriesSection()),
                      SliverToBoxAdapter(child: SizedBox(height: 9.h)),
                      SliverToBoxAdapter(child: _buildHotAuctionSection()),
                      SliverToBoxAdapter(child: _buildEndingSoonSection()),
                      SliverToBoxAdapter(child: _buildUpcomingSection()),
                      SliverToBoxAdapter(child: _buildEndedAuctionsSection()),
                      SliverToBoxAdapter(child: buildPromoBanner()),
                      SliverToBoxAdapter(child: buildHowItWorks()),
                      SliverToBoxAdapter(child: buildRecentWinners()),
                      SliverToBoxAdapter(child: buildTrustBenefits()),
                      SliverToBoxAdapter(child: SizedBox(height: 26.h)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════
  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(66.h),
      child: _BpUtilityHeader(
        isLoggedIn: is_logged_in.$,
        hasUnreadMessages: _shouldShowMessageBadge,
        hasUnreadNotifications: _shouldShowNotificationBadge,
        userBalance: (_userInfo?.balance ?? 0).toInt(),
        onSearchTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Filter()),
        ),
        onMessagesTap: () {
          if (is_logged_in.$) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessengerList()),
            );
          } else {
            _redirectToLogin();
          }
        },
        onNotificationsTap: () {
          if (is_logged_in.$) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ).then((_) => _refreshCounts());
          } else {
            _redirectToLogin();
          }
        },
        onRewardsTap: () {
          if (is_logged_in.$) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AffiliatePage()),
            );
          } else {
            _redirectToLogin();
          }
        },
        onAccountTap: () {},
        onLoginTap: () => _redirectToLogin(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO (unchanged — already matched)
  // ═══════════════════════════════════════════════════════════
  Widget buildBidPointsHeroSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 9.h),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(0.58, -0.16),
            radius: 1.2,
            colors: [
              Color(0xFF155e81),
              Color(0xFF0c355c),
              Color(0xFF071c35),
            ],
            stops: [0.0, 0.38, 0.80],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isMobile ? 22.r : 27.r),
            bottomRight: Radius.circular(isMobile ? 22.r : 27.r),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1613395b),
              blurRadius: 38,
              offset: Offset(0, 19),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: isMobile
                ? _buildHeroMobileContent()
                : _buildHeroDesktopContent(),
          ),
        ),
      );
    });
  }

  Widget _buildHeroDesktopContent() {
    return Container(
      constraints: BoxConstraints(minHeight: 400.h),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 47, child: _buildHeroCopy(isMobile: false)),
          Expanded(flex: 53, child: _buildHeroArt(isMobile: false)),
        ],
      ),
    );
  }

  Widget _buildHeroMobileContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCopy(isMobile: true),
          _buildHeroArt(isMobile: true),
        ],
      ),
    );
  }

  Widget _buildHeroCopy({required bool isMobile}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double headlineSize = isMobile
        ? (screenWidth * 0.07).clamp(28.0, 46.0)
        : (screenWidth * 0.043).clamp(34.0, 62.0);
    final headlineStyle = TextStyle(
      fontSize: headlineSize,
      fontWeight: FontWeight.w900,
      height: 1.09,
      letterSpacing: -headlineSize * 0.045,
      color: Colors.white,
    );

    return Padding(
      padding: isMobile
          ? EdgeInsets.fromLTRB(5.w, 24.h, 14.w, 5.h)
          : EdgeInsets.fromLTRB(0, 28.h, 22.w, 38.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.bp_hero_eyebrow,
            style: TextStyle(
              color: const Color(0xFF72eadc),
              fontSize: isMobile ? 11.sp : 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: isMobile ? 2 : 2.5,
              height: 1,
            ),
          ),
          SizedBox(height: 12.h),
          Text(AppLocalizations.of(context)!.bp_hero_line1,
              style: headlineStyle),
          Text(
            '${AppLocalizations.of(context)!.bp_hero_letter_a} ',
            style: headlineStyle,
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF5ee7e1),
                Color(0xFF19d3be),
                Color(0xFF75b8ff),
              ],
            ).createShader(bounds),
            child: Text(
              AppLocalizations.of(context)!.bp_hero_line2,
              style: headlineStyle.copyWith(color: Colors.white),
            ),
          ),
          SizedBox(height: 14.h),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              AppLocalizations.of(context)!.bp_hero_description,
              style: TextStyle(
                fontSize: isMobile ? 12.sp : 14.sp,
                color: const Color(0xFFd4e7f7),
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          GestureDetector(
            onTap: _showBidPointsVideoPopup,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14.w : 22.w,
                vertical: isMobile ? 10.h : 12.h,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-0.9, -0.4),
                  end: Alignment(0.9, 0.4),
                  colors: [Color(0xFF22d5b6), Color(0xFF33b9ec)],
                ),
                borderRadius: BorderRadius.circular(35.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F03bfa1),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.bp_hero_video_cta,
                style: TextStyle(
                  color: const Color(0xFF07304d),
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 10.sp : 11.sp,
                  height: 1.4,
                ),
              ),
            ),
          ),
          SizedBox(height: 22.h),
          _buildHeroTrustRow(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildHeroTrustRow({required bool isMobile}) {
    final items = <List<String>>[
      ['🏆', AppLocalizations.of(context)!.bp_trust_authentic],
      ['♢', AppLocalizations.of(context)!.bp_trust_secure_payments],
      ['🚚', AppLocalizations.of(context)!.bp_trust_shipping],
    ];

    return Wrap(
      spacing: isMobile ? 10.w : 22.w,
      runSpacing: 6.h,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              item[0],
              style: TextStyle(
                color: const Color(0xFFffcc38),
                fontSize: isMobile ? 15.sp : 18.sp,
                height: 1,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              item[1],
              style: TextStyle(
                fontSize: isMobile ? 9.sp : 10.sp,
                color: const Color(0xFFe5f1fc),
                height: 1.2,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHeroArt({required bool isMobile}) {
    final artHeight = isMobile ? 240.h : 360.h;

    return SizedBox(
      height: artHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: homeData.carouselImageList.isEmpty
                ? const SizedBox.shrink()
                : ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      if (isMobile) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.13, 0.80, 1.0],
                        ).createShader(bounds);
                      }
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.0, 0.20],
                      ).createShader(bounds);
                    },
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: artHeight,
                        viewportFraction: 1,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        autoPlayAnimationDuration:
                            const Duration(milliseconds: 1000),
                        autoPlayCurve: Curves.easeInExpo,
                        enableInfiniteScroll: true,
                        enlargeCenterPage: false,
                        scrollDirection: Axis.horizontal,
                      ),
                      items: homeData.carouselImageList.map((item) {
                        return GestureDetector(
                          onTap: () => _handleSliderTap(item.url),
                          child: SizedBox(
                            width: double.infinity,
                            height: artHeight,
                            child:
                                (item.photo != null && item.photo!.isNotEmpty)
                                    ? Image.network(
                                        item.photo!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          if (!isMobile)
            Positioned(
              top: artHeight * 0.21,
              right: 3.w,
              child: Transform.rotate(
                angle: -3 * math.pi / 180,
                child: _buildHeroSticker(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSticker() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xEC073457),
        border: Border.all(color: const Color(0xFF20d8c0), width: 2),
        borderRadius: BorderRadius.circular(13.r),
        boxShadow: const [
          BoxShadow(color: Color(0x550be7cc), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.bp_sticker_top,
            style: TextStyle(
              color: const Color(0xFFe3fcff),
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            AppLocalizations.of(context)!.bp_sticker_main,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF71f8e3),
              fontWeight: FontWeight.w900,
              fontSize: 13.sp,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  void _showBidPointsVideoPopup() {
    showDialog(
      context: context,
      barrierColor: const Color(0xB8071c35),
      builder: (ctx) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 22.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: const [
                  BoxShadow(color: Color(0x88000000), blurRadius: 60),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.bp_video_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF143957),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        AppLocalizations.of(context)!.bp_video_subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF59738b),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        height: 150.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0c365d), Color(0xFF0c8e9c)],
                          ),
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.bp_video_placeholder,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -12.w,
                    top: -8.h,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      color: const Color(0xFF31516b),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════════════════
  Widget buildBidPointsCategoriesSection() {
    if (homeData.featuredCategoryList.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: isMobile ? 18.h : 22.h),
        child: isMobile
            ? _buildCategoriesMobile()
            : _buildCategoriesDesktop(constraints.maxWidth),
      );
    });
  }

  Widget _buildCategoriesDesktop(double availableWidth) {
    final gridWidth = math.min(1380.0, availableWidth - 44.w);
    final categories = homeData.featuredCategoryList;
    final rows = <Widget>[];

    for (int i = 0; i < categories.length; i += 9) {
      final end = math.min(i + 9, categories.length);
      final chunk = categories.sublist(i, end);
      rows.add(_buildCategoryRow(chunk, gridWidth));
      if (end < categories.length) {
        rows.add(SizedBox(height: 8.h));
      }
    }

    return Center(
      child: SizedBox(
        width: gridWidth,
        child: Column(children: rows),
      ),
    );
  }

  Widget _buildCategoryRow(List chunk, double gridWidth) {
    final colWidth = (gridWidth - 8 * 8) / 9;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < 9; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SizedBox(
            width: colWidth,
            child: i < chunk.length
                ? _buildCategoryPill(chunk[i], isMobile: false)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoriesMobile() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: homeData.featuredCategoryList.map((category) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: SizedBox(
                  width: 82.w,
                  child: _buildCategoryPill(category, isMobile: true),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(dynamic category, {required bool isMobile}) {
    return InkWell(
      onTap: () {
        if (category.slug != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProducts(slug: category.slug!),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(34.r),
      child: Container(
        padding: isMobile
            ? EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h)
            : EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFdbe7f1), width: 1),
          borderRadius: BorderRadius.circular(34.r),
          boxShadow: isMobile
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x10143c64),
                    blurRadius: 13,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 22.w : 24.w,
              height: isMobile ? 22.w : 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFf0f7fb),
                border: Border.all(
                  color: const Color(0xFFdceaf3),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: (category.banner != null && category.banner!.isNotEmpty)
                  ? Image.network(
                      category.banner!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.category,
                        size: isMobile ? 13.sp : 14.sp,
                        color: const Color(0xFF34526c),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      size: isMobile ? 13.sp : 14.sp,
                      color: const Color(0xFF34526c),
                    ),
            ),
            SizedBox(height: 3.h),
            Text(
              category.name ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 9.sp : 10.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF34526c),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED
  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionHead({
    required String title,
    required VoidCallback onViewAll,
  }) {
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 21.sp : 24.sp,
                color: const Color(0xFF103451),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.05 * (isMobile ? 21 : 24),
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFd4e3ef),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                loc.view_all,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF144164),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 50.h,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(fontSize: 12.sp, color: MyTheme.font_grey),
      ),
    );
  }

  // Replace the _buildTwoColumnGrid method in home.dart with this:
  /// Requirement: every section shows 2 columns side-by-side on mobile too.
  /// Equal image sizes, equal card sizes enforced by IntrinsicHeight.
  Widget _buildTwoColumnGrid({
    required List<dynamic> products,
    required bool isMobile,
    required Widget Function(BuildContext, dynamic) cardBuilder,
  }) {
    final limited = products.take(2).toList();

    if (limited.isEmpty) return const SizedBox.shrink();

    // ALWAYS 2 columns side by side — on mobile AND desktop.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cardBuilder(context, limited[0])),
          SizedBox(width: isMobile ? 8.w : 18.w),
          Expanded(
            child: limited.length > 1
                ? cardBuilder(context, limited[1])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOT AUCTIONS
  // ═══════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════
  // HOT AUCTIONS — with new title + subtitle matching HTML
  // ═══════════════════════════════════════════════════════════
  Widget _buildHotAuctionSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final loc = AppLocalizations.of(context)!;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 22.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHotHead(onViewAll: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return CategoryProducts(slug: 'hot-auctions');
                    }));
                  }),
                  SizedBox(height: 18.h),
                  if (homeData.hotAuctionProductList.isEmpty)
                    _buildEmptyState(loc.no_hot_auctions_available)
                  else
                    _buildTwoColumnGrid(
                      products: homeData.hotAuctionProductList,
                      isMobile: isMobile,
                      cardBuilder: (context, product) {
                        bool isActive = false;
                        if (product.auctionEndDate != null &&
                            product.auctionEndDate is int) {
                          isActive = product.auctionEndDate >
                              DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        }
                        return HotAuctionCard(
                          id: product.id ?? 0,
                          slug: product.slug ?? '',
                          image: product.thumbnailImage,
                          name: product.name,
                          description: product.description,
                          pointPerBid: product.pointPerBid ?? 0,
                          auctionEndDate: product.auctionEndDate,
                          currentBid: product.highestBid,
                          startingBid: product.startingBid,
                          purchasePrice: product.purchasePrice,
                          isAuctionActive: isActive,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // HOT AUCTION HEADER — new localized title + subtitle
  // ═══════════════════════════════════════════════════════════
  Widget _buildHotHead({required VoidCallback onViewAll}) {
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      final title = '🔥 ${loc.hot_live_trending_auctions}';
      final onlinePrefix = '🟢 ${loc.hot_online_over} ';
      final onlineCount = loc.hot_online_count;
      final onlineSuffix = ' ${loc.hot_users_bidding_now}';

      if (isMobile) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 21.sp,
                      color: const Color(0xFF103451),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.05 * 21,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: onlinePrefix),
                        TextSpan(
                          text: onlineCount,
                          style: const TextStyle(
                            color: Color(0xFF00AD91),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: onlineSuffix),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF687E91),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFd4e3ef),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  loc.view_all,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF144164),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: onlinePrefix,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF687E91),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  TextSpan(
                    text: onlineCount,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF00AD91),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  TextSpan(
                    text: onlineSuffix,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF687E91),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 24.sp,
                color: const Color(0xFF103451),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.05 * 24,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFd4e3ef),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                loc.view_all,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF144164),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
  

  // ═══════════════════════════════════════════════════════════
  // ENDING SOON
  // ═══════════════════════════════════════════════════════════
  Widget _buildEndingSoonSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final loc = AppLocalizations.of(context)!;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 22.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHead(
                    title: '⏳ ${loc.ending_soon_ucf}',
                    onViewAll: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CategoryProducts(slug: 'ending-soon');
                      }));
                    },
                  ),
                  SizedBox(height: 18.h),
                  if (homeData.endingSoonProductList.isEmpty)
                    _buildEmptyState(loc.no_ending_soon_auctions)
                  else
                    _buildTwoColumnGrid(
                      products: homeData.endingSoonProductList,
                      isMobile: isMobile,
                      cardBuilder: (context, product) => EndingSoonCard(
                        id: product.id ?? 0,
                        slug: product.slug ?? '',
                        image: product.thumbnailImage,
                        name: product.name,
                        description: product.description,
                        pointPerBid: product.pointPerBid ?? 0,
                        auctionEndDate: product.auctionEndDate,
                        currentBid: product.highestBid,
                        startingBid: product.startingBid,
                        purchasePrice: product.purchasePrice,
                        isAuctionActive: product.auctionEndDate != null &&
                            product.auctionEndDate is int &&
                            product.auctionEndDate >
                                DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // UPCOMING
  // ═══════════════════════════════════════════════════════════
  Widget _buildUpcomingSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final loc = AppLocalizations.of(context)!;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 22.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHead(
                    title: '📅 ${loc.upcoming_auctions_ucf}',
                    onViewAll: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CategoryProducts(slug: 'upcoming-auctions');
                      }));
                    },
                  ),
                  SizedBox(height: 18.h),
                  if (homeData.upcomingProductList.isEmpty)
                    _buildEmptyState(loc.no_upcoming_auctions)
                  else
                    _buildTwoColumnGrid(
                      products: homeData.upcomingProductList,
                      isMobile: isMobile,
                      cardBuilder: (context, product) {
                        int? auctionStartTimestamp;
                        if (product.auctionStartDate != null) {
                          if (product.auctionStartDate is int) {
                            auctionStartTimestamp = product.auctionStartDate;
                          } else if (product.auctionStartDate is String) {
                            auctionStartTimestamp =
                                int.tryParse(product.auctionStartDate) ?? 0;
                          }
                        }
                        return UpcomingCard(
                          id: product.id ?? 0,
                          slug: product.slug ?? '',
                          image: product.thumbnailImage,
                          name: product.name,
                          description: product.description,
                          pointPerBid: product.pointPerBid ?? 0,
                          auctionEndDate: auctionStartTimestamp ??
                              product.auctionStartDate,
                          currentBid: product.startingBid,
                          startingBid: product.startingBid,
                          purchasePrice: product.purchasePrice,
                          isAuctionActive: false,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // COMPLETED AUCTIONS
  // ═══════════════════════════════════════════════════════════
  Widget _buildEndedAuctionsSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final loc = AppLocalizations.of(context)!;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 22.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHead(
                    title: '🏁 ${loc.ended_auctions_ucf}',
                    onViewAll: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CategoryProducts(slug: 'ended-auctions');
                      }));
                    },
                  ),
                  SizedBox(height: 18.h),
                  if (homeData.endedProductList.isEmpty)
                    _buildEmptyState(loc.no_ended_auctions)
                  else
                    _buildTwoColumnGrid(
                      products: homeData.endedProductList,
                      isMobile: isMobile,
                      cardBuilder: (context, product) => ProductCard(
                        id: product.id ?? 0,
                        slug: product.slug ?? '',
                        image: product.thumbnailImage,
                        name: product.name,
                        description: product.description,
                        pointPerBid: product.pointPerBid ?? 0,
                        auctionEndDate: 'Ended',
                        currentBid: product.highestBid,
                        startingBid: product.startingBid,
                        purchasePrice: product.purchasePrice,
                        isAuctionActive: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // PROMO BANNER (matches HTML .bp-promo-banner)
  // ═══════════════════════════════════════════════════════════
  Widget buildPromoBanner() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final isTightMobile = constraints.maxWidth < 520;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 24.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTightMobile ? 14.w : (isMobile ? 16.w : 28.w),
                vertical: isTightMobile ? 14.h : (isMobile ? 16.h : 24.h),
              ),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.68, 0),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2376a3),
                    Color(0xFF0b4168),
                    Color(0xFF08243e),
                  ],
                  stops: [0.0, 0.35, 0.80],
                ),
                borderRadius:
                    BorderRadius.circular(isTightMobile ? 14.r : 20.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20173f62),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: isMobile
                  ? _buildPromoBannerMobile(isTightMobile)
                  : _buildPromoBannerDesktop(isTightMobile),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPromoBannerDesktop(bool isTightMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = (screenWidth * 0.024).clamp(19.0, 31.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '🏆',
          style: TextStyle(
            fontSize: 75.sp,
            shadows: const [
              Shadow(color: Color(0xFFFFac36), blurRadius: 15),
            ],
          ),
        ),
        SizedBox(width: 22.w),
        Expanded(child: _buildPromoTitle(titleSize)),
        SizedBox(width: 22.w),
        _buildPromoCtaButton(isMobile: false, isTightMobile: false),
      ],
    );
  }

  // Replace _buildPromoBannerMobile in home.dart with this:

  Widget _buildPromoBannerMobile(bool isTightMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize =
        isTightMobile ? 15.0 : (screenWidth * 0.038).clamp(15.0, 18.0);

    // Requirement #7: button and text MUST be on the same line.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '🏆',
          style: TextStyle(fontSize: (isTightMobile ? 28 : 34).sp),
        ),
        SizedBox(width: 6.w),
        Expanded(
          flex: 3,
          child: _buildPromoTitle(titleSize),
        ),
        SizedBox(width: 6.w),
        Flexible(
          flex: 2,
          child: _buildPromoCtaButton(
            isMobile: true,
            isTightMobile: isTightMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoTitle(double titleSize) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!.bp_promo_line1,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.04 * titleSize,
            ),
          ),
          TextSpan(
            text:
                '\n${AppLocalizations.of(context)!.bp_promo_line2}\n${AppLocalizations.of(context)!.bp_promo_line3}',
            style: TextStyle(
              color: const Color(0xFF55e8d5),
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.04 * titleSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCtaButton(
      {required bool isMobile, required bool isTightMobile}) {
    return GestureDetector(
      onTap: () {
        final ctx = _howItWorksKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTightMobile ? 16.w : (isMobile ? 18.w : 24.w),
          vertical: isTightMobile ? 10.h : (isMobile ? 12.h : 14.h),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Text(
          '${AppLocalizations.of(context)!.bp_promo_cta} ➜',
          style: TextStyle(
            color: const Color(0xFF0d4462),
            fontWeight: FontWeight.w800,
            fontSize: isTightMobile ? 10.sp : (isMobile ? 11.sp : 12.sp),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOW IT WORKS — Requirement #6: same width/height/font as HTML
  // ═══════════════════════════════════════════════════════════
  Widget buildHowItWorks() {
    return KeyedSubtree(
      key: _howItWorksKey,
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isTightMobile = constraints.maxWidth < 520;

        return Padding(
          padding: EdgeInsets.only(
            left: 9.w,
            right: 9.w,
            top: 12.h,
            bottom: 28.h,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.bp_how_title,
                    style: TextStyle(
                      fontSize: isTightMobile
                          ? 22.sp
                          : (isMobile ? 22.sp : 26.sp),
                      color: const Color(0xFF103451),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppLocalizations.of(context)!.bp_how_subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF71879d),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  isMobile
                      ? _buildHowWorksMobileSteps(isTightMobile)
                      : _buildHowWorksDesktopSteps(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Map<String, String>> _howWorksSteps(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      {
        'num': '1',
        'icon': '🪙',
        'title': t.bp_how_step1_title,
        'desc': t.bp_how_step1_desc,
      },
      {
        'num': '2',
        'icon': '☝️',
        'title': t.bp_how_step2_title,
        'desc': t.bp_how_step2_desc,
      },
      {
        'num': '3',
        'icon': '⚒',
        'title': t.bp_how_step3_title,
        'desc': t.bp_how_step3_desc,
      },
      {
        'num': '4',
        'icon': '📦',
        'title': t.bp_how_step4_title,
        'desc': t.bp_how_step4_desc,
      },
    ];
  }

  Widget _buildHowWorksDesktopSteps() {
    final steps = _howWorksSteps(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        return Expanded(
          child: Container(
            padding:
                EdgeInsets.fromLTRB(i == 0 ? 0 : 19.w, 12.h, 19.w, 12.h),
            decoration: i < 3
                ? const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFdce9f2),
                        width: 1,
                      ),
                    ),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepNumBadge(step['num']!),
                SizedBox(width: 12.w),
                Text(
                  step['icon']!,
                  style: TextStyle(fontSize: 40.sp, height: 1),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF103451),
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        step['desc']!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF698099),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHowWorksMobileSteps(bool isTightMobile) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMobileStep(0, isTightMobile)),
            SizedBox(width: 10.w),
            Expanded(child: _buildMobileStep(1, isTightMobile)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMobileStep(2, isTightMobile)),
            SizedBox(width: 10.w),
            Expanded(child: _buildMobileStep(3, isTightMobile)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStep(int index, bool isTightMobile) {
    final step = _howWorksSteps(context)[index];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepNumBadge(step['num']!, small: true),
          SizedBox(width: 6.w),
          Text(
            step['icon']!,
            style:
                TextStyle(fontSize: isTightMobile ? 24.sp : 27.sp, height: 1),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title']!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF103451),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  step['desc']!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF698099),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNumBadge(String num, {bool small = false}) {
    return Container(
      width: small ? 26.w : 31.w,
      height: small ? 26.w : 31.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13baa8), Color(0xFF288bda)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        num,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: small ? 12.sp : 13.sp,
          height: 1,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RECENT WINNERS — Requirement #1: real data, Requirement #8: readable fonts
  // ═══════════════════════════════════════════════════════════
  Widget buildRecentWinners() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final isTightMobile = constraints.maxWidth < 520;

      return Padding(
        padding: EdgeInsets.only(
          left: 9.w,
          right: 9.w,
          top: 8.h,
          bottom: 14.h,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆  ${AppLocalizations.of(context)!.bp_winners_title}',
                  style: TextStyle(
                    fontSize: 17.sp,
                    color: const Color(0xFF103451),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!.bp_winners_subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF71879d),
                  ),
                ),
                SizedBox(height: 15.h),
                _buildWinnersList(isMobile, isTightMobile),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWinnersList(bool isMobile, bool isTightMobile) {
    if (_isLoadingWinners) {
      return Container(
        height: 60.h,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_recentWinners.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context)!.bp_winners_empty,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF71879d),
          ),
        ),
      );
    }

    final columns = isMobile ? 2 : 5;

    return LayoutBuilder(builder: (context, constraints) {
      final spacing = 8.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: _recentWinners.map((w) {
          return SizedBox(
            width: itemWidth,
            child: _buildWinnerCard(w, isTightMobile),
          );
        }).toList(),
      );
    });
  }

  Widget _buildWinnerCard(RecentWinner w, bool isTightMobile) {
    final hasImage = (w.thumbnail ?? '').isNotEmpty;
    final iconSize = isTightMobile ? 30.w : 30.w;
    final emojiSize = isTightMobile ? 14.sp : 16.sp;
    final titleSize = isTightMobile ? 11.sp : 11.sp;
    final subSize = isTightMobile ? 10.sp : 11.sp;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe0eaf2), width: 1),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10123e58),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: const Color(0xFFf0f7fb),
              borderRadius: BorderRadius.circular(7.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.network(
                    w.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text('🏆',
                          style: TextStyle(fontSize: emojiSize)),
                    ),
                  )
                : Center(
                    child:
                        Text('🏆', style: TextStyle(fontSize: emojiSize)),
                  ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.winnerName ?? '',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173c59),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${AppLocalizations.of(context)!.bp_winners_won} ${w.productName ?? ''}',
                  style: TextStyle(
                    fontSize: subSize,
                    color: const Color(0xFF71879d),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: subSize,
                      color: const Color(0xFF173c59),
                    ),
                    children: [
                      TextSpan(
                          text:
                              '${AppLocalizations.of(context)!.bp_winners_for} '),
                      TextSpan(
                        text:
                            '\$${(w.highestBid ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF00b7a1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TRUST BENEFITS — Requirement #8: fonts no longer tiny
  // ═══════════════════════════════════════════════════════════
  Widget buildTrustBenefits() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final isTightMobile = constraints.maxWidth < 520;

      final innerPad = isTightMobile
          ? EdgeInsets.all(14.w)
          : (isMobile
              ? EdgeInsets.all(16.w)
              : EdgeInsets.symmetric(horizontal: 28.w, vertical: 19.h));

      return Padding(
        padding: EdgeInsets.only(
          left: 9.w,
          right: 9.w,
          bottom: 12.h,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Container(
              padding: innerPad,
              decoration: BoxDecoration(
                color: const Color(0xFFe9f8f7),
                border: Border.all(color: const Color(0xFFcfece8), width: 1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: _buildTrustBenefitsGrid(isMobile, isTightMobile),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTrustBenefitsGrid(bool isMobile, bool isTightMobile) {
    final t = AppLocalizations.of(context)!;
    final benefits = <Map<String, String>>[
      {'icon': '🛡️', 'title': t.bp_trust1_title, 'sub': t.bp_trust1_sub},
      {'icon': '🚚', 'title': t.bp_trust2_title, 'sub': t.bp_trust2_sub},
      {'icon': '🔒', 'title': t.bp_trust3_title, 'sub': t.bp_trust3_sub},
      {'icon': '⭐', 'title': t.bp_trust4_title, 'sub': t.bp_trust4_sub},
    ];

    final columns = isMobile ? 2 : 4;

    return LayoutBuilder(builder: (context, constraints) {
      final spacing = isMobile ? 14.0 : 16.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: benefits.map((b) {
          return SizedBox(
            width: itemWidth,
            child: _buildTrustBenefit(b, isMobile, isTightMobile),
          );
        }).toList(),
      );
    });
  }

  Widget _buildTrustBenefit(
      Map<String, String> b, bool isMobile, bool isTightMobile) {
    final iconSize = isTightMobile ? 22.sp : (isMobile ? 22.sp : 24.sp);
    final titleSize = isTightMobile ? 12.sp : (isMobile ? 12.sp : 12.sp);
    final subSize = isTightMobile ? 10.sp : (isMobile ? 10.sp : 11.sp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(b['icon']!, style: TextStyle(fontSize: iconSize, height: 1)),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b['title']!,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF183c56),
                ),
              ),
              Text(
                b['sub']!,
                style: TextStyle(
                  fontSize: subSize,
                  color: const Color(0xFF6b8593),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BIDPOINTS UTILITY HEADER (unchanged from your version)
// ═══════════════════════════════════════════════════════════
class _BpUtilityHeader extends StatefulWidget {
  final bool isLoggedIn;
  final bool hasUnreadMessages;
  final bool hasUnreadNotifications;
  final int userBalance;
  final VoidCallback onSearchTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onRewardsTap;
  final VoidCallback onAccountTap;
  final VoidCallback onLoginTap;

  const _BpUtilityHeader({
    Key? key,
    required this.isLoggedIn,
    required this.hasUnreadMessages,
    required this.hasUnreadNotifications,
    required this.userBalance,
    required this.onSearchTap,
    required this.onMessagesTap,
    required this.onNotificationsTap,
    required this.onRewardsTap,
    required this.onAccountTap,
    required this.onLoginTap,
  }) : super(key: key);

  @override
  State<_BpUtilityHeader> createState() => _BpUtilityHeaderState();
}

class _BpUtilityHeaderState extends State<_BpUtilityHeader> {
  bool _menuOpen = false;
  OverlayEntry? _menuOverlay;
  final GlobalKey _menuBtnKey = GlobalKey();

  void _toggleMenu() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final loc = AppLocalizations.of(context)!;
    final box = _menuBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final top = pos.dy + box.size.height + 12;
    final screenWidth = MediaQuery.of(context).size.width;

    _menuOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: top,
            right: screenWidth < 700 ? 15 : 28,
            width: 310,
            child: Material(
              color: Colors.transparent,
              child: _buildMenuPanel(loc),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    if (mounted) setState(() => _menuOpen = false);
  }

  @override
  void dispose() {
    _menuOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFdceaf3))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C123866),
              blurRadius: 22,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 15.w : 28.w,
              vertical: isMobile ? 8.h : 9.h,
            ),
            child: Row(
              children: [
                _buildLogo(isMobile),
                SizedBox(width: isMobile ? 9.w : 15.w),
                Expanded(child: _buildSearch(isMobile)),
                SizedBox(width: isMobile ? 5.w : 9.w),
                _buildActions(isMobile),
                if (!isMobile) ...[
                  SizedBox(width: 9.w),
                  _buildHamburger(isMobile),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isMobile) {
    final size = isMobile ? 42.0 : 51.0;
    return Container(
      width: isMobile ? 39.w : 52.w,
      height: isMobile ? 43.h : 54.h,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/app_logo.png',
        width: isMobile ? 37.w : 48.w,
        height: size.h,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.gavel,
          size: isMobile ? 26.sp : 32.sp,
          color: const Color(0xFF155e81),
        ),
      ),
    );
  }

  Widget _buildSearch(bool isMobile) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: widget.onSearchTap,
      child: Container(
        height: isMobile ? 36.h : 40.h,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10.w : 13.w),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f7fb),
          border: Border.all(color: const Color(0xFFd8e8f2)),
          borderRadius: BorderRadius.circular(isMobile ? 11.r : 14.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: isMobile ? 17.sp : 19.sp,
              color: const Color(0xFF2d7894),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                loc.search_products_brands_ucf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 11.sp : 13.sp,
                  color: const Color(0xFF6b8a9e),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(
          icon: Icons.chat_bubble_outline_rounded,
          onTap: widget.onMessagesTap,
          isMobile: isMobile,
          showDot: widget.hasUnreadMessages,
        ),
        SizedBox(width: isMobile ? 5.w : 9.w),
        _iconBtn(
          icon: Icons.notifications_none_rounded,
          onTap: widget.onNotificationsTap,
          isMobile: isMobile,
          showDot: widget.hasUnreadNotifications,
        ),
        SizedBox(width: isMobile ? 5.w : 9.w),
        _iconBtn(
          icon: Icons.card_giftcard_rounded,
          onTap: widget.onRewardsTap,
          isMobile: isMobile,
          showDot: false,
          isGift: true,
        ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isMobile,
    bool showDot = false,
    bool isGift = false,
  }) {
    final size = isMobile ? 33.w : 41.w;
    final iconSize = isMobile ? 17.sp : 19.sp;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: isMobile ? 35.h : 41.h,
            decoration: BoxDecoration(
              color: isGift ? const Color(0xFFe8f9f5) : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 10.r : 13.r),
              border: Border.all(
                color: isGift
                    ? const Color(0xFFbfeae2)
                    : const Color(0xFFd7e7f1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isGift ? const Color(0xFF0b9f98) : const Color(0xFF185275),
            ),
          ),
          if (showDot)
            Positioned(
              right: isMobile ? 5.w : 7.w,
              top: isMobile ? 5.h : 7.h,
              child: Container(
                width: isMobile ? 6.w : 7.w,
                height: isMobile ? 6.w : 7.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFf1786e),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHamburger(bool isMobile) {
    return GestureDetector(
      key: _menuBtnKey,
      onTap: _toggleMenu,
      child: Container(
        width: 41.w,
        height: 41.h,
        decoration: BoxDecoration(
          color: _menuOpen ? const Color(0xFFe7f9f5) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _menuOpen
                ? const Color(0xFF19bbaa)
                : const Color(0xFFcfe5ee),
          ),
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 22.sp,
          color: const Color(0xFF174b70),
        ),
      ),
    );
  }

  Widget _buildMenuPanel(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFd7e8f1)),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x310c3553),
            blurRadius: 40,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 9.h),
            child: Text(
              loc.my_menu_ucf,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF143957),
              ),
            ),
          ),
          _menuLink(loc.home_ucf, () {
            _closeMenu();
          }),
          _menuLink(loc.my_account_ucf, () {
            _closeMenu();
            widget.onAccountTap();
          }),
          _menuLink(loc.notifications_ucf, () {
            _closeMenu();
            widget.onNotificationsTap();
          }),
          _menuLink(loc.messages_ucf, () {
            _closeMenu();
            widget.onMessagesTap();
          }),
          _menuLink(loc.rewards_ucf, () {
            _closeMenu();
            widget.onRewardsTap();
          }),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFe7f8f4),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Text('🪙', style: TextStyle(fontSize: 17.sp, height: 1)),
                SizedBox(width: 7.w),
                Text(
                  widget.isLoggedIn ? '${widget.userBalance}' : '0',
                  style: TextStyle(
                    color: const Color(0xFF154763),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  loc.points_ucf,
                  style: TextStyle(
                    color: const Color(0xFF154763),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5.h),
          if (widget.isLoggedIn)
            _accountRow(
              label: loc.my_account_ucf,
              onTap: () {
                _closeMenu();
                widget.onAccountTap();
              },
            )
          else
            _accountRow(
              label: loc.login_ucf,
              onTap: () {
                _closeMenu();
                widget.onLoginTap();
              },
            ),
        ],
      ),
    );
  }

  Widget _menuLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        margin: EdgeInsets.only(bottom: 3.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF244766),
          ),
        ),
      ),
    );
  }

  Widget _accountRow({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0a88d0), Color(0xFF18d2bc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 15.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF143957),
              ),
            ),
          ],
        ),
      ),
    );
  }
}