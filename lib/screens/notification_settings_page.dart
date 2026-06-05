import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Bid Notifications
  bool _newBidNotification = true;
  bool _outbidNotification = true;
  
  // Referral Notifications
  bool _newReferralNotification = true;
  bool _earningNotification = true;
  bool _withdrawalNotification = true;
  
  // Point Notifications
  bool _pointPurchaseNotification = true;
  bool _pointDeductionNotification = true;
  
  // Chat Notifications
  bool _newChatNotification = true;
  
  // Product Notifications
  bool _newProductNotification = true;
  bool _endingSoonNotification = true;
  bool _endedNotification = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header - Matching HTML exactly
          _buildTopHeader(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 30),
              child: Column(
                children: [
                  // Bid Notifications Card
                  _buildNotificationCard(
                    title: 'Bid Notifications',
                    icon: Icons.gavel,
                    children: [
                      _buildNotificationItem(
                        label: 'New bid notification',
                        value: _newBidNotification,
                        onChanged: (val) => setState(() => _newBidNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Outbid notification',
                        value: _outbidNotification,
                        onChanged: (val) => setState(() => _outbidNotification = val),
                      ),
                    ],
                  ),
                  
                  // Referral Notifications Card
                  _buildNotificationCard(
                    title: 'Referral Notifications',
                    icon: Icons.people,
                    children: [
                      _buildNotificationItem(
                        label: 'New referral notification',
                        value: _newReferralNotification,
                        onChanged: (val) => setState(() => _newReferralNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Earning notification',
                        value: _earningNotification,
                        onChanged: (val) => setState(() => _earningNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Withdrawal notification',
                        value: _withdrawalNotification,
                        onChanged: (val) => setState(() => _withdrawalNotification = val),
                      ),
                    ],
                  ),
                  
                  // Point Notifications Card
                  _buildNotificationCard(
                    title: 'Point Notifications',
                    icon: Icons.stars,
                    children: [
                      _buildNotificationItem(
                        label: 'Point Purchase notification',
                        value: _pointPurchaseNotification,
                        onChanged: (val) => setState(() => _pointPurchaseNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Point deduction notification',
                        value: _pointDeductionNotification,
                        onChanged: (val) => setState(() => _pointDeductionNotification = val),
                      ),
                    ],
                  ),
                  
                  // Chat Notifications Card
                  _buildNotificationCard(
                    title: 'Chat Notifications',
                    icon: Icons.chat_bubble_outline,
                    children: [
                      _buildNotificationItem(
                        label: 'New chat notification',
                        value: _newChatNotification,
                        onChanged: (val) => setState(() => _newChatNotification = val),
                      ),
                    ],
                  ),
                  
                  // Product Notifications Card
                  _buildNotificationCard(
                    title: 'Product Notifications',
                    icon: Icons.shopping_bag,
                    children: [
                      _buildNotificationItem(
                        label: 'New product notification',
                        value: _newProductNotification,
                        onChanged: (val) => setState(() => _newProductNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Ending soon notification',
                        value: _endingSoonNotification,
                        onChanged: (val) => setState(() => _endingSoonNotification = val),
                      ),
                      _buildNotificationItem(
                        label: 'Ended notification',
                        value: _endedNotification,
                        onChanged: (val) => setState(() => _endedNotification = val),
                      ),
                    ],
                  ),
                  
                  // Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEEF2F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel/Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          // Title
          const Text(
            'Notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          // Invisible placeholder for balance (matching HTML)
          const SizedBox(width: 36),
        ],
      ),
    );
  }
  
  Widget _buildNotificationCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFEEF2F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEF2F8)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: MyTheme.accent_color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          // Card Body
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF2F8)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
          // Custom Switch matching HTML style
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: value ? MyTheme.accent_color : const Color(0xFFCBD5E1),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: GestureDetector(
        onTap: _saveSettings,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: MyTheme.accent_color,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Text(
            'Save Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification settings saved successfully'),
        backgroundColor: MyTheme.accent_color,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}