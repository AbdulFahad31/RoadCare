import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/pothole_report.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/extensions.dart';

class PotholeBottomSheet extends ConsumerWidget {
  final PotholeReport report;
  final VoidCallback onViewDetails;

  const PotholeBottomSheet({
    super.key,
    required this.report,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (report.status) {
      PotholeStatus.fixed => AppColors.statusFixed,
      PotholeStatus.inProgress => AppColors.statusInProgress,
      _ => AppColors.statusReported,
    };
    final severityColor = switch (report.severity) {
      PotholeSeverity.high => AppColors.severityHigh,
      PotholeSeverity.medium => AppColors.severityMedium,
      _ => AppColors.severityLow,
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: report.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(
                                  label: report.status.label,
                                  color: statusColor),
                              const SizedBox(width: 6),
                              _Badge(
                                  label: report.severity.label,
                                  color: severityColor),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.description.isNotEmpty
                                ? report.description
                                : 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: report.description.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 14,
                              fontStyle: report.description.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.thumb_up_outlined,
                                  color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${report.upvotes} upvotes',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time,
                                  color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                report.timestamp.timeAgo,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
