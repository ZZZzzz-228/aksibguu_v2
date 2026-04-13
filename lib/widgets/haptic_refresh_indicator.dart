import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pull-to-refresh с тактильным откликом (как в нативных приложениях).
class HapticRefreshIndicator extends StatelessWidget {
  const HapticRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;

  Future<void> _wrappedRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await onRefresh();
    } finally {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: color ?? theme.colorScheme.primary,
      backgroundColor: backgroundColor,
      displacement: displacement,
      onRefresh: _wrappedRefresh,
      child: child,
    );
  }
}
