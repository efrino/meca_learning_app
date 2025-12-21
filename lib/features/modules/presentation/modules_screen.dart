import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
// ignore: unused_import
import '../../../core/services/gdrive_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class ModulesScreen extends StatefulWidget {
  final bool embedded;
  const ModulesScreen({super.key, this.embedded = false});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  List<ModuleModel> _modules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getModules(category: 'module');
      setState(() {
        _modules = data.map((e) => ModuleModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat modul: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Modul Pembelajaran')),
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
                color: AppTheme.moduleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.book_1,
                color: AppTheme.moduleColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modul Pembelajaran',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${_modules.length} modul tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadModules),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadModules);
    if (_modules.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.book,
          title: 'Belum Ada Modul',
          subtitle: 'Modul pembelajaran akan muncul di sini');

    return RefreshIndicator(
      onRefresh: _loadModules,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _modules.length,
        itemBuilder: (context, index) {
          final module = _modules[index];
          return _ModuleCard(module: module, onTap: () => _openModule(module));
        },
      ),
    );
  }

  void _openModule(ModuleModel module) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_module_${module.id}', screenName: 'modules_screen');
    Navigator.pushNamed(context, AppRoutes.moduleDetail, arguments: module);
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onTap;
  const _ModuleCard({required this.module, required this.onTap});

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
                      color: AppTheme.moduleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.document_text,
                      color: AppTheme.moduleColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (module.description != null) ...[
                        const SizedBox(height: 4),
                        Text(module.description!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Iconsax.document,
                              size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          const Text('PDF',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textLight)),
                          if (module.durationMinutes != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Iconsax.clock,
                                size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text(module.durationLabel,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textLight))
                          ],
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
