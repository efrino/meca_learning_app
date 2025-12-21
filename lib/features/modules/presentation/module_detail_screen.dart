import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';

class ModuleDetailScreen extends StatefulWidget {
  final ModuleModel module;
  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final _activityLogService = ActivityLogService();

  // States
  bool _isLoading = true;
  bool _isFromCache = false;
  String? _error;
  File? _pdfFile;
  double _downloadProgress = 0.0;

  // PDF tracking
  int _currentPage = 1;
  int _totalPages = 0;
  final Set<int> _viewedPages = {};

  String get _pdfUrl {
    if (widget.module.gdriveUrl != null &&
        widget.module.gdriveUrl!.isNotEmpty) {
      final url = widget.module.gdriveUrl!;
      if (url.contains('/view') || url.contains('/d/')) {
        final fileId = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
        if (fileId != null) {
          return 'https://drive.google.com/uc?export=download&id=$fileId';
        }
      }
      return url;
    }
    return 'https://drive.google.com/uc?export=download&id=${widget.module.gdriveFileId}';
  }

  /// Nama file cache dengan format: module_{id}.pdf
  String get _cacheFileName => 'module_${widget.module.id}.pdf';

  @override
  void initState() {
    super.initState();
    _startTracking();
    _loadPdf();
  }

  /// Start activity tracking
  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  /// Get internal storage cache directory
  /// Path: /data/data/{package}/app_flutter/pdf_cache/
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Load PDF - from cache or download
  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _downloadProgress = 0.0;
    });

    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');

      // ========== CHECK CACHE FIRST ==========
      if (await cachedFile.exists()) {
        final fileSize = await cachedFile.length();
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📁 PDF LOADED FROM INTERNAL STORAGE (OFFLINE)');
        debugPrint('📍 Path: ${cachedFile.path}');
        debugPrint(
            '📊 Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint('🌐 No internet required!');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        setState(() {
          _pdfFile = cachedFile;
          _isFromCache = true;
          _isLoading = false;
        });
        return;
      }

      // ========== DOWNLOAD IF NOT CACHED ==========
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('⬇️ DOWNLOADING PDF...');
      debugPrint('🔗 URL: $_pdfUrl');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Download with progress tracking
      final request = http.Request('GET', Uri.parse(_pdfUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final List<int> bytes = [];
        int downloaded = 0;

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          downloaded += chunk.length;

          if (contentLength > 0) {
            setState(() {
              _downloadProgress = downloaded / contentLength;
            });
          }
        }

        // ========== SAVE TO INTERNAL STORAGE ==========
        await cachedFile.writeAsBytes(bytes);

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ PDF SAVED TO INTERNAL STORAGE');
        debugPrint('📍 Path: ${cachedFile.path}');
        debugPrint(
            '📊 Size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint('💾 Available offline for next visit!');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        setState(() {
          _pdfFile = cachedFile;
          _isFromCache = false;
          _isLoading = false;
        });
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading PDF: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Force refresh - delete cache and re-download
  Future<void> _refreshPdf() async {
    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');
      if (await cachedFile.exists()) {
        await cachedFile.delete();
        debugPrint('🗑️ Cache deleted: ${cachedFile.path}');
      }
    } catch (e) {
      debugPrint('Error deleting cache: $e');
    }
    _loadPdf();
  }

  @override
  void dispose() {
    _endTracking();
    _pdfController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// End activity tracking with metrics
  Future<void> _endTracking() async {
    final scrollDepth = _totalPages > 0
        ? ((_viewedPages.length / _totalPages) * 100).round()
        : 0;

    await _activityLogService.endCurrentActivity(
      scrollDepthPercent: scrollDepth,
      pdfPagesViewed: _viewedPages.toList(),
    );

    debugPrint(
        '📊 Activity recorded: $scrollDepth% read, ${_viewedPages.length}/$_totalPages pages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Cari teks',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPdf,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state with progress
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      strokeWidth: 4,
                    ),
                    if (_downloadProgress > 0)
                      Text(
                        '${(_downloadProgress * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _downloadProgress > 0
                    ? 'Mengunduh PDF...'
                    : 'Memeriksa cache...',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'File akan disimpan untuk akses offline',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // PDF loaded
    if (_pdfFile != null) {
      return Column(
        children: [
          // Cache indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: _isFromCache ? Colors.green.shade50 : Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isFromCache ? Icons.offline_pin : Icons.cloud_download,
                  size: 16,
                  color: _isFromCache ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFromCache
                      ? '📁 Offline Mode - Dimuat dari penyimpanan internal'
                      : '✅ Tersimpan - Tersedia offline untuk kunjungan berikutnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isFromCache
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Page indicator
          if (_totalPages > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.grey.shade100,
              child: Text(
                'Halaman $_currentPage dari $_totalPages',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),

          // PDF Viewer - VERTICAL SCROLL
          Expanded(
            child: SfPdfViewer.file(
              _pdfFile!,
              controller: _pdfController,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              onDocumentLoaded: (details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _viewedPages.add(1);
                });
                debugPrint('📄 PDF loaded: $_totalPages pages');
              },
              onDocumentLoadFailed: (details) {
                debugPrint('❌ PDF load failed: ${details.error}');
                setState(() {
                  _error = 'Gagal memuat file: ${details.error}';
                  _pdfFile = null;
                });
              },
              onPageChanged: (details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                  _viewedPages.add(details.newPageNumber);
                });

                // Update tracking setiap 3 halaman baru
                if (_viewedPages.length % 3 == 0) {
                  _activityLogService.updateCurrentActivity(
                    scrollDepthPercent:
                        ((_viewedPages.length / _totalPages) * 100).round(),
                    pdfPagesViewed: _viewedPages.toList(),
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cari Teks'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan kata kunci',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              _pdfController.searchText(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final searchText = _searchController.text;
              Navigator.pop(context);
              if (searchText.isNotEmpty) {
                _pdfController.searchText(searchText);
              }
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }
}
