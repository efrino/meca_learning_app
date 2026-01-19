import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class AnimationsScreen extends StatefulWidget {
  final bool embedded;
  const AnimationsScreen({super.key, this.embedded = false});

  @override
  State<AnimationsScreen> createState() => _AnimationsScreenState();
}

class _AnimationsScreenState extends State<AnimationsScreen> {
  List<ModuleModel> _animations = [];
  List<ModuleModel> _filteredAnimations = [];
  bool _isLoading = true;
  String? _error;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Video cache status tracking
  Map<String, bool> _videoCacheStatus = {};

  @override
  void initState() {
    super.initState();
    _loadAnimations();
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
      _filteredAnimations = List.from(_animations);
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredAnimations = List.from(_animations);
    } else {
      final query = _searchQuery.toLowerCase().trim();
      _filteredAnimations = _animations.where((animation) {
        final title = animation.title.toLowerCase();
        final description = (animation.description ?? '').toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }
  }

  Future<void> _loadAnimations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getModules(category: 'animation');
      setState(() {
        _animations = data.map((e) => ModuleModel.fromJson(e)).toList();
        _applySearch();
        _isLoading = false;
      });

      // Check video cache status after loading animations
      _checkVideoCacheStatus();
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat animasi: $e';
        _isLoading = false;
      });
    }
  }

  /// Check cache status for all videos (non-blocking)
  Future<void> _checkVideoCacheStatus() async {
    final Map<String, bool> newStatus = {};

    for (final animation in _animations) {
      final isCached = await VideoCacheService.isVideoCached(animation.id);
      newStatus[animation.id] = isCached;
    }

    if (mounted) {
      setState(() {
        _videoCacheStatus = newStatus;
      });
    }
  }

  /// Get count of cached videos
  int get _cachedVideoCount {
    return _videoCacheStatus.values.where((cached) => cached).length;
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
      title: const Text('Animasi Pembelajaran'),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _loadAnimations,
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
                color: AppTheme.animationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.play_circle,
                color: AppTheme.animationColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Animasi Pembelajaran',
                    style: Theme.of(context).textTheme.titleLarge),
                // Updated subtitle with cache info and search result
                Row(
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? '${_animations.length} video'
                          : '${_filteredAnimations.length} dari ${_animations.length} video',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (_cachedVideoCount > 0 && _searchQuery.isEmpty) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Icon(
                        Icons.offline_pin,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_cachedVideoCount tersimpan',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadAnimations),
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
            hintText: 'Cari animasi...',
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
    if (_isLoading) return const ShimmerList();
    if (_error != null) {
      return ErrorStateWidget(message: _error!, onRetry: _loadAnimations);
    }
    if (_animations.isEmpty) {
      return const EmptyStateWidget(
          icon: Iconsax.play_circle,
          title: 'Belum Ada Animasi',
          subtitle: 'Video animasi akan muncul di sini');
    }
    if (_filteredAnimations.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.search_status,
        title: 'Tidak Ditemukan',
        subtitle: 'Tidak ada animasi yang cocok dengan "$_searchQuery"',
        buttonText: 'Reset Pencarian',
        onButtonPressed: _clearSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnimations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredAnimations.length,
        itemBuilder: (context, index) {
          final animation = _filteredAnimations[index];
          final isCached = _videoCacheStatus[animation.id] ?? false;

          return _AnimationCard(
            animation: animation,
            isCached: isCached,
            onTap: () => _openAnimation(animation),
          );
        },
      ),
    );
  }

  void _openAnimation(ModuleModel animation) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_animation_${animation.id}',
        screenName: 'animations_screen');

    Navigator.pushNamed(
      context,
      AppRoutes.animationPlayer,
      arguments: animation,
    ).then((_) {
      // Refresh cache status when returning from player
      _checkVideoCacheStatus();
    });
  }
}

class _AnimationCard extends StatelessWidget {
  final ModuleModel animation;
  final bool isCached;
  final VoidCallback onTap;

