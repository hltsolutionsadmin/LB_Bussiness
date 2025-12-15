import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
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

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    final user = _sessionStore.user;
    final businessId = (user != null && user['b2bUnit'] is Map<String, dynamic>)
        ? (user['b2bUnit']['id'] as int?)
        : null;
    if (businessId == null) return;

    try {
      final page = await _repo.getOrdersByBusiness(
        businessId: businessId,
        page: 0,
        size: 10,
      );

      final currentIds = page.items.map((e) => e['id'].toString()).toSet();
      bool _isNewStage(Map<String, dynamic> o) {
        final s = (o['orderStatus']?.toString() ?? '').toLowerCase();
        return s.contains('new') || s.contains('place') || s.contains('accept');
      }

      if (!_isInitial) {
        final newOrders = page.items
            .where((o) => !_previousOrderIds.contains(o['id'].toString()))
            .toList();
        final hasAnyNewStage = page.items.any(_isNewStage);
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
                      orderNumber: order['orderNumber']?.toString() ?? '',
                      status: 'ACCEPTED',
                      notes: '0',
                    );
                    navigatorKey.currentState?.pop();
                    _showingDialog = false;
                  },
                  onReject: () async {
                    await _stopSound();
                    await _repo.updateOrderStatus(
                      orderNumber: order['orderNumber']?.toString() ?? '',
                      status: 'REJECTED',
                      notes: '0',
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
    } catch (_) {
      // ignore errors in background
    }
  }

  Future<void> _playLoop() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/hen.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _soundPlaying = true;
    } catch (_) {}
  }

  Future<void> _stopSound() async {
    try {
      if (_soundPlaying) {
        await _audioPlayer.stop();
        _soundPlaying = false;
      }
    } catch (_) {}
  }
}
