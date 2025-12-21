import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Custom cache manager untuk PDF files
class PdfCacheManager {
  static const key = 'pdfCacheManager';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache selama 30 hari
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class PdfCacheService {
  static final PdfCacheService _instance = PdfCacheService._internal();
  factory PdfCacheService() => _instance;
  PdfCacheService._internal();

  final _cacheManager = PdfCacheManager.instance;

  /// Check if PDF is in cache
  Future<FileInfo?> getFileFromCache(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        debugPrint('PDF found in cache: ${fileInfo.file.path}');
        return fileInfo;
      }
      debugPrint('PDF not in cache');
      return null;
    } catch (e) {
      debugPrint('Error checking cache: $e');
      return null;
    }
  }

  /// Download PDF with progress and cache it
  Future<File?> downloadFile({
    required String url,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('Downloading PDF from: $url');

      // Gunakan downloadFile untuk tracking progress
      final stream = _cacheManager.getFileStream(
        url,
        withProgress: true,
      );

      File? resultFile;

      await for (final result in stream) {
        if (result is DownloadProgress) {
          final progress = result.totalSize != null && result.totalSize! > 0
              ? result.downloaded / result.totalSize!
              : 0.0;
          onProgress?.call(progress);
          debugPrint(
              'Download progress: ${(progress * 100).toStringAsFixed(1)}%');
        } else if (result is FileInfo) {
          resultFile = result.file;
          onProgress?.call(1.0);
          debugPrint('PDF cached at: ${result.file.path}');
        }
      }

      return resultFile;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      return null;
    }
  }

  /// Get file - from cache or download
  Future<File?> getFile({
    required String url,
    Function(double progress)? onProgress,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        await _cacheManager.removeFile(url);
      }

      // Check cache first
      final cached = await getFileFromCache(url);
      if (cached != null && !forceRefresh) {
        onProgress?.call(1.0);
        return cached.file;
      }

      // Download if not cached
      return await downloadFile(url: url, onProgress: onProgress);
    } catch (e) {
      debugPrint('Error getting file: $e');
      return null;
    }
  }

  /// Check if URL is cached
  Future<bool> isFileCached(String url) async {
    final fileInfo = await getFileFromCache(url);
    return fileInfo != null;
  }

  /// Remove specific file from cache
  Future<void> removeFile(String url) async {
    try {
      await _cacheManager.removeFile(url);
      debugPrint('Removed from cache: $url');
    } catch (e) {
      debugPrint('Error removing file: $e');
    }
  }

  /// Clear all cached PDFs
  Future<void> clearAllCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('All PDF cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache info (approximate)
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final pdfCacheDir = Directory(
          '${cacheDir.path}/libCachedImageData/${PdfCacheManager.key}');

      int fileCount = 0;
      int totalSize = 0;

      if (await pdfCacheDir.exists()) {
        await for (final entity in pdfCacheDir.list(recursive: true)) {
          if (entity is File) {
            fileCount++;
            totalSize += await entity.length();
          }
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'formattedSize': _formatBytes(totalSize),
      };
    } catch (e) {
      debugPrint('Error getting cache info: $e');
      return {
        'fileCount': 0,
        'totalSize': 0,
        'formattedSize': '0 B',
      };
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
