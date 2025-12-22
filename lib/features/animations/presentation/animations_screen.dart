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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnimations();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat animasi: $e';
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
          : AppBar(title: const Text('Animasi Pembelajaran')),
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
                Text('${_animations.length} video tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadAnimations),
        ],
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

    return RefreshIndicator(
      onRefresh: _loadAnimations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _animations.length,
        itemBuilder: (context, index) {
          final animation = _animations[index];
          return _AnimationCard(
              animation: animation, onTap: () => _openAnimation(animation));
        },
      ),
    );
  }

  void _openAnimation(ModuleModel animation) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_animation_${animation.id}',
        screenName: 'animations_screen');
    Navigator.pushNamed(context, AppRoutes.animationPlayer,
        arguments: animation);
  }
}

class _AnimationCard extends StatelessWidget {
  final ModuleModel animation;
  final VoidCallback onTap;
  const _AnimationCard({required this.animation, required this.onTap});

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
              // Thumbnail with play button overlay
              _CachedThumbnailWidget(animation: animation),

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
  const _CachedThumbnailWidget({required this.animation});

  @override
  State<_CachedThumbnailWidget> createState() => _CachedThumbnailWidgetState();
}

class _CachedThumbnailWidgetState extends State<_CachedThumbnailWidget> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

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
        debugPrint('📁 Thumbnail loaded from cache: ${widget.animation.title}');
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
        debugPrint('⚠️ No thumbnail URL for: ${widget.animation.title}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      debugPrint('⬇️ Downloading thumbnail: $thumbnailUrl');

      // Download thumbnail
      final response = await http.get(Uri.parse(thumbnailUrl));

      if (response.statusCode == 200) {
        // Check if it's valid image data
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('image') || response.bodyBytes.length > 1000) {
          // Save to cache
          await cachedFile.writeAsBytes(response.bodyBytes);

          debugPrint('✅ Thumbnail cached: ${widget.animation.title}');

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
      debugPrint('❌ Thumbnail error for ${widget.animation.title}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
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

            // Cache indicator (optional, untuk debug)
            if (_cachedFile != null && !_isLoading)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, size: 10, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'Cached',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
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
      return _buildLoadingPlaceholder();
    }

    // Error or no URL - show default
    if (_hasError || _cachedFile == null) {
      return _buildDefaultThumbnail();
    }

    // Load from cached file
    return Image.file(
      _cachedFile!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Error loading cached file: $error');
        return _buildDefaultThumbnail();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppTheme.animationColor.withOpacity(0.1),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.animationColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    // Coba load dari asset, jika gagal tampilkan placeholder sederhana
    return Image.asset(
      'assets/images/thumbnail_default.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Jika asset juga tidak ada, tampilkan placeholder warna
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
      },
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
