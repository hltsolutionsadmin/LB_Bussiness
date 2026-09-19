import 'dart:async';
import 'dart:developer' as dev;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_basket_business/core/services/tab_navigation_service.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/utils/order_status.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/presentation/widgets/new_order_alert_dialog.dart';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';

/// Polls the store's orders and, whenever a fresh order is waiting for the
/// merchant, plays a looping alert sound and shows a blocking popup — from
/// anywhere in the app.
void _log(String m) {
  // Not throttled like debugPrint, and visible in `flutter run` / logcat.
  dev.log(m, name: 'OrdersPoller');
  // ignore: avoid_print
  print('>>> ORDERS_POLLER: $m');
}

class OrdersPoller extends ChangeNotifier {
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
    if (orderId.isEmpty) return;
    if (merchantStatus[orderId] == status) return;
    merchantStatus[orderId] = status;
    // Let the Orders tab re-apply this onto whatever it's currently showing.
    notifyListeners();
  }

  /// A new order waiting for the merchant, detected by the background poll but
  /// not yet shown. A permanently-mounted widget (the dashboard) listens for
  /// this and presents the dialog with its own valid context — that's what
  /// makes the alert appear on *any* tab, not just the Orders tab.
  Map<String, dynamic>? _pendingAlert;
  Map<String, dynamic>? get pendingAlert => _pendingAlert;

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

  /// Queue a new-order alert. Starts the sound straight away (so it rings on
  /// whatever screen the merchant is on) and notifies listeners so the
  /// dashboard host can show the dialog.
  void _queueAlert(Map<String, dynamic> order) {
    if (_showingDialog) return;
    final id = _orderId(order);
    final alreadyQueued =
        _pendingAlert != null && _orderId(_pendingAlert!) == id;
    _pendingAlert = order;
    if (!alreadyQueued) _log('queued alert for $id');
    _playLoop(); // idempotent
    // Notify every poll while unshown — this is also the retry path if a
    // previous show attempt failed (e.g. dashboard wasn't mounted yet).
    notifyListeners();
  }

  /// Called by the always-mounted dashboard, which owns a context that is
  /// reliably inside the navigator — shows the queued new-order dialog.
  void presentPendingAlert(BuildContext context) {
    final order = _pendingAlert;
    if (order == null || _showingDialog) return;
    _pendingAlert = null;
    _presentAlert(order, context);
  }

  /// Clears per-session state — call on logout.
  void reset() {
    _handledOrderIds.clear();
    merchantStatus.clear();
    _pendingAlert = null;
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
        size: 20,
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
        _queueAlert(unhandled.first);
      } else if (awaiting.isEmpty && !_showingDialog) {
        _pendingAlert = null;
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
    // [context] comes from an always-mounted widget (the dashboard) or the
    // Orders screen — a context reliably inside the navigator. Falling back to
    // the root overlay only covers the rare "dashboard not mounted yet" gap.
    final ctx = context ?? navigatorKey.currentState?.overlay?.context;
    if (ctx == null) {
      _log('no context yet — will retry next tick');
      return;
    }

    final orderId = _orderId(order);
    _handledOrderIds.add(orderId);
    _pendingAlert = null; // consumed — don't let the host re-show it
    _showingDialog = true;
    _playLoop();

    final chain = nextOrderStatuses(_statusOf(order)) ?? const ['CONFIRMED'];

    /// Pops the dialog (and any screen the merchant had navigated into) and
    /// lands them on the Orders tab, so they see the result of their action.
    void goToOrdersTab() {
      sl<TabNavigationService>().goToOrders();
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    void closeDialogOnly() {
      if (navigatorKey.currentState?.canPop() ?? false) {
        navigatorKey.currentState?.pop();
      }
    }

    Future<void> accept() async {
      await _stopSound();
      var success = false;
      try {
        for (final s in chain) {
          await _repo.updateOrderStatus(orderId: orderId, status: s);
          recordMerchantStatus(orderId, s);
        }
        _log('accepted $orderId -> ${chain.join(",")}');
        success = true;
      } catch (e) {
        _log('accept failed: $e');
        _handledOrderIds.remove(orderId); // let it re-alert
      } finally {
        _showingDialog = false;
        success ? goToOrdersTab() : closeDialogOnly();
      }
    }

    Future<void> reject() async {
      await _stopSound();
      var success = false;
      try {
        await _repo.updateOrderStatus(orderId: orderId, status: 'CANCELLED');
        recordMerchantStatus(orderId, 'CANCELLED');
        _log('rejected $orderId -> CANCELLED');
        success = true;
      } catch (e) {
        _log('reject failed: $e');
        _handledOrderIds.remove(orderId); // let it re-alert
      } finally {
        _showingDialog = false;
        success ? goToOrdersTab() : closeDialogOnly();
      }
    }

    _log('showing popup for $orderId (${chain.join(",")})');
    try {
      showDialog<void>(
        context: ctx,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: NewOrderAlertDialog(
            order: order,
            acceptLabel: 'Accept Order',
            onAccept: accept,
            rejectLabel: 'Reject Order',
            onReject: reject,
          ),
        ),
      ).whenComplete(() {
        _showingDialog = false;
        _stopSound();
      });
    } catch (e) {
      _log('failed to show popup for $orderId: $e — will retry next tick');
      _handledOrderIds.remove(orderId);
      _showingDialog = false;
      // Re-queue without notifying (notifying here could recurse straight back
      // into this failing path) — the next 15s poll picks it up again.
      _pendingAlert = order;
    }
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
