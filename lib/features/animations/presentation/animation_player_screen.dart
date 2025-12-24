// ignore_for_file: unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';

class AnimationPlayerScreen extends StatefulWidget {
  final ModuleModel module;
  const AnimationPlayerScreen({super.key, required this.module});

  @override
  State<AnimationPlayerScreen> createState() => _AnimationPlayerScreenState();
}

class _AnimationPlayerScreenState extends State<AnimationPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final _activityLogService = ActivityLogService();

  // Video states
  bool _isLoading = true;
  bool _isFromCache = false;
  String? _error;
  File? _videoFile;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;

  // Tracking states
  Duration _maxWatchedPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _lastTrackedSecond = -1;

  String get _videoUrl =>
      'https://drive.google.com/uc?export=download&id=${widget.module.gdriveFileId}';

  String get _cacheFileName => 'animation_${widget.module.id}.mp4';

  @override
  void initState() {
    super.initState();
    _startTracking();
    _loadVideo();
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  // ==================== VIDEO CACHING ====================

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/video_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _downloadProgress = 0.0;
      _downloadedBytes = 0;
      _totalBytes = 0;
    });

    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');

      // Check if video is already cached
      if (await cachedFile.exists()) {
        final fileSize = await cachedFile.length();

        // Validate file size (minimum 100KB to ensure it's not corrupted)
        if (fileSize > 100 * 1024) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('🎬 VIDEO LOADED FROM INTERNAL STORAGE (OFFLINE)');
          debugPrint('📍 Path: ${cachedFile.path}');
          debugPrint('📊 Size: ${_formatFileSize(fileSize)}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          setState(() {
            _videoFile = cachedFile;
            _isFromCache = true;
          });

          await _initializeVideoPlayer(cachedFile);
          return;
        } else {
          // File corrupted, delete and re-download
          await cachedFile.delete();
          debugPrint('🗑️ Corrupted cache deleted');
        }
      }

      // Download video
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('⬇️ DOWNLOADING VIDEO...');
      debugPrint('🔗 URL: $_videoUrl');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final request = http.Request('GET', Uri.parse(_videoUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        _totalBytes = response.contentLength ?? 0;
        final List<int> bytes = [];
        _downloadedBytes = 0;

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          _downloadedBytes += chunk.length;

          if (_totalBytes > 0) {
            setState(() {
              _downloadProgress = _downloadedBytes / _totalBytes;
            });
          }
        }

        // Save to cache
        await cachedFile.writeAsBytes(bytes);

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ VIDEO SAVED TO INTERNAL STORAGE');
        debugPrint('📍 Path: ${cachedFile.path}');
        debugPrint('📊 Size: ${_formatFileSize(bytes.length)}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        setState(() {
          _videoFile = cachedFile;
          _isFromCache = false;
        });

        await _initializeVideoPlayer(cachedFile);
      } else {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading video: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    try {
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();

      _totalDuration = _videoController!.value.duration;
      _videoController!.addListener(_onVideoProgress);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.animationColor,
          handleColor: AppTheme.animationColor,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshVideo,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });

      debugPrint(
          '🎬 Video player initialized: ${_formatDuration(_totalDuration)}');
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      setState(() {
        _error = 'Gagal memutar video: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshVideo() async {
    // Dispose current controllers
    _videoController?.removeListener(_onVideoProgress);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;

    // Delete cache
    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');
      if (await cachedFile.exists()) {
        await cachedFile.delete();
        debugPrint('🗑️ Video cache deleted: ${cachedFile.path}');
      }
    } catch (e) {
      debugPrint('Error deleting cache: $e');
    }

    // Reload
    _loadVideo();
  }

  // ==================== PROGRESS TRACKING ====================

  void _onVideoProgress() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final currentPosition = _videoController!.value.position;

    // Update max watched position
    if (currentPosition > _maxWatchedPosition) {
      _maxWatchedPosition = currentPosition;
    }

    // Update tracking every 10 seconds (avoid duplicate updates)
    final currentSecond = currentPosition.inSeconds;
    if (currentSecond > 0 &&
        currentSecond % 10 == 0 &&
        currentSecond != _lastTrackedSecond) {
      _lastTrackedSecond = currentSecond;

      final watchPercent = _totalDuration.inSeconds > 0
          ? ((_maxWatchedPosition.inSeconds / _totalDuration.inSeconds) * 100)
              .round()
          : 0;

      _activityLogService.updateCurrentActivity(
        videoWatchPercent: watchPercent,
        actionDetail:
            'watching at ${currentSecond}s of ${_totalDuration.inSeconds}s',
      );

      debugPrint('📊 Progress tracked: $watchPercent% (${currentSecond}s)');
    }
  }

  @override
  void dispose() {
    _endTracking();
    _videoController?.removeListener(_onVideoProgress);
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _endTracking() async {
    final watchPercent = _totalDuration.inSeconds > 0
        ? ((_maxWatchedPosition.inSeconds / _totalDuration.inSeconds) * 100)
            .round()
        : 0;

    await _activityLogService.endCurrentActivity(
      videoWatchPercent: watchPercent,
    );

    debugPrint('📊 Final activity recorded: $watchPercent% watched');
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.module.title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _videoFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshVideo,
              tooltip: 'Muat ulang',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_chewieController != null) {
      return _buildVideoPlayer();
    }

    return const SizedBox();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.animationColor,
                    ),
                    backgroundColor: Colors.white24,
                  ),
                  if (_downloadProgress > 0)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_downloadProgress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _downloadProgress > 0
                  ? 'Mengunduh Video...'
                  : 'Memeriksa cache...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Download progress detail
            if (_downloadProgress > 0 && _totalBytes > 0)
              Text(
                '${_formatFileSize(_downloadedBytes)} / ${_formatFileSize(_totalBytes)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

            const SizedBox(height: 16),

            // Info text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Video akan disimpan untuk akses offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.animationColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        // Cache status indicator
        _buildCacheIndicator(),

        // Video player
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ),
        ),

        // Video info
        _buildVideoInfo(),
      ],
    );
  }

  Widget _buildCacheIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _isFromCache
          ? Colors.green.withOpacity(0.2)
          : AppTheme.animationColor.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isFromCache ? Icons.offline_pin : Icons.cloud_done,
            size: 14,
            color: _isFromCache ? Colors.green : AppTheme.animationColor,
          ),
          const SizedBox(width: 8),
          Text(
            _isFromCache
                ? 'Offline Mode - Dimuat dari penyimpanan'
                : 'Tersimpan - Tersedia offline',
            style: TextStyle(
              fontSize: 11,
              color: _isFromCache ? Colors.green : AppTheme.animationColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.module.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.module.description!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Durasi: ${_formatDuration(_totalDuration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (_videoFile != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Iconsax.folder,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  FutureBuilder<int>(
                    future: _videoFile!.length(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.hasData
                            ? _formatFileSize(snapshot.data!)
                            : '...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ==================== VIDEO CACHE SERVICE ====================

/// Service untuk mengelola cache video
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

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

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');
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
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get cached video count
  static Future<int> getCachedVideoCount() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');
      if (await cacheDir.exists()) {
        int count = 0;
        await for (final file in cacheDir.list()) {
          if (file is File && file.path.endsWith('.mp4')) {
            count++;
          }
        }
        return count;
      }
    } catch (e) {
      debugPrint('Error getting cached video count: $e');
    }
    return 0;
  }

  /// Check if specific video is cached
  static Future<bool> isVideoCached(String moduleId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cachedFile =
          File('${appDir.path}/video_cache/animation_$moduleId.mp4');
      return await cachedFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete specific cached video
  static Future<void> deleteVideo(String moduleId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cachedFile =
          File('${appDir.path}/video_cache/animation_$moduleId.mp4');
      if (await cachedFile.exists()) {
        await cachedFile.delete();
        debugPrint('🗑️ Deleted cached video: $moduleId');
      }
    } catch (e) {
      debugPrint('Error deleting cached video: $e');
    }
  }
}
