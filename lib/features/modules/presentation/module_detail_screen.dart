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

  // PDF States
  bool _isLoading = true;
  bool _isFromCache = false;
  String? _error;
  File? _pdfFile;
  double _downloadProgress = 0.0;

  // PDF tracking
  int _currentPage = 1;
  int _totalPages = 0;
  final Set<int> _viewedPages = {};

  // Search states
  bool _showSearchBar = false;
  bool _isSearching = false;
  PdfTextSearchResult? _searchResult;
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

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

  String get _cacheFileName => 'module_${widget.module.id}.pdf';

  @override
  void initState() {
    super.initState();
    _startTracking();
    _loadPdf();
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _downloadProgress = 0.0;
    });

    try {
      final cacheDir = await _getCacheDir();
      final cachedFile = File('${cacheDir.path}/$_cacheFileName');

      if (await cachedFile.exists()) {
        final fileSize = await cachedFile.length();
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📁 PDF LOADED FROM INTERNAL STORAGE (OFFLINE)');
        debugPrint('📍 Path: ${cachedFile.path}');
        debugPrint(
            '📊 Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        setState(() {
          _pdfFile = cachedFile;
          _isFromCache = true;
          _isLoading = false;
        });
        return;
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('⬇️ DOWNLOADING PDF...');
      debugPrint('🔗 URL: $_pdfUrl');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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

        await cachedFile.writeAsBytes(bytes);

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ PDF SAVED TO INTERNAL STORAGE');
        debugPrint('📍 Path: ${cachedFile.path}');
        debugPrint(
            '📊 Size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
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
    _clearSearch();
    _pdfController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  // ==================== SEARCH METHODS ====================

  /// Perform search with loading indicator
  Future<void> _performSearch(String searchText) async {
    if (searchText.trim().isEmpty) return;

    // Set loading state
    setState(() {
      _isSearching = true;
      _currentMatchIndex = 0;
      _totalMatches = 0;
    });

    try {
      // Perform search
      _searchResult = await _pdfController.searchText(searchText);

      if (_searchResult != null && _searchResult!.hasResult) {
        // Add listener for navigation updates
        _searchResult!.addListener(_onSearchResultChanged);

        setState(() {
          _totalMatches = _searchResult!.totalInstanceCount;
          _currentMatchIndex = _searchResult!.currentInstanceIndex;
          _isSearching = false;
        });

        debugPrint('🔍 Search found: $_totalMatches results for "$searchText"');
      } else {
        setState(() {
          _totalMatches = 0;
          _currentMatchIndex = 0;
          _isSearching = false;
        });

        // Show not found message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak ditemukan: "$searchText"'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      setState(() {
        _isSearching = false;
        _totalMatches = 0;
      });
    }
  }

  /// Listener for search result navigation changes
  void _onSearchResultChanged() {
    if (_searchResult != null && mounted) {
      setState(() {
        _currentMatchIndex = _searchResult!.currentInstanceIndex;
        _totalMatches = _searchResult!.totalInstanceCount;
      });
    }
  }

  /// Navigate to next match
  void _goToNextMatch() {
    if (_searchResult != null && _searchResult!.hasResult) {
      _searchResult!.nextInstance();
    }
  }

  /// Navigate to previous match
  void _goToPreviousMatch() {
    if (_searchResult != null && _searchResult!.hasResult) {
      _searchResult!.previousInstance();
    }
  }

  /// Clear search and reset state
  void _clearSearch() {
    if (_searchResult != null) {
      _searchResult!.removeListener(_onSearchResultChanged);
      _searchResult!.clear();
    }
    setState(() {
      _searchResult = null;
      _currentMatchIndex = 0;
      _totalMatches = 0;
      _isSearching = false;
    });
  }

  /// Toggle search bar visibility
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _clearSearch();
        _searchController.clear();
      }
    });
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_showSearchBar) {
      return AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _buildSearchBar(),
      );
    }

    return AppBar(
      title: Text(widget.module.title),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearchBar,
          tooltip: 'Cari teks',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshPdf,
          tooltip: 'Muat ulang',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        // Back button
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearchBar,
        ),
        // Search input
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari teks dalam PDF...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: _performSearch,
          ),
        ),
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _performSearch(_searchController.text),
        ),
      ],
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Error state
    if (_error != null) {
      return _buildErrorState();
    }

    // PDF loaded
    if (_pdfFile != null) {
      return _buildPdfViewer();
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
              _downloadProgress > 0 ? 'Mengunduh PDF...' : 'Memeriksa cache...',
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

  Widget _buildPdfViewer() {
    return Column(
      children: [
        // Search results bar (shown when searching or has results)
        if (_showSearchBar && (_isSearching || _totalMatches > 0))
          _buildSearchResultsBar(),

        // Cache indicator (hidden when search bar is shown)
        if (!_showSearchBar) _buildCacheIndicator(),

        // Page indicator
        if (_totalPages > 0) _buildPageIndicator(),

        // PDF Viewer
        Expanded(
          child: SfPdfViewer.file(
            _pdfFile!,
            controller: _pdfController,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            scrollDirection: PdfScrollDirection.vertical,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            currentSearchTextHighlightColor: Colors.yellow.withOpacity(0.8),
            otherSearchTextHighlightColor: Colors.yellow.withOpacity(0.3),
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

  Widget _buildSearchResultsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade200),
        ),
      ),
      child: Row(
        children: [
          // Loading indicator or result icon
          if (_isSearching)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          else
            Icon(
              _totalMatches > 0 ? Icons.check_circle : Icons.info_outline,
              size: 20,
              color: _totalMatches > 0 ? Colors.green : Colors.orange,
            ),
          const SizedBox(width: 12),

          // Results text
          Expanded(
            child: Text(
              _isSearching
                  ? 'Mencari...'
                  : _totalMatches > 0
                      ? '$_currentMatchIndex dari $_totalMatches hasil'
                      : 'Tidak ada hasil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.amber.shade900,
              ),
            ),
          ),

          // Navigation buttons (only show if more than 1 result)
          if (!_isSearching && _totalMatches > 1) ...[
            // Previous button (Arrow Up)
            _buildNavButton(
              icon: Icons.keyboard_arrow_up,
              onTap: _goToPreviousMatch,
              tooltip: 'Hasil sebelumnya',
            ),
            const SizedBox(width: 8),
            // Next button (Arrow Down)
            _buildNavButton(
              icon: Icons.keyboard_arrow_down,
              onTap: _goToNextMatch,
              tooltip: 'Hasil selanjutnya',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.amber.shade900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCacheIndicator() {
    return Container(
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
          Flexible(
            child: Text(
              _isFromCache
                  ? 'Offline Mode - Dimuat dari penyimpanan'
                  : 'Tersimpan - Tersedia offline',
              style: TextStyle(
                fontSize: 11,
                color:
                    _isFromCache ? Colors.green.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey.shade100,
      child: Text(
        'Halaman $_currentPage dari $_totalPages',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
