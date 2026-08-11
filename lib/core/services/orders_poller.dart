import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/presentation/tabs/widgets/orders_tab_widgets/order_details_dialog.dart';
import 'package:local_basket_business/routes/app_router.dart';

class OrdersPoller {
  OrdersPoller(this._repo, this._sessionStore);

  final OrdersRepository _repo;
  final SessionStore _sessionStore;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<String> _previousOrderIds = <String>{};
  bool _isInitial = true;
  bool _showingDialog = false;
  bool _soundPlaying = false;
  bool _isTickInFlight = false;

  static const Duration defaultInterval = Duration(seconds: 15);

  void start({Duration interval = defaultInterval}) {
    _timer ??= Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_isTickInFlight) return;
    _isTickInFlight = true;
    final storeId = _sessionStore.storeId;
    if (storeId.isEmpty || !_sessionStore.isStoreVendor) {
      _isTickInFlight = false;
      return;
    }

    try {
      final page = await _repo.getOrdersByStore(
        storeId: storeId,
        page: 0,
        size: 50,
      );

      final currentIds = page.items.map((e) => e['id'].toString()).toSet();
      bool isNewStage(Map<String, dynamic> o) {
        final s = (o['orderStatus']?.toString() ?? '').toLowerCase();
        return s.contains('created') || s.contains('new') || s.contains('place') || s.contains('pending');
      }

      if (!_isInitial) {
        final newOrders = page.items
            .where((o) => !_previousOrderIds.contains(o['id'].toString()))
            .toList();
        final hasAnyNewStage = page.items.any(isNewStage);
        if (newOrders.isNotEmpty) {
          await _playLoop();
          if (!_showingDialog) {
            _showingDialog = true;
            final order = newOrders.first;
            final ctx = navigatorKey.currentState?.overlay?.context;
            if (ctx != null) {
              // ignore: use_build_context_synchronously
              showDialog(
                context: ctx,
                barrierDismissible: false,
                builder: (_) => OrderDetailsDialog(
                  order: order,
                  isNewOrder: true,
                  onAccept: () async {
                    await _stopSound();
                    await _repo.updateOrderStatus(
                      orderId: order['id']?.toString() ?? '',
                      status: 'CONFIRMED',
                    );
                    navigatorKey.currentState?.pop();
                    _showingDialog = false;
                  },
                  onReject: () async {
                    await _stopSound();
                    await _repo.updateOrderStatus(
                      orderId: order['id']?.toString() ?? '',
                      status: 'REJECTED',
                    );
                    navigatorKey.currentState?.pop();
                    _showingDialog = false;
                  },
                ),
              ).then((_) async {
                _showingDialog = false;
                await _stopSound();
              });
            } else {
              // If no context yet, stop the sound to avoid looping indefinitely
              await _stopSound();
              _showingDialog = false;
            }
          }
        }
        // If there are no orders in a 'new' stage anymore, stop any playing sound
        if (!hasAnyNewStage) {
          await _stopSound();
        }
      }

      _previousOrderIds = currentIds;
      _isInitial = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OrdersPoller] tick error: $e');
      }
    } finally {
      _isTickInFlight = false;
    }
  }

  Future<void> _playLoop() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/hen.mp3'));
      _soundPlaying = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OrdersPoller] sound play failed: $e');
      }
    }
  }

  Future<void> _stopSound() async {
    try {
      if (_soundPlaying) {
        await _audioPlayer.stop();
        _soundPlaying = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OrdersPoller] sound stop failed: $e');
      }
    }
  }
}
