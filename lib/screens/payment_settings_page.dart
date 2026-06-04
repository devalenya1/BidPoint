import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class PaymentSettingsPage extends StatelessWidget {
  const PaymentSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.payment_settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: MyTheme.accent_color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment,
                size: 60,
                color: MyTheme.accent_color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.coming_soon,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: MyTheme.accent_color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.payment_settings_coming_soon,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}