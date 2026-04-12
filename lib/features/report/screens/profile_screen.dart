import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/report_providers.dart';
import '../models/pothole_report.dart';
import '../../auth/providers/auth_providers.dart';
import 'pothole_detail_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'about_roadcare_screen.dart';
import 'reports_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final reportsAsync = ref.watch(allPotholesProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(authService, isAdmin),
            const SizedBox(height: 24),
            reportsAsync.when(
              data: (reports) => _buildStats(reports, authService.userId),
              loading: () => const CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildMyReports(context, ref, reportsAsync, authService.userId),
            const SizedBox(height: 24),
            _buildSettings(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      dynamic authService, AsyncValue<bool> isAdminAsync) {
    final isAnon = authService.isAnonymous;
    final name = authService.displayName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                isAnon || name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                    Text(
                      isAnon ? 'Guest User' : name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    isAdminAsync.when(
                      data: (isAdmin) => isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAnon
                      ? 'Sign in to track your reports'
                      : authService.currentUser?.phoneNumber ?? 'No phone number',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<PotholeReport> reports, String userId) {
    final myReports = reports.where((r) => r.userId == userId).toList();
    final myFixed =
        myReports.where((r) => r.status == PotholeStatus.fixed).length;
    final totalUpvotes = myReports.fold<int>(0, (sum, r) => sum + r.upvotes);

    return Row(
      children: [
        _QuickStat(
          label: 'Reported',
          value: myReports.length.toString(),
          icon: Icons.report_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _QuickStat(
          label: 'Fixed',
          value: myFixed.toString(),
          icon: Icons.check_circle_outline,
          color: AppColors.statusFixed,
        ),
        const SizedBox(width: 12),
        _QuickStat(
          label: 'Upvotes',
          value: totalUpvotes.toString(),
          icon: Icons.thumb_up_outlined,
          color: AppColors.statusInProgress,
        ),
      ],
    );
  }

  Widget _buildMyReports(BuildContext context, WidgetRef ref,
      AsyncValue<List<PotholeReport>> reportsAsync, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Reports',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportsListScreen(),
                ),
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        reportsAsync.when(
          data: (reports) {
            final myReports =
                reports.where((r) => r.userId == userId).take(3).toList();
            if (myReports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.report_off_outlined,
                          color: AppColors.textTertiary, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No reports yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: myReports.map((r) {
                final statusColor = switch (r.status) {
                  PotholeStatus.fixed => AppColors.statusFixed,
                  PotholeStatus.inProgress => AppColors.statusInProgress,
                  _ => AppColors.statusReported,
                };
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PotholeDetailScreen(report: r),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.description.isNotEmpty
                                ? r.description
                                : 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.status.label,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 58),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 58),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'About RoadCare',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutRoadCareScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 58),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Sign Out',
            color: AppColors.error,
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      trailing: color == AppColors.error
          ? null
          : const Icon(Icons.chevron_right,
              color: AppColors.textTertiary, size: 20),
      onTap: onTap,
    );
  }
}
