import 'package:active_ecommerce_flutter/helpers/addons_helper.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/business_setting_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/presenter/currency_presenter.dart';
import 'package:active_ecommerce_flutter/providers/locale_provider.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';

class Index extends StatefulWidget {
  const Index({super.key, this.goBack = true});
  final bool goBack; // Make it non-nullable with a default value

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  Future<String?> getSharedValueHelperData() async {
    access_token.load().whenComplete(() {
      AuthHelper().fetch_and_set();
    });
    AddonsHelper().setAddonsData();
    BusinessSettingHelper().setBusinessSettingData();
    await app_language.load();
    await app_mobile_language.load();
    await app_language_rtl.load();
    await system_currency.load();
    Provider.of<CurrencyPresenter>(context, listen: false).fetchListData();

    return app_mobile_language.$;
  }

  @override
  void initState() {
    super.initState();
    getSharedValueHelperData().then((value) {
      Future.delayed(const Duration(seconds: 3)).then((value) {
        SystemConfig.isShownSplashScreed = true;
        Provider.of<LocaleProvider>(context, listen: false).setLocale(app_mobile_language.$!);
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemConfig.context ??= context;
    return Scaffold(
      body: SystemConfig.isShownSplashScreed == true
          ? Main(go_back: widget.goBack) // widget.goBack is now non-nullable
          : const SplashScreen(),
    );
  }
}