import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:go_router/go_router.dart';

// Import the data model with a prefix to avoid naming conflict
import '../data_model/user_info_response.dart' as model;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Auctions, 2: Payments, 3: System
  
  // ============ LOCAL STATE (Like ProductDetails pattern) ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  model.UserInformation? _userInfo;  // Store the complete user info response
  
  // Derived notification lists (processed from _userInfo)
  List<model.Notification> _allNotifications = [];
  List<model.Notification> _auctionNotifications = [];
  List<model.Notification> _paymentNotifications = [];
  List<model.Notification> _systemNotifications = [];
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchNotifications();  // Fetch fresh data from API
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ============ FETCH DATA FROM API (Like ProductDetails) ============
  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally like _productDetails
        });
        
        // Process notifications from the stored user info
        _processNotifications();
        
        // Optional: Update global SharedValues for unread count
        unread_notifications_count.$ = _userInfo?.unreadNotificationsCount ?? 0;
        unread_notifications_count.save();
        
        // Save all user data to SharedPreferences for other screens
        if (_userInfo != null) {
          UserDataHelper.saveUserData(_userInfo!);
        }
      } else {
        // Handle empty response
        setState(() {
          _allNotifications = [];
          _auctionNotifications = [];
          _paymentNotifications = [];
          _systemNotifications = [];
        });
      }
    } catch (e) {
      print("Error loading notifications: $e");
      ToastComponent.showDialog('Failed to load notifications');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PROCESS NOTIFICATIONS (Extract from stored user info) ============
  void _processNotifications() {
    if (_userInfo == null) return;
    
    final notifications = _userInfo!.notifications ?? [];
    
    // Auction related: outbid, newbid, point_deduction, bid_placed, etc.
    const auctionTypes = [
      'outbid', 'newbid', 'point_deduction', 'bid_placed', 
      'auction_win', 'auction_lose', 'auction_ending'
    ];
    
    // Payment related: payment_success, payment_failed, etc.
    const paymentTypes = [
      'payment', 'payment_success', 'payment_failed', 'package_purchase',
      'withdrawal', 'withdrawal_success', 'withdrawal_failed'
    ];
    
    setState(() {
      _allNotifications = notifications;
      
      _auctionNotifications = notifications.where((n) {
        return auctionTypes.contains(n.type);
      }).toList();
      
      _paymentNotifications = notifications.where((n) {
        return paymentTypes.contains(n.type);
      }).toList();
      
      _systemNotifications = notifications.where((n) {
        return !auctionTypes.contains(n.type) && !paymentTypes.contains(n.type);
      }).toList();
    });
  }
  
  // ============ PULL TO REFRESH (Like ProductDetails) ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchNotifications();
  }
  
  // Helper to get notification type category
  String _getNotificationType(String type) {
    const auctionTypes = [
      'outbid', 'newbid', 'bid_placed', 'auction_win', 'auction_lose', 'auction_ending'
    ];
    const paymentTypes = [
      'payment', 'payment_success', 'payment_failed', 'package_purchase',
      'withdrawal', 'withdrawal_success', 'withdrawal_failed'
    ];
    
    if (auctionTypes.contains(type)) return 'auction';
    if (paymentTypes.contains(type)) return 'payment';
    if (type == 'point_deduction') return 'point';
    if (type == 'new_chat') return 'chat';
    
    return 'system';
  }
  
  Color _getIconBackgroundColor(String type) {
    final notificationType = _getNotificationType(type);
    switch (notificationType) {
      case 'outbid':
        return const Color(0xFFFFE5E5);
      case 'auction':
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
      case 'auction':
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
      case 'auction':
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
  
  List<model.Notification> _getCurrentNotifications() {
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
  
  Future<void> _markAsRead(int? notificationId) async {
    if (notificationId == null) return;
    
    try {
      // TODO: Call API to mark notification as read
      // await ProfileRepository().markNotificationAsRead(notificationId);
      
      // Reload to update UI
      await _fetchNotifications();
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }
  
  // ============ BUILD UI (Like ProductDetails conditional rendering) ============
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              // Go to home if can't pop
              context.go("/");
            }
          },
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()  // Show shimmer while loading
            : Column(
                children: [
                  _buildTabs(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (currentNotifications.isEmpty)
                              _buildEmptyState()
                            else
                              Column(
                                children: currentNotifications.map((notification) => 
                                  _buildNotificationItem(notification)
                                ).toList(),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return Column(
      children: [
        // Tabs shimmer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => 
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 100,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MyTheme.shimmer_base,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Notification items shimmer
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ShimmerHelper().buildBasicShimmer(height: 80, radius: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabs() {
    final tabs = [
      '${AppLocalizations.of(context)!.all_ucf} (${_allNotifications.length})',
      '${AppLocalizations.of(context)!.auctions_ucf} (${_auctionNotifications.length})',
      '${AppLocalizations.of(context)!.payments_ucf} (${_paymentNotifications.length})',
      '${AppLocalizations.of(context)!.system_ucf} (${_systemNotifications.length})',
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
  
  Widget _buildNotificationItem(model.Notification notification) {
    final type = notification.type ?? 'system';
    final isRead = notification.isRead ?? false;
    
    return GestureDetector(
      onTap: () {
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