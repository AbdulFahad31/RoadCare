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
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (report.userId == userId)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.severityHigh),
                  ),
                  tooltip: 'Delete Report',
                  onPressed: () => _confirmDelete(context, ref),
                ),
            ],
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

                  if (report.aiGenerated) ...[
                    const SizedBox(height: 16),
                    _InfoSection(
                      title: 'AI Inspection Summary',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: AppColors.primary, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI Generated',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (report.confidence != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${report.confidence}% Match',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAiTile(
                                    'Damage Type',
                                    report.damageType ?? 'Unknown',
                                    Icons.pest_control_rodent_outlined),
                              ),
                              Expanded(
                                child: _buildAiTile(
                                    'Priority',
                                    report.repairPriority ?? 'Medium',
                                    Icons.priority_high),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAiTile(
                                  'Est. Diameter',
                                  report.estimatedDiameterCm != null
                                      ? '${report.estimatedDiameterCm!.toStringAsFixed(1)} cm'
                                      : 'N/A',
                                  Icons.straighten,
                                ),
                              ),
                              Expanded(
                                child: _buildAiTile(
                                  'Est. Depth',
                                  report.estimatedDepthCm != null
                                      ? '${report.estimatedDepthCm!.toStringAsFixed(1)} cm'
                                      : 'N/A',
                                  Icons.vertical_align_bottom,
                                ),
                              ),
                            ],
                          ),
                          if (report.suggestedAction != null &&
                              report.suggestedAction!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildAiTile('Suggested Action',
                                report.suggestedAction!, Icons.build_outlined),
                          ],
                          if (report.safetyWarning != null &&
                              report.safetyWarning!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.severityHigh
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.severityHigh
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.severityHigh, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Safety Warning',
                                          style: TextStyle(
                                            color: AppColors.severityHigh,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          report.safetyWarning!,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (report.status == PotholeStatus.fixed) ...[
                    const SizedBox(height: 16),
                    _InfoSection(
                      title: 'Resolution Info',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.statusFixed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Marked as Fixed by ${report.fixedByName ?? "a user"}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (report.fixedMessage != null &&
                              report.fixedMessage!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '"${report.fixedMessage}"',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                            ? AppColors.primary.withValues(alpha: 0.2)
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

                  // Mark as Fixed Button (for other users or anyone when unfixed)
                  if (report.status != PotholeStatus.fixed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showMarkFixedDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusFixed,
                          side: const BorderSide(color: AppColors.statusFixed),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Mark as Fixed',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkFixedDialog(BuildContext context, WidgetRef ref) {
    final textController =
        TextEditingController(text: 'bro that issue is already fixed');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Mark Pothole as Fixed',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Help the community by explaining how or when it was resolved.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Enter details...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusFixed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final message = textController.text.trim();
                final userName = ref.read(authServiceProvider).displayName;

                try {
                  await ref.read(potholeServiceProvider).markAsFixed(
                        potholeId: report.id,
                        fixedMessage: message,
                        fixedByName: userName,
                      );
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pothole successfully marked as fixed!'),
                        backgroundColor: AppColors.statusFixed,
                      ),
                    );
                    Navigator.pop(context); // Return to Map/List
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
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

  Widget _buildAiTile(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete Report',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.severityHigh,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  Navigator.pop(context); // Close dialog

                  // Show loading spinner
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );

                  await ref
                      .read(potholeServiceProvider)
                      .deletePothole(report.id);

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report deleted successfully'),
                        backgroundColor: AppColors.severityHigh,
                      ),
                    );
                    Navigator.pop(context); // Return to list/map
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading spinner if open
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete report: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
              color: color.withValues(alpha: 0.1),
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
