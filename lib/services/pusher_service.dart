import 'dart:async';
import 'dart:convert';

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Central Pusher (realtime) client for the BidPoint app.
///
/// The web version of BidPoint already runs on Pusher, the mobile app talks
/// to exactly the same channels:
///
///  * `product.{id}`                  (public)   → `new-bid`, `new-comment`
///  * `private-auction-user.{userId}` (private)  → `auction-balance-updated`,
///                                                      `user-balance-updated`,
///                                                      `new-notification`,
///                                                      `new-message`
///
/// Everything that used to poll the REST API for live auction data now
/// listens to these streams instead.
class PusherService {
  PusherService._internal();

  static final PusherService instance = PusherService._internal();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _initialized = false;
  bool _connecting = false;
  String? _authToken;

  /// Reference counted product channels, several widgets can watch the same
  /// live auction at the same time.
  final Map<int, int> _productChannels = {};

  /// The private channel of the signed in user.
  int? _userChannelId;

  final Set<String> _activeChannels = {};

  final StreamController<Map<String, dynamic>> _bidController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _commentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _balanceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _subscribedController =
      StreamController<String>.broadcast();

  /// Fires for every `new-bid` event of any subscribed product.
  Stream<Map<String, dynamic>> get onBid => _bidController.stream;

  /// Fires for every `new-comment` event of any subscribed product.
  Stream<Map<String, dynamic>> get onComment => _commentController.stream;

  /// Fires for every point balance update of the signed in user.
  Stream<Map<String, dynamic>> get onBalance => _balanceController.stream;

  /// Fires for every new customer notification of the signed in user.
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  /// Fires for every new chat message addressed to the signed in user.
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  /// Fires with the channel name every time a subscription succeeded.
  Stream<String> get onSubscriptionSucceeded => _subscribedController.stream;

  bool get isConnected =>
      _pusher.connectionState.toUpperCase() == 'CONNECTED';

  bool get isInitialized => _initialized;

  // ================================================================
  // CONNECTION
  // ================================================================

  /// Connects (or reconnects) to Pusher.
  ///
  /// The private channel authorization endpoint needs the sanctum token of the
  /// signed in user, so the client is re-initialized whenever the token
  /// changes (login / logout).
  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;

    try {
      final token = access_token.$ ?? '';
      final needsReinit = !_initialized || _authToken != token;

      _authToken = token;

      if (needsReinit) {
        _initialized = true;
        _activeChannels.clear();

        await _pusher.init(
          apiKey: AppConfig.PUSHER_APP_KEY,
          cluster: AppConfig.PUSHER_APP_CLUSTER,
          useTLS: AppConfig.PUSHER_USE_TLS,
          // The native SDKs cannot send custom headers, therefore the sanctum
          // token travels inside the query string of the auth endpoint.
          authEndpoint: token.isEmpty
              ? null
              : '${AppConfig.BASE_URL}/broadcasting/auth'
                  '?api_token=${Uri.encodeQueryComponent(token)}',
          onEvent: _handleEvent,
          onConnectionStateChange: _handleConnectionStateChange,
          onSubscriptionSucceeded: (channelName, data) {
            _subscribedController.add(channelName);
          },
          onSubscriptionError: (message, error) {
            print('⚠️ Pusher subscription error: $message $error');
          },
          onError: (message, code, error) {
            print('⚠️ Pusher error: $message ($code) $error');
          },
        );
      }

      // Without a token the private channel of the user cannot be used.
      if (token.isEmpty) {
        _userChannelId = null;
      }

      await _pusher.connect();

      // Re-create every subscription, the native client is rebuilt on re-init.
      await _resubscribeAll();
    } catch (e) {
      print('❌ Pusher connect error: $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> _resubscribeAll() async {
    for (final productId in _productChannels.keys.toList()) {
      await _subscribeChannel('product.$productId');
    }
    final userId = _userChannelId;
    if (userId != null && is_logged_in.$ == true) {
      await _subscribeChannel('private-auction-user.$userId');
    }
  }

  void _handleConnectionStateChange(String currentState, String previousState) {
    print('📡 Pusher connection: $previousState -> $currentState');
  }

  // ================================================================
  // EVENTS
  // ================================================================

  void _handleEvent(PusherEvent event) {
    final data = _decodePayload(event.data);

    switch (event.eventName) {
      case 'new-bid':
        _bidController.add(data);
        break;
      case 'new-comment':
        _commentController.add(data);
        break;
      case 'auction-balance-updated':
      case 'user-balance-updated':
        _balanceController.add(data);
        break;
      case 'new-notification':
        _notificationController.add(data);
        break;
      case 'new-message':
        _messageController.add(data);
        break;
      default:
        break;
    }
  }

  Map<String, dynamic> _decodePayload(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // ================================================================
  // SUBSCRIPTIONS
  // ================================================================

  /// Subscribes to the live auction channel of a product.
  ///
  /// Returns true when a new channel subscription was created. When the
  /// channel was already joined no "subscription succeeded" event arrives, so
  /// the caller has to refresh the state on its own.
  Future<bool> subscribeProduct(int productId) async {
    if (productId <= 0) return false;

    _productChannels[productId] = (_productChannels[productId] ?? 0) + 1;

    await connect();
    return _subscribeChannel('product.$productId');
  }

  /// Releases one subscription of the live auction channel of a product.
  Future<void> unsubscribeProduct(int productId) async {
    final count = _productChannels[productId];
    if (count == null) return;

    if (count > 1) {
      _productChannels[productId] = count - 1;
      return;
    }

    _productChannels.remove(productId);
    await _unsubscribeChannel('product.$productId');
  }

  /// Joins the private channel of the signed in user. It carries the live
  /// point balance, the customer notifications and the chat messages.
  ///
  /// The call is idempotent, several screens can call it.
  Future<void> subscribeUserChannel() async {
    if (is_logged_in.$ != true) return;

    final id = user_id.$;
    if (id == null || id <= 0) return;

    await connect();

    if (_userChannelId == id) {
      await _subscribeChannel('private-auction-user.$id');
      return;
    }

    // The user changed, leave the previous private channel.
    final previous = _userChannelId;
    if (previous != null) {
      _userChannelId = null;
      await _unsubscribeChannel('private-auction-user.$previous');
    }

    _userChannelId = id;
    await _subscribeChannel('private-auction-user.$id');
  }

  /// Leaves the private channel of the signed in user.
  Future<void> unsubscribeUserChannel() async {
    final id = _userChannelId;
    if (id == null) return;

    _userChannelId = null;
    await _unsubscribeChannel('private-auction-user.$id');
  }

  Future<bool> _subscribeChannel(String channelName) async {
    if (_activeChannels.contains(channelName)) return false;

    try {
      await _pusher.subscribe(channelName: channelName);
      _activeChannels.add(channelName);
      return true;
    } catch (e) {
      print('❌ Pusher subscribe error ($channelName): $e');
      return false;
    }
  }

  Future<void> _unsubscribeChannel(String channelName) async {
    if (!_activeChannels.remove(channelName)) return;

    try {
      await _pusher.unsubscribe(channelName: channelName);
    } catch (e) {
      print('❌ Pusher unsubscribe error ($channelName): $e');
    }
  }

  // ================================================================
  // CLEAN UP
  // ================================================================

  Future<void> disconnect() async {
    _productChannels.clear();
    _userChannelId = null;
    _activeChannels.clear();

    try {
      await _pusher.disconnect();
    } catch (e) {
      print('❌ Pusher disconnect error: $e');
    }
  }
}
