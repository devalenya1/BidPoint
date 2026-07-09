import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/user_data_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import the data model with a prefix to avoid naming conflict
import '../data_model/user_info_response.dart' as model;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Auctions, 2: Payments, 3: System

  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isMarkingAllAsRead = false;
  bool _isLoadingMore = false;

  model.UserInformation? _userInfo; // Store the complete user info response

  // ============ PAGINATION STATE ============
  int _currentNotificationPage = 1;
  int _currentPointPage = 1;
  int _currentCashPage = 1;
  int _currentWithdrawPage = 1;
  bool _hasMoreNotifications = true;
  bool _hasMorePoints = true;
  bool _hasMoreCash = true;

  // ============ CACHED LISTS FOR INFINITE SCROLL ============
  List<model.Notification> _allNotifications = [];
  List<model.Notification> _auctionNotifications = [];
  List<model.Notification> _paymentNotifications = [];
  List<model.Notification> _systemNotifications = [];

  // Track if initial load is complete for each tab
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchNotifications(); // Fetch fresh data from API
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============ FETCH DATA FROM API WITH PAGINATION ============
  Future<void> _fetchNotifications({bool loadMore = false}) async {
    try {
      if (loadMore) {
        if (_isLoadingMore || !_hasMoreNotifications) return;
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _currentNotificationPage = 1;
          _hasMoreNotifications = true;
          _allNotifications.clear();
          _auctionNotifications.clear();
          _paymentNotifications.clear();
          _systemNotifications.clear();
        });
      }

      final page = loadMore ? _currentNotificationPage + 1 : 1;

      var response = await ProfileRepository().getUserInfoResponse(
        notificationPage: page,
        notificationPerPage: 10,
        pointPage: _currentPointPage,
        pointPerPage: 10,
        cashPage: _currentCashPage,
        cashPerPage: 10,
        withdrawPage: _currentWithdrawPage,
        withdrawPerPage: 10,
      );

      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final newUserInfo = response.data![0];

        // Update pagination info
        final pagination = newUserInfo.notificationsPagination;
        if (pagination != null) {
          _hasMoreNotifications = pagination.hasNext;
          _currentNotificationPage = pagination.currentPage;
        }

        // Process notifications
        final newNotifications = newUserInfo.notifications ?? [];

        setState(() {
          if (loadMore) {
            // Append to existing lists
            _allNotifications.addAll(newNotifications);
            _updateFilteredLists();
          } else {
            // Replace entire user info and lists
            _userInfo = newUserInfo;
            _allNotifications = newNotifications;
            _updateFilteredLists();

            // Update global unread count
            unread_notifications_count.$ = _userInfo?.unreadNotificationsCount ?? 0;
            unread_notifications_count.save();

            // Save user data
            if (_userInfo != null) {
              UserDataHelper.saveUserData(_userInfo!);
            }
          }
        });

        // Mark all as read in background (only on first load)
        if (!loadMore) {
          _markAllAsReadInBackground();
        }
      } else {
        if (!loadMore) {
          setState(() {
            _allNotifications = [];
            _auctionNotifications = [];
            _paymentNotifications = [];
            _systemNotifications = [];
          });
        }
      }
    } catch (e) {
      print("Error loading notifications: $e");
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_load_notifications);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _initialLoadComplete = true;
      });
    }
  }

  // ============ UPDATE FILTERED LISTS ============
  void _updateFilteredLists() {
    // Auction related: outbid, newbid, point_deduction, bid_placed, etc.
    const auctionTypes = [
      'outbid',
      'newbid',
      'point_deduction',
      'bid_placed',
      'auction_win',
      'auction_lose',
      'auction_ending'
    ];

    // Payment related: payment_success, payment_failed, etc.
    const paymentTypes = [
      'payment',
      'payment_success',
      'payment_failed',
      'package_purchase',
      'withdrawal',
      'withdrawal_success',
      'withdrawal_failed'
    ];

    _auctionNotifications = _allNotifications.where((n) {
      return auctionTypes.contains(n.type);
    }).toList();

    _paymentNotifications = _allNotifications.where((n) {
      return paymentTypes.contains(n.type);
    }).toList();

    _systemNotifications = _allNotifications.where((n) {
      return !auctionTypes.contains(n.type) && !paymentTypes.contains(n.type);
    }).toList();
  }

  // ============ LOAD MORE NOTIFICATIONS (INFINITE SCROLL) ============
  Future<void> _loadMoreNotifications() async {
    if (!_hasMoreNotifications || _isLoadingMore) return;
    await _fetchNotifications(loadMore: true);
  }

  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchNotifications(loadMore: false);
  }

  // ============ MARK ALL AS READ (BACKGROUND - NO UI BLOCKING) ============
  void _markAllAsReadInBackground() {
    if (_userInfo == null || (_userInfo?.unreadNotificationsCount ?? 0) <= 0) {
      return;
    }

    if (_isMarkingAllAsRead) return;

    setState(() {
      _isMarkingAllAsRead = true;
    });

    // Optimistic update - mark all as read locally
    setState(() {
      _allNotifications = _allNotifications.map((n) {
        return model.Notification(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          readAt: DateTime.now().toIso8601String(),
          createdAt: n.createdAt,
          isRead: true,
        );
      }).toList();

      _updateFilteredLists();

      unread_notifications_count.$ = 0;
      unread_notifications_count.save();
    });

    // Send background request
    _sendMarkAllAsReadRequest();
  }

  void _sendMarkAllAsReadRequest() async {
    try {
      final Map<String, dynamic> response = await ProfileRepository().markAllNotificationsAsRead();

      setState(() {
        _isMarkingAllAsRead = false;
      });

      if (response['success'] == true) {
        print('✅ All notifications marked as read in background');
      } else {
        print('❌ Failed to mark all notifications as read: ${response['message']}');
        ToastComponent.showWarning(response['message'] ?? AppLocalizations.of(context)!.failed_to_mark_notifications_read);
        await _fetchNotifications(loadMore: false);
      }
    } catch (e) {
      print('❌ Failed to mark all notifications as read: $e');
      ToastComponent.showError(AppLocalizations.of(context)!.failed_to_mark_notifications_read);
      setState(() {
        _isMarkingAllAsRead = false;
      });
      await _fetchNotifications(loadMore: false);
    }
  }

  // ============ HELPER METHODS ============
  String _getNotificationType(String type) {
    const auctionTypes = [
      'outbid',
      'newbid',
      'bid_placed',
      'auction_win',
      'auction_lose',
      'auction_ending'
    ];
    const paymentTypes = [
      'payment',
      'payment_success',
      'payment_failed',
      'package_purchase',
      'withdrawal',
      'withdrawal_success',
      'withdrawal_failed'
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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

  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    final currentNotifications = _getCurrentNotifications();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notification_ucf,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              context.go("/");
            }
          },
        ),
        actions: [
          // Mark all as read button (only show if there are unread notifications)
          if ((_userInfo?.unreadNotificationsCount ?? 0) > 0)
            IconButton(
              icon: Icon(Icons.done_all, size: 22.sp, color: MyTheme.accent_color),
              onPressed: _isMarkingAllAsRead ? null : _markAllAsReadInBackground,
              tooltip: AppLocalizations.of(context)!.mark_all_read,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : Column(
                children: [
                  _buildTabs(),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Detect when user scrolls to bottom
                        if (!_isLoadingMore &&
                            _hasMoreNotifications &&
                            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                          _loadMoreNotifications();
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            if (currentNotifications.isEmpty)
                              _buildEmptyState()
                            else
                              Column(
                                children: [
                                  ...currentNotifications.map((notification) =>
                                    _buildNotificationItem(notification)
                                  ).toList(),
                                  // Loading more indicator
                                  if (_isLoadingMore)
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      child: CircularProgressIndicator(
                                        color: MyTheme.accent_color,
                                        strokeWidth: 2.w,
                                      ),
                                    ),
                                  // End of list indicator
                                  if (!_hasMoreNotifications && currentNotifications.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      child: Text(
                                        AppLocalizations.of(context)!.no_more_notifications,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF999999),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            SizedBox(height: 20.h),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          margin: EdgeInsets.only(bottom: 16.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) =>
                Container(
                  margin: EdgeInsets.only(right: 4.w),
                  width: 100.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: MyTheme.shimmer_base,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Notification items shimmer
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: ShimmerHelper().buildBasicShimmer(height: 80.h, radius: 12.r),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(bottom: 16.h),
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
                margin: EdgeInsets.only(right: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isActive ? MyTheme.accent_color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 14.sp,
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

  // ============================================================
  // UPDATED: Notification Item with "New" Badge
  // ============================================================
  Widget _buildNotificationItem(model.Notification notification) {
    final type = notification.type ?? 'system';
    final isRead = notification.isRead ?? false; // ✅ Now correctly computed from readAt

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF0F0F0),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Icon
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(type),
              size: 20.sp,
              color: _getIconColor(type),
            ),
          ),
          SizedBox(width: 14.w),

          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? '',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.message ?? '',
                  style: TextStyle(
                    fontSize: 13.6.sp,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  notification.createdAt != null
                      ? _formatDate(notification.createdAt!)
                      : '',
                  style: TextStyle(
                    fontSize: 11.2.sp,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // ✅ "NEW" BADGE - Shows when read_at is null (unread)
          // ============================================================
          if (!isRead)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30), // Red color
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.new_ucf,
                style: TextStyle(
                  fontSize: 10.4.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text( 
            icon,
            style: TextStyle(fontSize: 48.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}