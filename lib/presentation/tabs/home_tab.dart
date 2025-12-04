import 'package:flutter/material.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late ScrollController _scroll;
  late AnimationController _animController;
  late Animation<double> _anim;
  bool _enabled = true;
  int? _businessId;

  @override
  void initState() {
    super.initState();

    _scroll = ScrollController()
      ..addListener(() {
        double offset = _scroll.offset;
        double value = (offset / 160).clamp(0.0, 1.0);
        _animController.value = value;
      });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Initialize business status from session
    final sess = sl<SessionStore>().user;
    if (sess is Map<String, dynamic>) {
      final b2b = sess['b2bUnit'];
      if (b2b is Map<String, dynamic>) {
        _businessId = b2b['id'] as int?;
        final en = b2b['enabled'];
        if (en is bool) _enabled = en;
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [_bodyContent(), _animatedHeader()]),
    );
  }

  Widget _animatedHeader() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -160 * _anim.value),
          child: Opacity(
            opacity: 1 - _anim.value,
            child: Container(
              height: Responsive.isTablet(context) ? 280 : 250,
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 50,
                left: Responsive.horizontalPadding(context),
                right: Responsive.horizontalPadding(context),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: Responsive.headingFontSize(context),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  AnimatedBuilder(
                    animation: sl<SessionStore>(),
                    builder: (context, _) => Text(
                      sl<SessionStore>().businessName,
                      style: TextStyle(
                        fontSize: Responsive.titleFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    height: Responsive.isTablet(context) ? 90 : 80,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context),
                      vertical: Responsive.verticalPadding(context),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.power_settings_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Restaurant Status",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              _enabled ? "Currently Open" : "Currently Closed",
                              style: TextStyle(
                                fontSize: 15,
                                color: _enabled ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Switch(
                          value: _enabled,
                          onChanged: (value) async {
                            if (_businessId == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Business ID not found'),
                                ),
                              );
                              return;
                            }
                            final old = _enabled;
                            setState(() => _enabled = value);
                            try {
                              final repo = sl<BusinessRepository>();
                              await repo.setBusinessEnabled(
                                businessId: _businessId!,
                                enabled: value,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Restaurant enabled'
                                        : 'Restaurant disabled',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _enabled = old);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          },
                          activeTrackColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bodyContent() {
    return SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.only(
        top: Responsive.isTablet(context) ? 280 : 250,
        left: Responsive.horizontalPadding(context),
        right: Responsive.horizontalPadding(context),
      ),
      child: Column(
        children: [
          _statsSection(),
          SizedBox(height: Responsive.spacing(context)),

          _premiumSection(
            title: "Recent Orders",
            action: "View All",
            child: Column(
              children: const [
                _OrderItem(
                  orderId: '#1234',
                  customer: 'Rahul Sharma',
                  amount: '₹450',
                  status: 'preparing',
                  time: '2 min ago',
                ),
                SizedBox(height: 12),
                _OrderItem(
                  orderId: '#1233',
                  customer: 'Priya Singh',
                  amount: '₹230',
                  status: 'ready',
                  time: '5 min ago',
                ),
                SizedBox(height: 12),
                _OrderItem(
                  orderId: '#1232',
                  customer: 'Amit Kumar',
                  amount: '₹680',
                  status: 'preparing',
                  time: '8 min ago',
                ),
              ],
            ),
          ),

          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _statsSection() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: "Today's Revenue",
                value: '₹12,450',
                change: '+12%',
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Active Orders',
                value: '8',
                change: '+3',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: 'Avg. Prep Time',
                value: '18 min',
                change: '-2 min',
                icon: Icons.access_time,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Rating',
                value: '4.5',
                change: '+0.2',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _premiumSection({
    required String title,
    String? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    action,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String orderId;
  final String customer;
  final String amount;
  final String status;
  final String time;

  const _OrderItem({
    required this.orderId,
    required this.customer,
    required this.amount,
    required this.status,
    required this.time,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      customer,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
