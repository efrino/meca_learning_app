import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class MecaAidScreen extends StatefulWidget {
  final bool embedded;
  const MecaAidScreen({super.key, this.embedded = false});

  @override
  State<MecaAidScreen> createState() => _MecaAidScreenState();
}

class _MecaAidScreenState extends State<MecaAidScreen> {
  List<ModuleModel> _mecaAids = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMecaAids();
  }

  Future<void> _loadMecaAids() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getModules(category: 'meca_aid');
      setState(() {
        _mecaAids = data.map((e) => ModuleModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat Meca Aid: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded ? null : AppBar(title: const Text('Meca Aid')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.task_square,
                color: AppTheme.mecaAidColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meca Aid', style: Theme.of(context).textTheme.titleLarge),
                Text('${_mecaAids.length} latihan tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadMecaAids),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadMecaAids);
    if (_mecaAids.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.task_square,
          title: 'Belum Ada Meca Aid',
          subtitle: 'Latihan soal akan muncul di sini');

    return RefreshIndicator(
      onRefresh: _loadMecaAids,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mecaAids.length,
        itemBuilder: (context, index) {
          final mecaAid = _mecaAids[index];
          return _MecaAidCard(
              mecaAid: mecaAid, onTap: () => _openMecaAid(mecaAid));
        },
      ),
    );
  }

  void _openMecaAid(ModuleModel mecaAid) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_meca_aid_${mecaAid.id}', screenName: 'meca_aid_screen');
    Navigator.pushNamed(context, AppRoutes.mecaAidDetail, arguments: mecaAid);
  }
}

class _MecaAidCard extends StatelessWidget {
  final ModuleModel mecaAid;
  final VoidCallback onTap;
  const _MecaAidCard({required this.mecaAid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: AppTheme.mecaAidColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.task_square,
                      color: AppTheme.mecaAidColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mecaAid.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (mecaAid.description != null) ...[
                        const SizedBox(height: 4),
                        Text(mecaAid.description!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppTheme.mecaAidColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.document_text,
                                    size: 12, color: AppTheme.mecaAidColor),
                                SizedBox(width: 4),
                                Text('Materi + Quiz',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mecaAidColor,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
