import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/report_providers.dart';
import '../models/pothole_report.dart';
import '../../auth/providers/auth_providers.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportSubmissionProvider.notifier).fetchLocation();
      final auth = ref.read(authServiceProvider);
      _nameController.text = auth.displayName;
      _phoneController.text = auth.currentUser?.phone ?? '';
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimized from 80 (reduces file size by ~40%)
        maxWidth: 1024, // Optimized from 1200
        maxHeight: 1024, // Optimized from 1200
      );
      if (picked != null) {
        ref.read(reportSubmissionProvider.notifier).setImage(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Use camera to capture pothole',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(color: AppColors.border, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Select existing photo',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    ref
        .read(reportSubmissionProvider.notifier)
        .setDescription(_descriptionController.text);
    ref
        .read(reportSubmissionProvider.notifier)
        .setUserInfo(_nameController.text, _phoneController.text);
    await ref.read(reportSubmissionProvider.notifier).submitReport();
    final state = ref.read(reportSubmissionProvider);
    if (state.isSuccess && mounted) {
      Navigator.pop(context);

      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      final isOffline =
          results.isEmpty || results.contains(ConnectivityResult.none);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.check_circle,
                color: isOffline
                    ? AppColors.severityMedium
                    : AppColors.statusFixed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOffline
                      ? 'No internet connection. Pothole report saved offline! It will sync automatically once online.'
                      : 'Pothole reported successfully!',
                ),
              ),
            ],
          ),
          duration: Duration(seconds: isOffline ? 5 : 3),
        ),
      );
      ref.read(reportSubmissionProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportSubmissionProvider);

    ref.listen(reportSubmissionProvider, (previous, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }

      // Auto-populate the description controller if the AI produces a summary
      if (next.aiAnalysis != null &&
          next.aiAnalysis?.description != previous?.aiAnalysis?.description) {
        _descriptionController.text = next.aiAnalysis!.description;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Pothole'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(state),
              _buildAiAnalysisButton(state),
              _buildAiSummaryCard(state),
              const SizedBox(height: 20),
              _buildLocationSection(state),
              const SizedBox(height: 20),
              _buildSeveritySection(state),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildUserDetailsSection(),
              const SizedBox(height: 28),
              _buildSubmitButton(state),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ReportSubmissionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Pothole Photo', isRequired: true),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.selectedImage != null
                    ? AppColors.primary
                    : AppColors.border,
                width: state.selectedImage != null ? 2 : 1,
              ),
            ),
            child: state.selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          state.selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Change',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Camera or gallery',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAnalysisButton(ReportSubmissionState state) {
    if (state.selectedImage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: state.isAnalyzing
              ? null
              : () => ref
                  .read(reportSubmissionProvider.notifier)
                  .analyzeImageWithAi(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: state.isAnalyzing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            state.isAnalyzing ? 'Analyzing Road with AI...' : 'Analyze with AI',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAiSummaryCard(ReportSubmissionState state) {
    final ai = state.aiAnalysis;
    if (ai == null) {
      if (state.aiError != null) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.aiError!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Inspection Summary',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${ai.confidence}% match',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            // Grid of parameters
            Row(
              children: [
                Expanded(
                  child: _buildAiParamTile('Damage Type', ai.damageType,
                      Icons.pest_control_rodent_outlined),
                ),
                Expanded(
                  child: _buildAiParamTile(
                      'Severity', ai.severity, Icons.warning_amber_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAiParamTile(
                      'Priority', ai.repairPriority, Icons.priority_high),
                ),
                Expanded(
                  child: _buildAiParamTile('Suggested Action',
                      ai.suggestedAction, Icons.build_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAiParamTile(
                    'Est. Diameter',
                    '${ai.estimatedDiameterCm.toStringAsFixed(1)} cm',
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildAiParamTile(
                    'Est. Depth',
                    ai.estimatedDepthCm != null
                        ? '${ai.estimatedDepthCm!.toStringAsFixed(1)} cm'
                        : 'N/A',
                    Icons.vertical_align_bottom,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            // Description
            const Text(
              'Professional Analysis',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              ai.description,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.5),
            ),

            // Safety Warning Callout
            if (ai.safetyWarning.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.severityHigh.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.severityHigh.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.severityHigh, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            ai.safetyWarning,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12),
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
    );
  }

  Widget _buildAiParamTile(String label, String value, IconData icon) {
    return Row(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ReportSubmissionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Location', isRequired: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  state.location != null ? AppColors.primary : AppColors.border,
            ),
          ),
          child: state.isLoading && state.location == null
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Getting location...',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                )
              : state.location != null
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location captured',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.location!.latitude.toStringAsFixed(6)}, ${state.location!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primary, size: 20),
                          onPressed: () => ref
                              .read(reportSubmissionProvider.notifier)
                              .fetchLocation(),
                          tooltip: 'Refresh location',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.location_off,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.error?.contains('location') == true
                                ? state.error!
                                : 'Location not detected',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(reportSubmissionProvider.notifier)
                              .fetchLocation(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSeveritySection(ReportSubmissionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Severity Level', isRequired: true),
        const SizedBox(height: 12),
        Row(
          children: PotholeSeverity.values.map((severity) {
            final isSelected = state.severity == severity;
            final color = _severityColor(severity);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: severity != PotholeSeverity.high ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => ref
                      .read(reportSubmissionProvider.notifier)
                      .setSeverity(severity),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _severityIcon(severity),
                          color: isSelected ? color : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          severity.label,
                          style: TextStyle(
                            color: isSelected ? color : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _severityColor(PotholeSeverity severity) {
    switch (severity) {
      case PotholeSeverity.high:
        return AppColors.severityHigh;
      case PotholeSeverity.medium:
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }

  IconData _severityIcon(PotholeSeverity severity) {
    switch (severity) {
      case PotholeSeverity.high:
        return Icons.warning_rounded;
      case PotholeSeverity.medium:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildUserDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Your Details', isRequired: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Description', isRequired: false),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 300,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText:
                'Describe the pothole (size, road conditions, hazards...)',
            alignLabelWithHint: true,
            counterStyle: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ReportSubmissionState state) {
    final canSubmit = state.selectedImage != null && state.location != null;
    return ElevatedButton.icon(
      onPressed: state.isLoading ? null : (canSubmit ? _submit : null),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            canSubmit ? AppColors.primary : AppColors.surfaceVariant,
        foregroundColor: canSubmit ? Colors.white : AppColors.textTertiary,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      icon: state.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.report_problem_rounded),
      label: Text(
        state.isLoading ? 'Submitting...' : 'Submit Report',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _SectionLabel({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: AppColors.error, fontSize: 16),
          ),
        ],
      ],
    );
  }
}
