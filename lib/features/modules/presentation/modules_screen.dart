import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
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
  List<ModuleModel> _filteredModules = [];
  bool _isLoading = true;
  String? _error;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applySearch();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredModules = _modules;
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredModules = List.from(_modules);
    } else {
      final query = _searchQuery.toLowerCase().trim();
      _filteredModules = _modules.where((module) {
        final title = module.title.toLowerCase();
        final description = (module.description ?? '').toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }
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
        _applySearch();
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
      appBar: widget.embedded ? null : _buildAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Modul Pembelajaran'),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _loadModules,
          tooltip: 'Refresh',
        ),
      ],
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
              borderRadius: BorderRadius.circular(12),
            ),
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
                Text(
                  _searchQuery.isEmpty
                      ? '${_modules.length} modul tersedia'
                      : '${_filteredModules.length} dari ${_modules.length} modul',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadModules,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari modul...',
            hintStyle: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Iconsax.search_normal,
                size: 20, color: AppTheme.textLight),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle,
                        size: 20, color: AppTheme.textLight),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerGrid();
    if (_error != null) {
      return ErrorStateWidget(message: _error!, onRetry: _loadModules);
    }
    if (_modules.isEmpty) {
      return const EmptyStateWidget(
        icon: Iconsax.book,
        title: 'Belum Ada Modul',
        subtitle: 'Modul pembelajaran akan muncul di sini',
      );
    }
    if (_filteredModules.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.search_status,
        title: 'Tidak Ditemukan',
        subtitle: 'Tidak ada modul yang cocok dengan "$_searchQuery"',
        buttonText: 'Reset Pencarian',
        onButtonPressed: _clearSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadModules,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredModules.length,
        itemBuilder: (context, index) {
          final module = _filteredModules[index];
          return _ModuleGridCard(
            module: module,
            onTap: () => _openModule(module),
          );
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

/// ============================================================
/// SHIMMER GRID UNTUK LOADING STATE
/// ============================================================
class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  const ShimmerGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail shimmer
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
              ),
              // Content shimmer
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 20,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================
/// MODULE GRID CARD (2 COLUMN LAYOUT)
/// ============================================================
class _ModuleGridCard extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onTap;
  const _ModuleGridCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 3,
                child: _ModuleThumbnailWidget(module: module),
              ),

              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // File type badge & arrow
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.moduleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.document_text,
                                  size: 12,
                                  color: AppTheme.moduleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PDF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.moduleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Iconsax.arrow_right_3,
                            size: 14,
                            color: AppTheme.textLight,
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
      ),
    );
  }
}

/// ============================================================
/// CACHED THUMBNAIL WIDGET UNTUK MODUL
/// ============================================================
class _ModuleThumbnailWidget extends StatefulWidget {
  final ModuleModel module;
  const _ModuleThumbnailWidget({required this.module});

  @override
  State<_ModuleThumbnailWidget> createState() => _ModuleThumbnailWidgetState();
}

class _ModuleThumbnailWidgetState extends State<_ModuleThumbnailWidget> {
  File? _cachedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/module_thumbnail_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String get _cacheFileName => 'module_thumb_${widget.module.id}.jpg';

  Future<void> _loadThumbnail() async {
    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');

      if (await cachedFile.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = cachedFile;
            _isLoading = false;
          });
        }
        return;
      }

      final thumbnailUrl = widget.module.getThumbnailUrl(size: 400);

      if (thumbnailUrl.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final response = await http.get(Uri.parse(thumbnailUrl));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('image') || response.bodyBytes.length > 1000) {
          await cachedFile.writeAsBytes(response.bodyBytes);
          if (mounted) {
            setState(() {
              _cachedFile = cachedFile;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Invalid image data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Thumbnail error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnailImage(),

          // PDF badge
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.moduleColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage() {
    if (_isLoading) {
      return Container(
        color: AppTheme.moduleColor.withOpacity(0.1),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
      );
    }

    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: AppTheme.moduleColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Iconsax.document_text,
          size: 40,
          color: AppTheme.moduleColor.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// ============================================================
/// SERVICE UNTUK MENGELOLA CACHE THUMBNAIL MODUL
/// ============================================================
class ModuleThumbnailCacheService {
  static final ModuleThumbnailCacheService _instance =
      ModuleThumbnailCacheService._internal();
  factory ModuleThumbnailCacheService() => _instance;
  ModuleThumbnailCacheService._internal();

  static Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/module_thumbnail_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('🗑️ Module thumbnail cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing module thumbnail cache: $e');
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/module_thumbnail_cache');
      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (final file in cacheDir.list()) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        return totalSize;
      }
    } catch (e) {
      debugPrint('Error getting cache size: $e');
    }
    return 0;
  }

  static Future<String> getFormattedCacheSize() async {
    final size = await getCacheSize();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
