import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../report/models/pothole_report.dart';
import '../../report/providers/report_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../report/screens/pothole_detail_screen.dart';

enum AdminSortOrder { byDate, byUpvotes, bySeverity }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allPotholesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Reports'),
            Tab(text: 'Reported'),
            Tab(text: 'In Progress'),
            Tab(text: 'Fixed'),
          ],
        ),
      ),
      body: Column(
        children: [
          reportsAsync.when(
            data: (reports) => _buildStatsRow(reports),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          _buildSortBar(),
          Expanded(
            child: reportsAsync.when(
              data: (reports) => TabBarView(
                controller: _tabController,
                children: [
                  _AdminReportsList(reports: _sortReports(reports)),
                  _AdminReportsList(
                    reports: _sortReports(
                      reports
                          .where((r) => r.status == PotholeStatus.reported)
                          .toList(),
                    ),
                  ),
                  _AdminReportsList(
                    reports: _sortReports(
                      reports
                          .where((r) => r.status == PotholeStatus.inProgress)
                          .toList(),
                    ),
                  ),
                  _AdminReportsList(
                    reports: _sortReports(
                      reports
                          .where((r) => r.status == PotholeStatus.fixed)
                          .toList(),
                    ),
                  ),
                ],
              ),
              loading: () => _buildLoadingState(),
              error: (e, __) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<PotholeReport> reports) {
    final reported =
        reports.where((r) => r.status == PotholeStatus.reported).length;
    final inProgress =
        reports.where((r) => r.status == PotholeStatus.inProgress).length;
    final fixed = reports.where((r) => r.status == PotholeStatus.fixed).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(
              label: 'Total', value: reports.length, color: AppColors.primary),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Reported',
              value: reported,
              color: AppColors.statusReported),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Active',
              value: inProgress,
              color: AppColors.statusInProgress),
          const SizedBox(width: 8),
          _StatChip(label: 'Fixed', value: fixed, color: AppColors.statusFixed),
        ],
      ),
    );
  }

  AdminSortOrder _sortOrder = AdminSortOrder.byDate;

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          _SortButton(
            label: 'Date',
            isSelected: _sortOrder == AdminSortOrder.byDate,
            onTap: () => setState(() => _sortOrder = AdminSortOrder.byDate),
          ),
          const SizedBox(width: 6),
          _SortButton(
            label: 'Upvotes',
            isSelected: _sortOrder == AdminSortOrder.byUpvotes,
            onTap: () => setState(() => _sortOrder = AdminSortOrder.byUpvotes),
          ),
          const SizedBox(width: 6),
          _SortButton(
            label: 'Severity',
            isSelected: _sortOrder == AdminSortOrder.bySeverity,
            onTap: () => setState(() => _sortOrder = AdminSortOrder.bySeverity),
          ),
        ],
      ),
    );
  }

  List<PotholeReport> _sortReports(List<PotholeReport> reports) {
    final sorted = List<PotholeReport>.from(reports);
    switch (_sortOrder) {
      case AdminSortOrder.byUpvotes:
        sorted.sort((a, b) => b.upvotes.compareTo(a.upvotes));
      case AdminSortOrder.bySeverity:
        sorted.sort((a, b) => b.severity.index.compareTo(a.severity.index));
      default:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return sorted;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ─── Admin Reports List ───────────────────────────────────────────────────────

class _AdminReportsList extends ConsumerWidget {
  final List<PotholeReport> reports;
  const _AdminReportsList({required this.reports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('No reports in this category',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (ctx, i) => _AdminReportCard(
        report: reports[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PotholeDetailScreen(report: reports[i]),
          ),
        ),
        onStatusUpdate: (status) async {
          try {
            await ref
                .read(potholeServiceProvider)
                .updateStatus(reports[i].id, status);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Status updated to ${status.label}'),
                ),
              );
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
      ),
    );
  }
}

// ─── Admin Report Card ────────────────────────────────────────────────────────

class _AdminReportCard extends StatelessWidget {
  final PotholeReport report;
  final VoidCallback onTap;
  final void Function(PotholeStatus) onStatusUpdate;

  const _AdminReportCard({
    required this.report,
    required this.onTap,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: report.imageUrl.isNotEmpty
                  ? Image.network(
                      report.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary),
                    ),
            ),
            title: Row(
              children: [
                _StatusDot(status: report.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.description.isNotEmpty
                        ? report.description
                        : 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${report.timestamp.timeAgo}  •  ↑ ${report.upvotes}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ),
          // Admin actions bar
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: PotholeStatus.values.map((s) {
                final isActive = report.status == s;
                final color = _statusColor(s);
                return Expanded(
                  child: TextButton(
                    onPressed: isActive ? null : () => onStatusUpdate(s),
                    child: Text(
                      s.label,
                      style: TextStyle(
                        color: isActive ? color : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PotholeStatus s) {
    switch (s) {
      case PotholeStatus.fixed:
        return AppColors.statusFixed;
      case PotholeStatus.inProgress:
        return AppColors.statusInProgress;
      default:
        return AppColors.statusReported;
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
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
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortButton(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final PotholeStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PotholeStatus.fixed => AppColors.statusFixed,
      PotholeStatus.inProgress => AppColors.statusInProgress,
      _ => AppColors.statusReported,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
