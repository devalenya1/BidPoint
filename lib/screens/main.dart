import 'dart:io';
import 'package:active_ecommerce_flutter/custom/aiz_route.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/main.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_flutter/presenter/cart_counter.dart';
import 'package:active_ecommerce_flutter/screens/activity_page.dart';
import 'package:active_ecommerce_flutter/screens/cart.dart';
import 'package:active_ecommerce_flutter/screens/category_list.dart';
import 'package:active_ecommerce_flutter/screens/home.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/points_page.dart';
import 'package:active_ecommerce_flutter/screens/profile.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  Main({Key? key, go_back = true}) : super(key: key);

  late bool go_back;

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  int? _pendingIndex; // Store the index that was trying to be accessed

  BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();
  CartCounter counter = CartCounter();
  var _children = [];

  fetchAll() {
    getCartCount();
  }

  void onTapped(int i) {
    fetchAll();
    
    // Check login for protected routes
    if (!is_logged_in.$ && (i == 2 || i == 3 || i == 4)) {
      // Store the intended index before navigating to login
      _pendingIndex = i;
      
      // Navigate to login and wait for result
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => Login())
      ).then((_) {
        // After returning from login, check if user is now logged in
        if (is_logged_in.$ && _pendingIndex != null) {
          // User logged in successfully, navigate to the intended page
          setState(() {
            _currentIndex = _pendingIndex!;
            _pendingIndex = null;
          });
        } else {
          // User didn't log in, clear pending index
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
    // Initialize children with all 5 pages
    _children = [
      Home(),
      CategoryList(
        slug: "",
        is_base_category: true,
      ),
      PointsPage(),
      ActivityPage(),
      Profile(),
    ];
    
    fetchAll();
    
    // Re-appear statusbar in case it was not there in the previous page
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    super.initState();
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
            textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
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
        textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          extendBody: true,
          body: _children[_currentIndex],
          bottomNavigationBar: SizedBox(
            height: 70,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              onTap: onTapped,
              currentIndex: _currentIndex,
              backgroundColor: Colors.white.withOpacity(0.95),
              unselectedItemColor: const Color.fromRGBO(168, 175, 179, 1),
              selectedItemColor: MyTheme.accent_color,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      "assets/home.png",
                      color: _currentIndex == 0
                          ? MyTheme.accent_color
                          : const Color.fromRGBO(153, 153, 153, 1),
                      height: 16,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.home_ucf,
                ),
                
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      "assets/categories.png",
                      color: _currentIndex == 1
                          ? MyTheme.accent_color
                          : const Color.fromRGBO(153, 153, 153, 1),
                      height: 16,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.categories_ucf,
                ),
                
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      "assets/crown.png",
                      color: _currentIndex == 2
                          ? MyTheme.accent_color
                          : const Color.fromRGBO(153, 153, 153, 1),
                      height: 16,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.points_ucf,
                ),
                
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      "assets/task-square.png",
                      color: _currentIndex == 3
                          ? MyTheme.accent_color
                          : const Color.fromRGBO(153, 153, 153, 1),
                      height: 16,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.activity_ucf,
                ),
                
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      "assets/profile.png",
                      color: _currentIndex == 4
                          ? MyTheme.accent_color
                          : const Color.fromRGBO(153, 153, 153, 1),
                      height: 16,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.profile_ucf,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}