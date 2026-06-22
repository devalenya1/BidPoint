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
  
  // Notification settings - matching backend field names
  Map<String, bool> _notificationSettings = {
    // Bid Notifications
    'new_bid_notification': true,
    'outbid_notification': true,
    
    // Referral Notifications
    'new_referral_notification': true,
    'earning_notification': true,
    'withdrawal_notification': true,
    
    // Point Notifications
    'point_purchase_notification': true,
    'point_deduction_notification': true,
    
    // Chat Notifications
    'new_chat_notification': true,
    
    // Product Notifications
    'new_product_notification': true,
    'ending_soon_notification': true,
    'ended_notification': true,
  };
  
  // Display names mapping
  final Map<String, String> _displayNames = {
    'new_bid_notification': 'New Bid Notification',
    'outbid_notification': 'Outbid Notification',
    'new_referral_notification': 'New Referral Notification',
    'earning_notification': 'Earning Notification',
    'withdrawal_notification': 'Withdrawal Notification',
    'point_purchase_notification': 'Point Purchase Notification',
    'point_deduction_notification': 'Point Deduction Notification',
    'new_chat_notification': 'New Chat Notification',
    'new_product_notification': 'New Product Notification',
    'ending_soon_notification': 'Ending Soon Notification',
    'ended_notification': 'Ended Notification',
  };
  
  final ProfileRepository _profileRepository = ProfileRepository();

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
      
      final response = await _profileRepository.getNotificationSettings();
      
      if (response['success'] == true && response['settings'] != null) {
        final settings = response['settings'] as Map<String, dynamic>;
        
        // Update local settings with fetched values
        setState(() {
          for (var key in _notificationSettings.keys) {
            if (settings.containsKey(key)) {
              // Convert to bool (handle int values from database)
              final value = settings[key];
              if (value is bool) {
                _notificationSettings[key] = value;
              } else if (value is int) {
                _notificationSettings[key] = value == 1;
              } else if (value is String) {
                _notificationSettings[key] = value == '1' || value == 'true';
              }
            }
          }
          _isLoading = false;
        });
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
  
  void _useDefaultSettings() {
    setState(() {
      _notificationSettings = {
        'new_bid_notification': true,
        'outbid_notification': true,
        'new_referral_notification': true,
        'earning_notification': true,
        'withdrawal_notification': true,
        'point_purchase_notification': true,
        'point_deduction_notification': true,
        'new_chat_notification': true,
        'new_product_notification': true,
        'ending_soon_notification': true,
        'ended_notification': true,
      };
      _isLoading = false;
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
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await _profileRepository.updateNotificationSettings(_notificationSettings);
      
      if (response['success'] == true) {
        ToastComponent.showDialog(
          response['message'] ?? AppLocalizations.of(context)!.notification_settings_saved_successfully,
        );
        
        if (mounted) {
          // Refresh settings after save
          await _fetchNotificationSettings();
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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  void _updateSetting(String key, bool value) {
    setState(() {
      _notificationSettings[key] = value;
    });
  }
  
  // ============ HELPER METHOD FOR DISPLAY NAME ============
  String _getDisplayName(String key) {
    // Check if we have a localized version
    final localKey = key.replaceAll('_notification', '');
    final localizedMap = {
      'new_bid': AppLocalizations.of(context)!.new_bid_notification,
      'outbid': AppLocalizations.of(context)!.outbid_notification,
      'new_referral': AppLocalizations.of(context)!.new_referral_notification,
      'earning': AppLocalizations.of(context)!.earning_notification,
      'withdrawal': AppLocalizations.of(context)!.withdrawal_notification,
      'point_purchase': AppLocalizations.of(context)!.point_purchase_notification,
      'point_deduction': AppLocalizations.of(context)!.point_deduction_notification,
      'new_chat': AppLocalizations.of(context)!.new_chat_notification,
      'new_product': AppLocalizations.of(context)!.new_product_notification,
      'ending_soon': AppLocalizations.of(context)!.ending_soon_notification,
      'ended': AppLocalizations.of(context)!.ended_notification,
    };
    
    return localizedMap[localKey] ?? _displayNames[key] ?? key;
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
                      keys: ['new_bid_notification', 'outbid_notification'],
                    ),
                    
                    // Referral Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.referral_notifications,
                      icon: Icons.people,
                      keys: ['new_referral_notification', 'earning_notification', 'withdrawal_notification'],
                    ),
                    
                    // Point Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.point_notifications,
                      icon: Icons.stars,
                      keys: ['point_purchase_notification', 'point_deduction_notification'],
                    ),
                    
                    // Chat Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.chat_notifications,
                      icon: Icons.chat_bubble_outline,
                      keys: ['new_chat_notification'],
                    ),
                    
                    // Product Notifications Card
                    _buildNotificationCard(
                      title: AppLocalizations.of(context)!.product_notifications,
                      icon: Icons.shopping_bag,
                      keys: ['new_product_notification', 'ending_soon_notification', 'ended_notification'],
                    ),
                    
                    // Save Button - Same loader as HotAuctionCard
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
    required List<String> keys,
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
          // Notification Items
          ...keys.map((key) => _buildNotificationItem(
            label: _getDisplayName(key),
            key: key,
            value: _notificationSettings[key] ?? true,
            onChanged: (val) => _updateSetting(key, val),
          )),
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
  
  // ============ SAVE BUTTON - SAME LOADER AS HOTAUCTIONCARD ============
  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveSettings,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _isSaving ? MyTheme.medium_grey : MyTheme.accent_color,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
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
      ),
    );
  }
}