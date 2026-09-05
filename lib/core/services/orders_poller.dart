import 'dart:async';
import 'dart:developer' as dev;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/utils/order_status.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/presentation/widgets/new_order_alert_dialog.dart';
import 'package:local_basket_business/routes/app_router.dart';

/// Polls the store's orders and, whenever a fresh order is waiting for the
/// merchant, plays a looping alert sound and shows a blocking popup — from
/// anywhere in the app.
void _log(String m) {
  // Not throttled like debugPrint, and visible in `flutter run` / logcat.
  dev.log(m, name: 'OrdersPoller');
  // ignore: avoid_print
  print('>>> ORDERS_POLLER: $m');
}

class OrdersPoller {
  OrdersPoller(this._repo, this._sessionStore) {
    _log('constructed');
  }

  final OrdersRepository _repo;
  final SessionStore _sessionStore;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioContextSet = false;

  /// Ids we've already popped for, so an un-accepted order doesn't re-trigger
  /// the dialog on every poll.
  final Set<String> _handledOrderIds = <String>{};

  /// orderId → the last status the merchant set from this app (popup or the
  /// Orders list). Once set, this wins over whatever the backend reports, so
  /// the card walks CONFIRMED → PREPARING → READY at the merchant's pace and
  /// isn't yanked ahead by auto-assignment. Shared with the Orders tab.
  final Map<String, String> merchantStatus = <String, String>{};

  void recordMerchantStatus(String orderId, String status) {
    if (orderId.isNotEmpty) merchantStatus[orderId] = status;
  }
  bool _showingDialog = false;
  bool _soundPlaying = false;
  bool _isTickInFlight = false;

  static const Duration defaultInterval = Duration(seconds: 15);

  void start({Duration interval = defaultInterval}) {
    _log('start() timer=${_timer != null}');
    _isTickInFlight = false;
    _showingDialog = false;
    _timer ??= Timer.periodic(interval, (_) => _tick());
    // Run one now and one just after the first frame, so a pending order is
    // caught without waiting a full interval and once the navigator exists.
    _tick();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run a check immediately (e.g. right after the Orders list refreshes).
  void checkNow() {
    _log('checkNow()');
    _tick();
  }

  /// Direct entry point for a screen that already has the fresh list + a live
  /// [BuildContext] (belt-and-suspenders for the Orders screen).
  void alertFromScreen(List<Map<String, dynamic>> items, BuildContext context) {
    try {
      final awaiting = items
          .where((o) => isAwaitingAcceptance(_statusOf(o)))
          .toList()
        ..sort((a, b) => _createdMillis(b).compareTo(_createdMillis(a)));
      _log('alertFromScreen awaiting=${awaiting.length} showing=$_showingDialog');
      final unhandled = awaiting
          .where((o) => !_handledOrderIds.contains(_orderId(o)))
          .toList();
      if (unhandled.isNotEmpty && !_showingDialog) {
        _presentAlert(unhandled.first, context);
      }
    } catch (e) {
      _log('alertFromScreen error: $e');
    }
  }

  /// Clears per-session state — call on logout.
  void reset() {
    _handledOrderIds.clear();
    merchantStatus.clear();
    _showingDialog = false;
    _stopSound();
  }

  String _orderId(Map<String, dynamic> o) =>
      (o['id'] ?? o['orderId'] ?? '').toString();

  String _statusOf(Map<String, dynamic> o) {
    final local = merchantStatus[_orderId(o)];
    if (local != null) return local;
    return (o['orderStatus'] ?? o['status'] ?? '').toString();
  }

  int _createdMillis(Map<String, dynamic> o) {
    final raw = o['createdDate'] ?? o['createdAt'] ?? o['created'];
    return DateTime.tryParse(raw?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
  }

  Future<void> _tick() async {
    if (_isTickInFlight) return;
    _isTickInFlight = true;
    try {
      final storeId = _sessionStore.storeId;
      if (storeId.isEmpty) {
        _log('skip: storeId empty');
        return;
      }

      final page = await _repo.getOrdersByStore(
        storeId: storeId,
        page: 0,
        size: 50,
      );
      final items = page.items;

      final awaiting = items
          .where((o) => isAwaitingAcceptance(_statusOf(o)))
          .toList()
        ..sort((a, b) => _createdMillis(b).compareTo(_createdMillis(a)));

      _log(
        'store=$storeId fetched=${items.length} '
        'awaiting=${awaiting.length} showing=$_showingDialog '
        'handled=${_handledOrderIds.length} '
        'statuses=${items.take(8).map(_statusOf).toList()}',
      );

      final unhandled = awaiting
          .where((o) => !_handledOrderIds.contains(_orderId(o)))
          .toList();

      if (unhandled.isNotEmpty && !_showingDialog) {
        _presentAlert(unhandled.first);
      } else if (awaiting.isEmpty && !_showingDialog) {
        await _stopSound();
      }

      final currentIds = items.map(_orderId).toSet();
      _handledOrderIds.removeWhere((id) => !currentIds.contains(id));
    } catch (e, st) {
      _log('tick error: $e\n$st');
    } finally {
      _isTickInFlight = false;
    }
  }

  void _presentAlert(Map<String, dynamic> order, [BuildContext? context]) {
    final ctx = context ??
        navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (ctx == null) {
      _log('no context yet — will retry next tick');
      return;
    }

    final orderId = _orderId(order);
    _handledOrderIds.add(orderId);
    _showingDialog = true;
    _playLoop();

    final chain =
        nextOrderStatuses(_statusOf(order)) ?? const ['CONFIRMED', 'PREPARING'];

    Future<void> accept() async {
      await _stopSound();
      try {
        for (final s in chain) {
          await _repo.updateOrderStatus(orderId: orderId, status: s);
        }
        recordMerchantStatus(orderId, chain.last);
        _log('accepted $orderId -> ${chain.join(",")}');
      } catch (e) {
        _log('accept failed: $e');
        _handledOrderIds.remove(orderId); // let it re-alert
      } finally {
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
        _showingDialog = false;
      }
    }

    _log('showing popup for $orderId (${chain.join(",")})');
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: NewOrderAlertDialog(
          order: order,
          acceptLabel: 'Accept Order',
          onAccept: accept,
        ),
      ),
    ).whenComplete(() {
      _showingDialog = false;
      _stopSound();
    });
  }

  Future<void> _playLoop() async {
    if (_soundPlaying) return;
    if (!_audioContextSet) {
      _audioContextSet = true;
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(respectSilence: false).build(),
        );
      } catch (e) {
        _log('setAudioContext failed: $e');
      }
    }
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/manasantha.mp3'));
      _soundPlaying = true;
      _log('sound started');
    } catch (e) {
      _log('sound play failed: $e');
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _stopSound() async {
    if (!_soundPlaying) return;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _soundPlaying = false;
  }
}
