import 'package:flutter/material.dart';

/// Skeleton placeholder rendered in place of an [OrderCard] while that
/// order's status change is in flight — so the card is never shown with a
/// stale / half-updated status while the API call is running.
class OrderCardShimmer extends StatefulWidget {
  const OrderCardShimmer({super.key});

  @override
  State<OrderCardShimmer> createState() => _OrderCardShimmerState();
}

class _OrderCardShimmerState extends State<OrderCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final v = _controller.value;
              return LinearGradient(
                begin: Alignment(v * 3 - 2, 0),
                end: Alignment(v * 3, 0),
                colors: const [
                  Color(0xFFE7EAEE),
                  Color(0xFFF4F6F8),
                  Color(0xFFE7EAEE),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: const _SkeletonBody(),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bar(width: 90, height: 18),
              SizedBox(height: 8),
              _Bar(width: 150, height: 12),
              SizedBox(height: 8),
              _Bar(width: 120, height: 10),
            ],
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(width: 64, height: 18),
            SizedBox(height: 10),
            _Bar(width: 88, height: 26, radius: 20),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, this.radius = 6});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EAEE),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
