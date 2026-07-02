import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.terms_conditions,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 80.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context)!.terms_conditions_coming_soon,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.terms_conditions_description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommonWebViewScreen(
                        title: AppLocalizations.of(context)!.terms_conditions,
                        url: '${AppConfig.RAW_BASE_URL}/terms', // Adjust URL as needed
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.view_terms_conditions,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}