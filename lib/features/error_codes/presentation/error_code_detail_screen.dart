import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../core/services/gdrive_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/error_code_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class ErrorCodeDetailScreen extends StatefulWidget {
  final ErrorCodeModel errorCode;
  const ErrorCodeDetailScreen({super.key, required this.errorCode});

  @override
  State<ErrorCodeDetailScreen> createState() => _ErrorCodeDetailScreenState();
}

class _ErrorCodeDetailScreenState extends State<ErrorCodeDetailScreen> {
  final _activityLogService = ActivityLogService();

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingErrorCode(
      errorCodeId: widget.errorCode.id,
      errorCode: widget.errorCode.code,
    );
  }

  @override
  void dispose() {
    _activityLogService.endCurrentActivity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor:
                AppTheme.getSeverityColor(widget.errorCode.severity),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.getSeverityColor(widget.errorCode.severity),
                      AppTheme.getSeverityColor(widget.errorCode.severity)
                          .withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          widget.errorCode.code,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.errorCode.title,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SeverityBadge(severity: widget.errorCode.severity),
                      if (widget.errorCode.machineType != null)
                        _buildInfoChip(
                            Iconsax.cpu, widget.errorCode.machineType!),
                      if (widget.errorCode.category != null)
                        _buildInfoChip(
                            Iconsax.category, widget.errorCode.category!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cause section
                  _buildSection(
                    icon: Iconsax.warning_2,
                    title: 'Penyebab',
                    color: AppTheme.warningColor,
                    content: widget.errorCode.cause,
                  ),
                  const SizedBox(height: 20),

                  // Solution section
                  _buildSection(
                    icon: Iconsax.tick_circle,
                    title: 'Solusi',
                    color: AppTheme.successColor,
                    content: widget.errorCode.solution,
                  ),

                  // Images section
                  if (widget.errorCode.images != null &&
                      widget.errorCode.images!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildImagesSection(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(text,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
                fontSize: 15, height: 1.6, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    final images = widget.errorCode.images!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.gallery,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Gambar Referensi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${images.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Padding(
                padding:
                    EdgeInsets.only(right: index < images.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () => _showImageViewer(image),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: NetworkImageWidget(
                              imageUrl: GDriveService().getThumbnailUrl(
                                  image.gdriveFileId,
                                  size: 400),
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (image.caption != null)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              image.caption!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageViewer(ErrorCodeImageModel image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            image.caption ?? 'Gambar ${image.imageTypeLabel}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Image
                  Flexible(
                    child: InteractiveViewer(
                      child: NetworkImageWidget(
                        imageUrl: GDriveService()
                            .getDirectDownloadUrl(image.gdriveFileId),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
