import 'dart:async';

import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/helpers/main_helpers.dart';
import 'package:active_ecommerce_flutter/middlewares/auth_middleware.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/other_config.dart';
import 'package:active_ecommerce_flutter/presenter/cart_counter.dart';
import 'package:active_ecommerce_flutter/presenter/currency_presenter.dart';
import 'package:active_ecommerce_flutter/providers/locale_provider.dart';
import 'package:active_ecommerce_flutter/screens/all_routes.dart';
import 'package:active_ecommerce_flutter/screens/auction_bidded_products.dart';
import 'package:active_ecommerce_flutter/screens/auction_products.dart';
import 'package:active_ecommerce_flutter/screens/auction_products_details.dart';
import 'package:active_ecommerce_flutter/screens/auction_purchase_history.dart';
import 'package:active_ecommerce_flutter/screens/brand_products.dart';
import 'package:active_ecommerce_flutter/screens/cart.dart';
import 'package:active_ecommerce_flutter/screens/category_list.dart';
import 'package:active_ecommerce_flutter/screens/category_products.dart';
import 'package:active_ecommerce_flutter/screens/coupons.dart';
import 'package:active_ecommerce_flutter/screens/filter.dart';
import 'package:active_ecommerce_flutter/screens/flash_deal_list.dart';
import 'package:active_ecommerce_flutter/screens/flash_deal_products.dart';
import 'package:active_ecommerce_flutter/screens/followed_sellers.dart';
import 'package:active_ecommerce_flutter/screens/index.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/order_details.dart';
import 'package:active_ecommerce_flutter/screens/order_list.dart';
import 'package:active_ecommerce_flutter/screens/package/packages.dart';
import 'package:active_ecommerce_flutter/screens/product_details.dart';
import 'package:active_ecommerce_flutter/screens/profile.dart';
import 'package:active_ecommerce_flutter/screens/registration.dart';
import 'package:active_ecommerce_flutter/screens/seller_details.dart';
import 'package:active_ecommerce_flutter/screens/todays_deal_products.dart';
import 'package:active_ecommerce_flutter/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_value/shared_value.dart';
// ✅ ADD THIS IMPORT
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_config.dart';
import 'lang_config.dart';

main() async {
  print("open");
  WidgetsFlutterBinding.ensureInitialized();
  FlutterDownloader.initialize(
      debug: true,
      // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(
    SharedValue.wrapApp(
      // ✅ WRAP WITH SCREEN UTIL INIT
      ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone 13/14 design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MyApp();
        },
      ),
    ),
  );
}

var routes = GoRouter(
  overridePlatformDefaultLocation: false,
  navigatorKey: OneContext().key,
  initialLocation: "/",
  routes: [
    GoRoute(
        path: '/',
        name: "Home",
        pageBuilder: (BuildContext context, GoRouterState state) =>
            MaterialPage(child: Index()),
        routes: [
          GoRoute(
              path: "product/:slug",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: ProductDetails(
                    slug: getParameter(state, "slug"),
                  ))),
          GoRoute(
              path: "customer-packages",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(child: UpdatePackage())),
          GoRoute(
              path: "users/login",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(child: Login())),
          GoRoute(
              path: "users/registration",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(child: Registration())),
          GoRoute(
              path: "dashboard",
              name: "Profile",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  AIZRoute.rightTransition(Profile())),
          GoRoute(
              path: "auction-product/:slug",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: AuctionProductsDetails(
                    slug: getParameter(state, "slug"),
                  ))),
          GoRoute(
              path: "brand/:slug",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: (BrandProducts(
                    slug: getParameter(state, "slug"),
                  )))),
          GoRoute(
              path: "brands",
              name: "Bands",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: Filter(
                    selected_filter: "brands",
                  ))),
          GoRoute(
              path: "categories",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: (CategoryList(
                    slug: getParameter(state, "slug"),
                  )))),
          GoRoute(
              path: "category/:slug",
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  MaterialPage(
                      child: (CategoryProducts(
                    slug: getParameter(state, "slug"),
                  )))),
        ])
  ],
);

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    routes.routerDelegate.addListener(() {});

    routes.routeInformationProvider.addListener(() {});
    super.initState();
    Future.delayed(Duration.zero).then(
      (value) async {
        Firebase.initializeApp().then((value) {
          if (OtherConfig.USE_PUSH_NOTIFICATION) {
            Future.delayed(Duration(milliseconds: 10), () async {
              PushNotificationService().initialise();
            });
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (context) => CartCounter()),
          ChangeNotifierProvider(create: (context) => CurrencyPresenter()),
        ],
        child: Consumer<LocaleProvider>(builder: (context, provider, snapshot) {
          return MaterialApp.router(
            builder: (context, child) => OneContext().builder(
              context,
              child,
              onGenerateRoute: (route) {
                return MaterialPageRoute(builder: (context2) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Builder(
                      builder: (innerContext) {
                        OneContext().context = innerContext;
                        return child!;
                      },
                    ),
                  );
                });
              },
              onUnknownRoute: (route) {
                print("abc ${route.name}");
                return MaterialPageRoute(builder: (context) => child!);
              },
            ),
            routerConfig: routes,
            title: AppConfig.app_name,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: MyTheme.white,
              scaffoldBackgroundColor: MyTheme.white,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: "PublicSansSerif",
              textTheme: MyTheme.textTheme1,
              fontFamilyFallback: ['NotoSans'],
            ),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            locale: provider.locale,
            supportedLocales: LangConfig().supportedLocales(),
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (AppLocalizations.delegate.isSupported(deviceLocale!)) {
                return deviceLocale;
              }
              return const Locale('en');
            },
          );
        }));
  }
}