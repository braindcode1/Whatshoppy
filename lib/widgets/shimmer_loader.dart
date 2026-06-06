import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

/// A reusable shimmer placeholder widget for loading states.
class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final gradient = LinearGradient(
          begin: Alignment(-1.0 + 2.0 * value, 0),
          end: Alignment(1.0 + 2.0 * value, 0),
          colors: [
            AppTheme.borderGrey.withValues(alpha: 0.3),
            AppTheme.borderGrey.withValues(alpha: 0.6),
            AppTheme.borderGrey.withValues(alpha: 0.3),
          ],
        );
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer card for KPI placeholders
class ShimmerKPICard extends StatelessWidget {
  const ShimmerKPICard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerLoader(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(14))),
              const Spacer(),
              const ShimmerLoader(width: 32, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
            ],
          ),
          const SizedBox(height: 20),
          const ShimmerLoader(width: 80, height: 12),
          const SizedBox(height: 10),
          const ShimmerLoader(width: 60, height: 28),
        ],
      ),
    );
  }
}

/// Pre-built shimmer for the quick stat row
class ShimmerQuickStat extends StatelessWidget {
  const ShimmerQuickStat({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShimmerLoader(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoader(width: 100, height: 12),
                SizedBox(height: 8),
                ShimmerLoader(width: 60, height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
