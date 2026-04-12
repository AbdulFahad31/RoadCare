import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../report/models/pothole_report.dart';
import '../../report/providers/report_providers.dart';
import '../../report/screens/pothole_detail_screen.dart';
import '../../auth/providers/auth_providers.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  PotholeStatus? _statusFilter;
  PotholeSeverity? _severityFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allPotholesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                final filtered = _applyFilters(reports);
                if (filtered.isEmpty) return _buildEmptyState();
                return _buildReportsList(filtered);
              },
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search reports...',
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _statusFilter == null && _severityFilter == null,
            onTap: () => setState(() {
              _statusFilter = null;
              _severityFilter = null;
            }),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          ...PotholeStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: s.label,
                isSelected: _statusFilter == s,
                onTap: () => setState(
                    () => _statusFilter = _statusFilter == s ? null : s),
                color: _statusColor(s),
              ),
            ),
          ),
          ...PotholeSeverity.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: '${s.label} Risk',
                isSelected: _severityFilter == s,
                onTap: () => setState(
                    () => _severityFilter = _severityFilter == s ? null : s),
                color: _severityColor(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PotholeReport> _applyFilters(List<PotholeReport> reports) {
    return reports.where((r) {
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      final matchesSeverity =
          _severityFilter == null || r.severity == _severityFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return matchesStatus && matchesSeverity && matchesSearch;
    }).toList();
  }

  Widget _buildReportsList(List<PotholeReport> reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (ctx, i) => _ReportCard(
        report: reports[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PotholeDetailScreen(report: reports[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.search_off,
                color: AppColors.textTertiary, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reports found',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surfaceElevated,
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(error,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Filter options',
            style: TextStyle(color: AppColors.textPrimary)),
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

  Color _severityColor(PotholeSeverity s) {
    switch (s) {
      case PotholeSeverity.high:
        return AppColors.severityHigh;
      case PotholeSeverity.medium:
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}

// ─── Report Card ─────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final PotholeReport report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (report.status) {
      PotholeStatus.fixed => AppColors.statusFixed,
      PotholeStatus.inProgress => AppColors.statusInProgress,
      _ => AppColors.statusReported,
    };

    return Consumer(
      builder: (context, ref, child) {
        final currentUserId = ref.watch(authServiceProvider).userId;
        final isMe = report.userId == currentUserId;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMe ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                width: isMe ? 1.5 : 1,
              ),
              boxShadow: isMe
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Hero(
                    tag: 'pothole_${report.id}',
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: report.imageUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.surfaceVariant,
                            highlightColor: AppColors.surfaceElevated,
                            child: Container(color: AppColors.surfaceVariant),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: AppColors.textTertiary),
                          ),
                        ),
                        if (isMe)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                report.status.label,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              report.timestamp.timeAgo,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: AppColors.textTertiary, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              isMe ? 'You' : (report.userName?.isNotEmpty ?? false ? report.userName! : 'Anonymous'),
                              style: TextStyle(
                                color: isMe ? AppColors.primary : AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description.isNotEmpty
                              ? report.description
                              : 'No description provided',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: report.description.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontSize: 13,
                            fontStyle: report.description.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_outlined,
                                color: AppColors.textSecondary, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${report.upvotes}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _severityColor(report.severity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${report.severity.label} Risk',
                              style: TextStyle(
                                color: _severityColor(report.severity),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _severityColor(PotholeSeverity s) {
    switch (s) {
      case PotholeSeverity.high:
        return AppColors.severityHigh;
      case PotholeSeverity.medium:
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
