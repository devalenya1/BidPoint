import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.activity_ucf,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: MyTheme.accent_color,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: MyTheme.accent_color,
            ),
            const SizedBox(height: 20),
            Text(
              "Activity Page",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MyTheme.accent_color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Coming Soon",
              style: TextStyle(
                fontSize: 14,
                color: MyTheme.font_grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}