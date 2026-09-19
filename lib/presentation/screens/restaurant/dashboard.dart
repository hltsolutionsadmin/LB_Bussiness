import 'package:flutter/material.dart';
import 'package:local_basket_business/core/services/orders_poller.dart';
import 'package:local_basket_business/core/services/tab_navigation_service.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/presentation/tabs/analytics_tab.dart';
import 'package:local_basket_business/presentation/tabs/home_tab.dart';
import 'package:local_basket_business/presentation/tabs/menu_tab.dart';
import 'package:local_basket_business/presentation/tabs/order_tab.dart';
import 'package:local_basket_business/presentation/tabs/profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final int _notificationCount = 3;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  final List<Widget> _tabs = const [
    HomeTab(),
    OrdersTab(),
    MenuTab(),
    AnalyticsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Lets services outside the widget tree (e.g. OrdersPoller, after the
    // merchant accepts/rejects a new order) switch the visible tab. A fresh
    // dashboard always starts on Home, so reset the shared index too —
    // otherwise a stale value from a previous session (e.g. left on Orders)
    // would silently desync it from this screen's own starting tab.
    sl<TabNavigationService>().setIndex(0);
    sl<TabNavigationService>().addListener(_onExternalTabChange);

    // The dashboard is mounted under every tab, so its context is always a
    // valid place to show the new-order alert. The background poll just
    // queues the order; this is what actually pops the dialog + sound on
    // Home / Menu / Analytics / Profile, not only the Orders tab.
    sl<OrdersPoller>().addListener(_onPollerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPollerChanged());
  }

  @override
  void dispose() {
    sl<TabNavigationService>().removeListener(_onExternalTabChange);
    sl<OrdersPoller>().removeListener(_onPollerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPollerChanged() {
    if (!mounted) return;
    if (sl<OrdersPoller>().pendingAlert == null) return;
    sl<OrdersPoller>().presentPendingAlert(context);
  }

  void _onExternalTabChange() {
    final index = sl<TabNavigationService>().currentIndex;
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _controller.reset();
      _controller.forward();
    });
  }

  void animateTabChange(int index) {
    sl<TabNavigationService>().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // -------------------- HEADER --------------------
          if (_currentIndex != 0)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPadding(context),
                    Responsive.verticalPadding(context),
                    Responsive.horizontalPadding(context),
                    Responsive.isTablet(context) ? 50 : 40,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: sl<SessionStore>(),
                        builder: (context, _) {
                          final name = sl<SessionStore>().businessName;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: Responsive.titleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Restaurant Partner',
                                style: TextStyle(
                                  fontSize: Responsive.bodyFontSize(context),
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$_notificationCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // -------------------- CONTENT WITH ANIMATION --------------------
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: _tabs[_currentIndex],
            ),
          ),
        ],
      ),

      // -------------------- BOTTOM NAV --------------------
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: animateTabChange,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF97316),
          unselectedItemColor: const Color(0xFF6B7280),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
