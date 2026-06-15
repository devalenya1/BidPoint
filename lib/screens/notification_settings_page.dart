import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'dart:convert';

// Import the data model
import '../data_model/user_info_response.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSaving = false;
  
  UserInformation? _userInfo;
  
  // Notification settings
  Map<String, bool> _notificationSettings = {
    // Bid Notifications
    'new_bid': true,
    'outbid': true,
    
    // Referral Notifications
    'new_referral': true,
    'earning': true,
    'withdrawal': true,
    
    // Point Notifications
    'point_purchase': true,
    'point_deduction': true,
    
    // Chat Notifications
    'new_chat': true,
    
    // Product Notifications
    'new_product': true,
    'ending_soon': true,
    'ended': true,
  };
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchNotificationSettings();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ============ FETCH NOTIFICATION SETTINGS FROM API ============
  Future<void> _fetchNotificationSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];
        });
        
        _loadSettingsFromUserInfo();
      } else {
        _useDefaultSettings();
      }
    } catch (e) {
      print("Error loading notification settings: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.failed_to_load_notification_settings);
      _useDefaultSettings();
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  void _loadSettingsFromUserInfo() {
    // Load from user preferences if available
    // For now, use defaults
    _useDefaultSettings();
  }
  
  void _useDefaultSettings() {
    setState(() {
      _notificationSettings = {
        'new_bid': true,
        'outbid': true,
        'new_referral': true,
        'earning': true,
        'withdrawal': true,
        'point_purchase': true,
        'point_deduction': true,
        'new_chat': true,
        'new_product': true,
        'ending_soon': true,
        'ended': true,
      };
    });
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchNotificationSettings();
  }
  
  // ============ SAVE SETTINGS TO SERVER ============
  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await ProfileRepository().updateNotificationSettings(_notificationSettings);
      
      if (response['success'] == true) {
        ToastComponent.showDialog(
          response['message'] ?? AppLocalizations.of(context)!.notification_settings_saved_successfully,
        );
        
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ToastComponent.showDialog(
          response['message'] ?? AppLocalizations.of(context)!.notification_settings_save_failed,
        );
      }
    } catch (e) {
      print("Error saving notification settings: $e");
      ToastComponent.showDialog(AppLocalizations.of(context)!.notification_settings_save_failed);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  void _updateSetting(String key, bool value) {
    setState(() {
      _notificationSettings[key] = value;
    });
  }
  
  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notification_ucf,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 30),
                child: Column(
                  children: [
                    // Bid Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.bid_notifications,
                      icon: Icons.gavel,
                      children: [
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.new_bid_notification,
                          key: 'new_bid',
                          value: _notificationSettings['new_bid'] ?? true,
                          onChanged: (val) => _updateSetting('new_bid', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.outbid_notification,
                          key: 'outbid',
                          value: _notificationSettings['outbid'] ?? true,
                          onChanged: (val) => _updateSetting('outbid', val),
                        ),
                      ],
                    ),
                    
                    // Referral Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.referral_notifications,
                      icon: Icons.people,
                      children: [
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.new_referral_notification,
                          key: 'new_referral',
                          value: _notificationSettings['new_referral'] ?? true,
                          onChanged: (val) => _updateSetting('new_referral', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.earning_notification,
                          key: 'earning',
                          value: _notificationSettings['earning'] ?? true,
                          onChanged: (val) => _updateSetting('earning', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.withdrawal_notification,
                          key: 'withdrawal',
                          value: _notificationSettings['withdrawal'] ?? true,
                          onChanged: (val) => _updateSetting('withdrawal', val),
                        ),
                      ],
                    ),
                    
                    // Point Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.point_notifications,
                      icon: Icons.stars,
                      children: [
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.point_purchase_notification,
                          key: 'point_purchase',
                          value: _notificationSettings['point_purchase'] ?? true,
                          onChanged: (val) => _updateSetting('point_purchase', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.point_deduction_notification,
                          key: 'point_deduction',
                          value: _notificationSettings['point_deduction'] ?? true,
                          onChanged: (val) => _updateSetting('point_deduction', val),
                        ),
                      ],
                    ),
                    
                    // Chat Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.chat_notifications,
                      icon: Icons.chat_bubble_outline,
                      children: [
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.new_chat_notification,
                          key: 'new_chat',
                          value: _notificationSettings['new_chat'] ?? true,
                          onChanged: (val) => _updateSetting('new_chat', val),
                        ),
                      ],
                    ),
                    
                    // Product Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.product_notifications,
                      icon: Icons.shopping_bag,
                      children: [
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.new_product_notification,
                          key: 'new_product',
                          value: _notificationSettings['new_product'] ?? true,
                          onChanged: (val) => _updateSetting('new_product', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.ending_soon_notification,
                          key: 'ending_soon',
                          value: _notificationSettings['ending_soon'] ?? true,
                          onChanged: (val) => _updateSetting('ending_soon', val),
                        ),
                        _buildNotificationItem(
                          label: AppLocalizations.of(context)!.ended_notification,
                          key: 'ended',
                          value: _notificationSettings['ended'] ?? true,
                          onChanged: (val) => _updateSetting('ended', val),
                        ),
                      ],
                    ),
                    
                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 30),
      child: Column(
        children: [
          _buildShimmerCard(),
          const SizedBox(height: 12),
          _buildShimmerCard(),
          const SizedBox(height: 12),
          _buildShimmerCard(),
          const SizedBox(height: 12),
          _buildShimmerCard(),
          const SizedBox(height: 12),
          _buildShimmerCard(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerHelper().buildBasicShimmer(height: 48, radius: 50),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFEEF2F8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ShimmerHelper().buildBasicShimmer(height: 28, width: 28, radius: 7),
                const SizedBox(width: 10),
                ShimmerHelper().buildBasicShimmer(height: 20, width: 150),
              ],
            ),
          ),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerHelper().buildBasicShimmer(height: 16, width: 180),
                ShimmerHelper().buildBasicShimmer(height: 24, width: 44, radius: 34),
              ],
            ),
          )),
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
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem({
    required String label,
    required String key,
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          // Custom Switch
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
        onTap: _isSaving ? null : _saveSettings,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _isSaving ? MyTheme.medium_grey : MyTheme.accent_color,
            borderRadius: BorderRadius.circular(50),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.save_settings,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}