import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Auctions, 2: Payments, 3: System
  
  // Demo notifications data
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _auctionNotifications = [];
  List<Map<String, dynamic>> _paymentNotifications = [];
  List<Map<String, dynamic>> _systemNotifications = [];
  
  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }
  
  void _loadDemoData() {
    _allNotifications = [
      {
        'id': 1,
        'type': 'outbid',
        'title': 'You were outbid!',
        'message': 'Someone placed a higher bid on Vintage Rolex Watch',
        'time': DateTime(2024, 5, 15, 14, 30),
        'isRead': false,
        'link': '/auction/1',
      },
      {
        'id': 2,
        'type': 'bid',
        'title': 'Bid placed successfully',
        'message': 'Your bid of $1,250 on iPhone 15 Pro Max has been placed',
        'time': DateTime(2024, 5, 14, 9, 15),
        'isRead': true,
        'link': '/auction/2',
      },
      {
        'id': 3,
        'type': 'ending',
        'title': 'Auction ending soon',
        'message': 'Samsung Galaxy S24 Ultra auction ends in 1 hour',
        'time': DateTime(2024, 5, 13, 20, 0),
        'isRead': false,
        'link': '/auction/3',
      },
      {
        'id': 4,
        'type': 'payment',
        'title': 'Payment successful',
        'message': 'Your payment of \$69.99 for Premium Package has been confirmed',
        'time': DateTime(2024, 5, 12, 11, 45),
        'isRead': true,
        'link': '/payments',
      },
      {
        'id': 5,
        'type': 'system',
        'title': 'Welcome to BidPoint!',
        'message': 'Thank you for joining BidPoint. Start bidding to win amazing items.',
        'time': DateTime(2024, 5, 10, 16, 20),
        'isRead': true,
        'link': '/welcome',
      },
      {
        'id': 6,
        'type': 'profile',
        'title': 'Profile updated',
        'message': 'Your profile information has been successfully updated.',
        'time': DateTime(2024, 5, 9, 10, 0),
        'isRead': false,
        'link': '/profile',
      },
      {
        'id': 7,
        'type': 'bid',
        'title': 'New bid on your auction',
        'message': 'A new bid of \$2,800 has been placed on Canon EOS R5 Camera',
        'time': DateTime(2024, 5, 8, 13, 30),
        'isRead': true,
        'link': '/auction/6',
      },
    ];
    
    // Filter notifications by type
    _auctionNotifications = _allNotifications
        .where((n) => ['outbid', 'bid', 'ending'].contains(n['type']))
        .toList();
    
    _paymentNotifications = _allNotifications
        .where((n) => n['type'] == 'payment')
        .toList();
    
    _systemNotifications = _allNotifications
        .where((n) => !['outbid', 'bid', 'ending', 'payment'].contains(n['type']))
        .toList();
  }
  
  String _getIconClass(String type) {
    switch (type) {
      case 'outbid':
        return 'outbid-icon';
      case 'ending':
        return 'ending-icon';
      case 'bid':
        return 'bid-icon';
      case 'payment':
        return 'payment-icon';
      case 'system':
        return 'system-icon';
      case 'profile':
        return 'profile-icon';
      default:
        return 'system-icon';
    }
  }
  
  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'outbid':
        return const Color(0xFFFFE5E5);
      case 'ending':
        return const Color(0xFFFFF3E0);
      case 'bid':
        return const Color(0xFFE5F6FF);
      case 'payment':
        return const Color(0xFFE5FFE8);
      case 'system':
        return const Color(0xFFE8E8FF);
      case 'profile':
        return const Color(0xFFFFE5F0);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
  
  Color _getIconColor(String type) {
    switch (type) {
      case 'outbid':
        return const Color(0xFFFF3B30);
      case 'ending':
        return const Color(0xFFFF9500);
      case 'bid':
        return const Color(0xFF007AFF);
      case 'payment':
        return const Color(0xFF34C759);
      case 'system':
        return const Color(0xFF5856D6);
      case 'profile':
        return const Color(0xFFFF2D55);
      default:
        return const Color(0xFF64748B);
    }
  }
  
  IconData _getIconData(String type) {
    switch (type) {
      case 'outbid':
        return Icons.trending_down;
      case 'ending':
        return Icons.timer;
      case 'bid':
        return Icons.gavel;
      case 'payment':
        return Icons.payment;
      case 'system':
        return Icons.settings;
      case 'profile':
        return Icons.person;
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
  
  List<Map<String, dynamic>> _getCurrentNotifications() {
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
      body: Column(
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
                    
                    // Pagination (demo - if more than 5 items)
                    if (currentNotifications.length > 5)
                      _buildPagination(),
                    
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
  
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'];
    final isRead = notification['isRead'] as bool;
    
    return GestureDetector(
      onTap: () {
        // Navigate to link
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to: ${notification['link']}'),
            backgroundColor: MyTheme.accent_color,
            duration: const Duration(seconds: 1),
          ),
        );
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
                    notification['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: const TextStyle(
                      fontSize: 13.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification['time']),
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
  
  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}