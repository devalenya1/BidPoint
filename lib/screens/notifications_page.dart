import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Auctions, 2: Payments, 3: System
  
  // Real notifications data from API
  List<dynamic> _allNotifications = [];
  List<dynamic> _auctionNotifications = [];
  List<dynamic> _paymentNotifications = [];
  List<dynamic> _systemNotifications = [];
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _loadNotifications();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      var userInfo = await ProfileRepository().getUserInfoResponse();
      
      if (userInfo.success == true && userInfo.data != null && userInfo.data!.isNotEmpty) {
        final user = userInfo.data![0];
        final notifications = user.notifications ?? [];
        
        setState(() {
          _allNotifications = notifications;
          
          // Filter notifications by type
          // Auction related: outbid, newbid, point_deduction, bid_placed, etc.
          _auctionNotifications = notifications.where((n) {
            final type = n.type ?? '';
            return ['outbid', 'newbid', 'point_deduction', 'bid_placed', 'auction_win', 'auction_lose'].contains(type);
          }).toList();
          
          // Payment related: payment_success, payment_failed, etc.
          _paymentNotifications = notifications.where((n) {
            final type = n.type ?? '';
            return ['payment', 'payment_success', 'payment_failed', 'package_purchase'].contains(type);
          }).toList();
          
          // System related: everything else
          _systemNotifications = notifications.where((n) {
            final type = n.type ?? '';
            return !['outbid', 'newbid', 'point_deduction', 'bid_placed', 'auction_win', 'auction_lose', 
                      'payment', 'payment_success', 'payment_failed', 'package_purchase'].contains(type);
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading notifications: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getNotificationType(String type) {
    // Map notification types to categories
    switch (type) {
      case 'outbid':
        return 'outbid';
      case 'newbid':
      case 'bid_placed':
        return 'bid';
      case 'point_deduction':
        return 'point';
      case 'payment':
      case 'payment_success':
      case 'payment_failed':
      case 'package_purchase':
        return 'payment';
      case 'new_chat':
        return 'chat';
      default:
        return 'system';
    }
  }
  
  Color _getIconBackgroundColor(String type) {
    final notificationType = _getNotificationType(type);
    switch (notificationType) {
      case 'outbid':
        return const Color(0xFFFFE5E5);
      case 'bid':
        return const Color(0xFFE5F6FF);
      case 'point':
        return const Color(0xFFFFF3E0);
      case 'payment':
        return const Color(0xFFE5FFE8);
      case 'chat':
        return const Color(0xFFE8E8FF);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
  
  Color _getIconColor(String type) {
    final notificationType = _getNotificationType(type);
    switch (notificationType) {
      case 'outbid':
        return const Color(0xFFFF3B30);
      case 'bid':
        return const Color(0xFF007AFF);
      case 'point':
        return const Color(0xFFFF9500);
      case 'payment':
        return const Color(0xFF34C759);
      case 'chat':
        return const Color(0xFF5856D6);
      default:
        return const Color(0xFF64748B);
    }
  }
  
  IconData _getIconData(String type) {
    final notificationType = _getNotificationType(type);
    switch (notificationType) {
      case 'outbid':
        return Icons.trending_down;
      case 'bid':
        return Icons.gavel;
      case 'point':
        return Icons.stars;
      case 'payment':
        return Icons.payment;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }
  
  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    String hourFormat = date.hour > 12 ? (date.hour - 12).toString() : date.hour.toString();
    String ampm = date.hour >= 12 ? 'pm' : 'am';
    if (date.hour == 0) hourFormat = '12';
    if (date.hour == 12) hourFormat = '12';
    
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '${months[date.month - 1]} ${date.day} ${date.year}, $hourFormat:$minute $ampm';
  }
  
  List<dynamic> _getCurrentNotifications() {
    switch (_selectedTab) {
      case 1:
        return _auctionNotifications;
      case 2:
        return _paymentNotifications;
      case 3:
        return _systemNotifications;
      default:
        return _allNotifications;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentNotifications = _getCurrentNotifications();
    
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs Section
                _buildTabs(),
                
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Tab Content
                          if (currentNotifications.isEmpty)
                            _buildEmptyState()
                          else
                            Column(
                              children: [
                                ...currentNotifications.map((notification) => 
                                  _buildNotificationItem(notification)
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildTabs() {
    final tabs = [
      AppLocalizations.of(context)!.all_ucf,
      AppLocalizations.of(context)!.auctions_ucf,
      AppLocalizations.of(context)!.payments_ucf,
      AppLocalizations.of(context)!.system_ucf,
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildNotificationItem(dynamic notification) {
    final type = notification.type ?? 'system';
    final isRead = notification.isRead ?? false;
    
    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        _markAsRead(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFF0F0F0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(type),
                size: 20,
                color: _getIconColor(type),
              ),
            ),
            const SizedBox(width: 14),
            
            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message ?? '',
                    style: const TextStyle(
                      fontSize: 13.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.createdAt != null 
                        ? _formatDate(notification.createdAt!)
                        : '',
                    style: const TextStyle(
                      fontSize: 11.2,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            
            // New Badge
            if (!isRead)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context)!.new_ucf,
                  style: const TextStyle(
                    fontSize: 10.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _markAsRead(int? notificationId) async {
    if (notificationId == null) return;
    
    try {
      // TODO: Call API to mark notification as read
      // await ProfileRepository().markNotificationAsRead(notificationId);
      
      // Update local state
      setState(() {
        final index = _allNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          // Create a new object with isRead = true
          final notification = _allNotifications[index];
          // Since we can't modify the original, we'll reload
        }
      });
      
      // Reload to update UI
      await _loadNotifications();
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }
  
  Widget _buildEmptyState() {
    String icon;
    String text;
    
    switch (_selectedTab) {
      case 1:
        icon = '🔔';
        text = AppLocalizations.of(context)!.no_auction_notifications;
        break;
      case 2:
        icon = '💰';
        text = AppLocalizations.of(context)!.no_payment_notifications;
        break;
      case 3:
        icon = '⚙️';
        text = AppLocalizations.of(context)!.no_system_notifications;
        break;
      default:
        icon = '🔔';
        text = AppLocalizations.of(context)!.no_notifications_yet;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}