  const _AnimationCard({
    required this.animation,
    required this.isCached,
    required this.onTap,
  });

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play button overlay and cache badge
              _CachedThumbnailWidget(
                animation: animation,
                isCached: isCached,
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animation.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (animation.description != null) ...[
                      const SizedBox(height: 4),
                      Text(animation.description!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Iconsax.video,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        const Text('Video',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textLight)),
                        if (animation.durationMinutes != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Iconsax.clock,
                              size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(animation.durationLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textLight))
                        ],
                        const Spacer(),
                        // Offline badge in card info
                        if (isCached)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin,
                                    size: 12, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan thumbnail dengan caching ke internal storage
class _CachedThumbnailWidget extends StatefulWidget {
  final ModuleModel animation;
  final bool isCached;

  const _CachedThumbnailWidget({
    required this.animation,
    required this.isCached,
  });

  @override
  State<_CachedThumbnailWidget> createState() => _CachedThumbnailWidgetState();
}

class _CachedThumbnailWidgetState extends State<_CachedThumbnailWidget> {
  File? _cachedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  /// Get cache directory for thumbnails
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/thumbnail_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Get cache file name based on module ID
  String get _cacheFileName => 'thumb_${widget.animation.id}.jpg';

  /// Load thumbnail - from cache or download
  Future<void> _loadThumbnail() async {
    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');

      // Check if cached file exists
      if (await cachedFile.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = cachedFile;
            _isLoading = false;
          });
        }
        return;
      }

      // Get thumbnail URL
      final thumbnailUrl = widget.animation.getThumbnailUrl(size: 400);

      if (thumbnailUrl.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Download thumbnail
      final response = await http.get(Uri.parse(thumbnailUrl));

      if (response.statusCode == 200) {
        // Check if it's valid image data
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('image') || response.bodyBytes.length > 1000) {
          // Save to cache
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
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail Image
            _buildThumbnailImage(),

            // Play button overlay
            _buildPlayButtonOverlay(),

            // Duration badge (jika ada)
            if (widget.animation.durationMinutes != null) _buildDurationBadge(),

            // Video cache indicator (top-left) - shows if video is cached
            if (widget.isCached)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Tersimpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    // Loading state
    if (_isLoading) {
      return Container(
        color: AppTheme.animationColor.withOpacity(0.1),
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.animationColor),
            ),
          ),
        ),
      );
    }

    // Load from cached file
    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
      );
    }

    // Error or no URL - show default
    return _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      color: AppTheme.animationColor.withOpacity(0.15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.video,
              size: 48,
              color: AppTheme.animationColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.animationColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButtonOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.play5,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.animation.durationLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Service untuk mengelola cache video
class VideoCacheService {
  /// Check if video is cached
  static Future<bool> isVideoCached(String moduleId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videoFile =
          File('${appDir.path}/video_cache/animation_$moduleId.mp4');

      if (await videoFile.exists()) {
        // Validate file size (minimum 100KB)
        final fileSize = await videoFile.length();
        return fileSize > 100 * 1024;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking video cache: $e');
      return false;
    }
  }

  /// Get cached video count
  static Future<int> getCachedVideoCount() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');

      if (await cacheDir.exists()) {
        int count = 0;
        await for (final entity in cacheDir.list()) {
          if (entity is File && entity.path.endsWith('.mp4')) {
            final fileSize = await entity.length();
            if (fileSize > 100 * 1024) {
              count++;
            }
          }
        }
        return count;
      }
      return 0;
    } catch (e) {
      debugPrint('Error counting cached videos: $e');
      return 0;
    }
  }

  /// Clear all cached videos
  static Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('🗑️ Video cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing video cache: $e');
    }
  }

  /// Get total cache size
  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');

      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// Get formatted cache size
  static Future<String> getFormattedCacheSize() async {
    final size = await getCacheSize();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// Delete specific video
  static Future<void> deleteVideo(String moduleId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videoFile =
          File('${appDir.path}/video_cache/animation_$moduleId.mp4');
      if (await videoFile.exists()) {
        await videoFile.delete();
        debugPrint('🗑️ Video deleted: animation_$moduleId.mp4');
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
    }
  }
}

/// Service untuk mengelola cache thumbnail
class ThumbnailCacheService {
  static final ThumbnailCacheService _instance =
      ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();

  /// Clear all cached thumbnails
  static Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/thumbnail_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('🗑️ Thumbnail cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/thumbnail_cache');
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

  /// Get formatted cache size
  static Future<String> getFormattedCacheSize() async {
    final size = await getCacheSize();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
