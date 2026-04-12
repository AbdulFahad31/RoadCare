import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NearbyStatsWidget extends StatelessWidget {
  final int total;
  final int fixed;
  final int inProgress;

  const NearbyStatsWidget({
    super.key,
    required this.total,
    required this.fixed,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final active = total - fixed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            value: total.toString(),
            label: 'Total',
            color: AppColors.primary,
          ),
          _Divider(),
          _StatItem(
            value: active.toString(),
            label: 'Active',
            color: AppColors.statusReported,
          ),
          _Divider(),
          _StatItem(
            value: inProgress.toString(),
            label: 'In Progress',
            color: AppColors.statusInProgress,
          ),
          _Divider(),
          _StatItem(
            value: fixed.toString(),
            label: 'Fixed',
            color: AppColors.statusFixed,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border,
    );
  }
}
