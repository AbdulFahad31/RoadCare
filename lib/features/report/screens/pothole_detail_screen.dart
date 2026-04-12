import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../models/pothole_report.dart';
import '../providers/report_providers.dart';
import '../../auth/providers/auth_providers.dart';

class PotholeDetailScreen extends ConsumerWidget {
  final PotholeReport report;

  const PotholeDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).userId;
    final hasUpvoted = report.upvotedBy.contains(userId);
    final upvoteState = ref.watch(upvoteProvider(report.id));
    final color = _statusColor(report.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'pothole_${report.id}',
                child: CachedNetworkImage(
                  imageUrl: report.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.surfaceVariant,
                    highlightColor: AppColors.surfaceElevated,
                    child: Container(color: AppColors.surfaceVariant),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textTertiary, size: 48),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Severity row
                  Row(
                    children: [
                      _StatusBadge(status: report.status),
                      const SizedBox(width: 8),
                      _SeverityBadge(severity: report.severity),
                      const Spacer(),
                      Text(
                        report.timestamp.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Upvotes
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.thumb_up_outlined,
                          label: 'Upvotes',
                          value: report.upvotes.toString(),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_outline,
                          label: 'Confirmed by',
                          value: '${report.upvotedBy.length} users',
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location
                  _InfoSection(
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report.address != null)
                          Text(
                            report.address!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop,
                                color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoSection(
                      title: 'Description',
                      child: Text(
                        report.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _InfoSection(
                    title: 'Report Info',
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Reported',
                          value: report.timestamp.formatted,
                        ),
                        _InfoRow(
                          label: 'Report ID',
                          value: report.id.substring(0, 8).toUpperCase(),
                        ),
                        _InfoRow(
                          label: 'Current Status',
                          value: report.status.label,
                          valueColor: color,
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _InfoRow(
                          label: 'Reported By',
                          value: report.userName?.isNotEmpty == true
                              ? report.userName!
                              : 'Anonymous',
                        ),
                        if (report.userPhone?.isNotEmpty == true)
                          _InfoRow(
                            label: 'Contact',
                            value: report.userPhone!,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Upvote button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: upvoteState is AsyncLoading
                          ? null
                          : () => ref
                              .read(upvoteProvider(report.id).notifier)
                              .toggle(report.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUpvoted
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.primary,
                        foregroundColor:
                            hasUpvoted ? AppColors.primary : Colors.white,
                        side: hasUpvoted
                            ? const BorderSide(color: AppColors.primary)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: upvoteState is AsyncLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          : Icon(hasUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined),
                      label: Text(
                        hasUpvoted ? 'Upvoted ✓' : 'Confirm This Issue',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PotholeStatus status) {
    switch (status) {
      case PotholeStatus.fixed:
        return AppColors.statusFixed;
      case PotholeStatus.inProgress:
        return AppColors.statusInProgress;
      default:
        return AppColors.statusReported;
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final PotholeStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PotholeStatus.fixed => AppColors.statusFixed,
      PotholeStatus.inProgress => AppColors.statusInProgress,
      _ => AppColors.statusReported,
    };
    final label = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final PotholeSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      PotholeSeverity.high => AppColors.severityHigh,
      PotholeSeverity.medium => AppColors.severityMedium,
      _ => AppColors.severityLow,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${severity.label} Risk',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
