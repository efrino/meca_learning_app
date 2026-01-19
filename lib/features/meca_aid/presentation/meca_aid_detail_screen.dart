import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';

class MecaAidDetailScreen extends StatefulWidget {
  final ModuleModel module;
  const MecaAidDetailScreen({super.key, required this.module});

  @override
  State<MecaAidDetailScreen> createState() => _MecaAidDetailScreenState();
}

class _MecaAidDetailScreenState extends State<MecaAidDetailScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final _activityLogService = ActivityLogService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // PDF state
  int _currentPage = 1;
  int _totalPages = 0;
  final Set<int> _viewedPages = {};
  bool _isSearchOpen = false;
  PdfTextSearchResult? _searchResult;

  // PDF loading state
  bool _isLoadingPdf = false;
  String? _pdfError;
  Uint8List? _pdfBytes;
  String _pdfLoadingStatus = 'Memulai...';

  // Excel state
  Excel? _excelData;
  bool _isLoadingExcel = false;
  String? _excelError;
  String _selectedSheet = '';
  List<String> _sheetNames = [];
  String _loadingStatus = 'Memulai...';

  // Content type detection
  late ContentType _contentType;

  // Debug logging
  void _log(String message) {
    debugPrint('[MecaAidDetail] $message');
  }

  @override
  void initState() {
    super.initState();
    _detectContentType();
    _startTracking();
  }

  void _detectContentType() {
    // Use existing ModuleModel getters
    _log('Detecting content type for: ${widget.module.title}');
    _log(
        'FileType: ${widget.module.fileType}, isExcel: ${widget.module.isExcel}, isPdf: ${widget.module.isPdf}');
    _log('GDrive FileID: ${widget.module.gdriveFileId}');

    if (widget.module.isExcel) {
      _contentType = ContentType.excel;
      _loadExcelFile();
    } else {
      // Default to PDF
      _contentType = ContentType.pdf;
      _loadPdfFile();
    }
  }

  /// Get cache directory path for files
  Future<String> _getCacheFilePath(String type) async {
    final cacheDir = await getApplicationCacheDirectory();
    final typeCacheDir = Directory('${cacheDir.path}/${type}_cache');
    if (!await typeCacheDir.exists()) {
      await typeCacheDir.create(recursive: true);
    }
    final extension = type == 'excel' ? 'xlsx' : 'pdf';
    return '${typeCacheDir.path}/${widget.module.gdriveFileId}.$extension';
  }

  /// Check if cached file exists and is valid
  Future<File?> _getCachedFile(String type) async {
    try {
      final filePath = await _getCacheFilePath(type);
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        // Cache valid for 7 days
        final cacheAge = DateTime.now().difference(stat.modified);
        if (cacheAge.inDays < 7) {
          _log(
              '[$type] Cache hit! File age: ${cacheAge.inHours} hours, size: ${stat.size} bytes');
          return file;
        } else {
          _log('[$type] Cache expired. Age: ${cacheAge.inDays} days');
          await file.delete();
        }
      } else {
        _log('[$type] No cache found');
      }
    } catch (e) {
      _log('[$type] Cache check error: $e');
    }
    return null;
  }

  /// Save file to cache
  Future<void> _saveToCache(String type, Uint8List bytes) async {
    try {
      final filePath = await _getCacheFilePath(type);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      _log('[$type] Saved to cache: $filePath (${bytes.length} bytes)');
    } catch (e) {
      _log('[$type] Cache save error: $e');
    }
  }

  /// Clear cache for specific type
  Future<void> _clearCache(String type) async {
    try {
      final filePath = await _getCacheFilePath(type);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _log('[$type] Cache cleared');
      }
    } catch (e) {
      _log('[$type] Clear cache error: $e');
    }
  }

  // ==================== PDF LOADING ====================
  Future<void> _loadPdfFile() async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
      _pdfLoadingStatus = 'Memeriksa cache...';
    });

    try {
      Uint8List? fileBytes;

      // Step 1: Check cache first
      _log('[PDF] Step 1: Checking cache...');
      final cachedFile = await _getCachedFile('pdf');
      if (cachedFile != null) {
        setState(() => _pdfLoadingStatus = 'Memuat dari cache...');
        fileBytes = await cachedFile.readAsBytes();
        _log('[PDF] Loaded from cache: ${fileBytes.length} bytes');
      }

      // Step 2: Download if not cached
      if (fileBytes == null) {
        setState(() => _pdfLoadingStatus = 'Mengunduh file...');
        fileBytes = await _downloadFromGoogleDrive('pdf');

        if (fileBytes != null) {
          // Save to cache for future use
          await _saveToCache('pdf', fileBytes);
        }
      }

      if (fileBytes == null) {
        throw Exception('Gagal mendapatkan file PDF');
      }

      // Validate PDF
      if (!_isValidPdfFile(fileBytes)) {
        throw Exception('File bukan PDF yang valid');
      }

      setState(() {
        _pdfBytes = fileBytes;
        _isLoadingPdf = false;
      });

      _log('[PDF] PDF loaded successfully! Size: ${fileBytes.length} bytes');
    } catch (e, stack) {
      _log('[PDF] ERROR loading PDF: $e');
      _log('[PDF] Stack trace: $stack');
      setState(() {
        _pdfError = 'Gagal memuat file PDF:\n$e';
        _isLoadingPdf = false;
      });
    }
  }

  /// Check if bytes represent a valid PDF file
  bool _isValidPdfFile(Uint8List bytes) {
    if (bytes.length < 5) return false;

    // PDF files start with %PDF-
    // Magic bytes: 25 50 44 46 2D
    if (bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D) {
      _log('[PDF] Valid PDF format detected');
      return true;
    }

    _log(
        '[PDF] Invalid file format. First 10 bytes: ${bytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Also log as string for debugging HTML responses
    try {
      final firstChars = String.fromCharCodes(bytes.take(100));
      _log('[PDF] First 100 chars: $firstChars');
    } catch (_) {}

    return false;
  }

  // ==================== EXCEL LOADING ====================
  Future<void> _loadExcelFile() async {
    setState(() {
      _isLoadingExcel = true;
      _excelError = null;
      _loadingStatus = 'Memeriksa cache...';
    });

    try {
      Uint8List? fileBytes;

      // Step 1: Check cache first
      _log('[Excel] Step 1: Checking cache...');
      final cachedFile = await _getCachedFile('excel');
      if (cachedFile != null) {
        setState(() => _loadingStatus = 'Memuat dari cache...');
        fileBytes = await cachedFile.readAsBytes();
        _log('[Excel] Loaded from cache: ${fileBytes.length} bytes');
      }

      // Step 2: Download if not cached
      if (fileBytes == null) {
        setState(() => _loadingStatus = 'Mengunduh file...');
        fileBytes = await _downloadFromGoogleDrive('excel');

        if (fileBytes != null) {
          // Save to cache for future use
          await _saveToCache('excel', fileBytes);
        }
      }

      if (fileBytes == null) {
        throw Exception('Gagal mendapatkan file');
      }

      // Step 3: Parse Excel
      setState(() => _loadingStatus = 'Memproses Excel...');
      _log('[Excel] Step 3: Parsing Excel (${fileBytes.length} bytes)...');

      final excel = Excel.decodeBytes(fileBytes);
      _log('[Excel] Excel parsed. Sheets: ${excel.tables.keys.toList()}');

      setState(() {
        _excelData = excel;
        _sheetNames = excel.tables.keys.toList();
        if (_sheetNames.isNotEmpty) {
          _selectedSheet = _sheetNames.first;
        }
        _isLoadingExcel = false;
      });

      _log('[Excel] Excel loaded successfully!');
    } catch (e, stack) {
      _log('[Excel] ERROR loading Excel: $e');
      _log('[Excel] Stack trace: $stack');
      setState(() {
        _excelError = 'Gagal memuat file Excel:\n$e';
        _isLoadingExcel = false;
      });
    }
  }

  /// Download file from Google Drive with proper redirect handling
  Future<Uint8List?> _downloadFromGoogleDrive(String type) async {
    final fileId = widget.module.gdriveFileId;
    _log('[$type] Downloading from Google Drive. FileID: $fileId');

    // Try multiple URL formats
    final urls = [
      // Direct export (works for most files)
      'https://drive.google.com/uc?export=download&id=$fileId',
      // Confirm download (for larger files with virus scan warning)
      'https://drive.google.com/uc?export=download&confirm=t&id=$fileId',
      // With confirm=yes
      'https://drive.google.com/uc?export=download&confirm=yes&id=$fileId',
    ];

    final client = http.Client();

    try {
      for (int i = 0; i < urls.length; i++) {
        final url = urls[i];
        _log('[$type] Trying URL ${i + 1}/${urls.length}: $url');

        if (type == 'pdf') {
          setState(() =>
              _pdfLoadingStatus = 'Mengunduh... (${i + 1}/${urls.length})');
        } else {
          setState(
              () => _loadingStatus = 'Mengunduh... (${i + 1}/${urls.length})');
        }

        try {
          final response = await client
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 60));

          _log('[$type] Response status: ${response.statusCode}');
          _log('[$type] Content-Type: ${response.headers['content-type']}');
          _log(
              '[$type] Content-Length: ${response.contentLength ?? response.bodyBytes.length} bytes');

          // Check if it's an HTML response (error or redirect page)
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('text/html')) {
            _log('[$type] Got HTML response, checking for confirmation...');

            // Check if it's a virus scan warning page
            final body = response.body;
            if (body.contains('confirm=') ||
                body.contains('virus scan') ||
                body.contains('Google Drive')) {
              _log(
                  '[$type] Detected redirect/warning page, trying next URL...');
              continue;
            }

            // Check for other errors
            if (body.contains('error') ||
                body.contains('Error') ||
                body.contains('not found')) {
              _log('[$type] HTML contains error message');
              continue;
            }
          }

          // Valid response with actual file content
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final bytes = response.bodyBytes;

            // Validate based on type
            bool isValid = false;
            if (type == 'pdf') {
              isValid = _isValidPdfFile(bytes);
            } else if (type == 'excel') {
              isValid = _isValidExcelFile(bytes);
            }

            if (isValid) {
              _log('[$type] Valid file downloaded: ${bytes.length} bytes');
              return bytes;
            } else {
              _log('[$type] Downloaded content is not a valid $type file');
            }
          }
        } on TimeoutException {
          _log('[$type] Timeout on URL ${i + 1}');
        } catch (e) {
          _log('[$type] Error on URL ${i + 1}: $e');
        }
      }

      _log('[$type] All download attempts failed');
      return null;
    } finally {
      client.close();
    }
  }

  /// Check if bytes represent a valid Excel file
  bool _isValidExcelFile(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // XLSX files are ZIP archives (start with PK)
    // Magic bytes: 50 4B 03 04
    if (bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      _log('[Excel] Detected XLSX format (ZIP archive)');
      return true;
    }

    // XLS files (old format) start with D0 CF 11 E0
    if (bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      _log('[Excel] Detected XLS format (OLE compound)');
      return true;
    }

    _log(
        '[Excel] Unknown file format. First 4 bytes: ${bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    return false;
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  @override
  void dispose() {
    _endTracking();
    _pdfController.dispose();
    _searchController.dispose();
    _searchResult?.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearchOpen && _contentType == ContentType.pdf
          ? _buildSearchField()
          : Text(
              widget.module.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: _buildAppBarActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Cari dalam dokumen...',
        hintStyle: TextStyle(color: AppTheme.textLight),
        border: InputBorder.none,
        suffixIcon: _searchResult != null && _searchResult!.hasResult
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_searchResult!.currentInstanceIndex}/${_searchResult!.totalInstanceCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.arrow_up_2, size: 20),
                    onPressed: () => _searchResult?.previousInstance(),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.arrow_down_1, size: 20),
                    onPressed: () => _searchResult?.nextInstance(),
                  ),
                ],
              )
            : null,
      ),
      onSubmitted: _performSearch,
      onChanged: (value) {
        if (value.isEmpty) {
          _searchResult?.clear();
          setState(() {});
        }
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_contentType == ContentType.pdf) {
      return [
        if (!_isSearchOpen)
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () => setState(() => _isSearchOpen = true),
            tooltip: 'Cari',
          ),
        if (_isSearchOpen)
          IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: _closeSearch,
            tooltip: 'Tutup pencarian',
          ),
        IconButton(
          icon: const Icon(Iconsax.book_1),
          onPressed: () => _pdfViewerKey.currentState?.openBookmarkView(),
          tooltip: 'Bookmark',
        ),
      ];
    }
    return [];
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      _searchResult = _pdfController.searchText(query);
      _searchResult?.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _closeSearch() {
    _searchController.clear();
    _searchResult?.clear();
    setState(() => _isSearchOpen = false);
  }

  Widget _buildBody() {
    switch (_contentType) {
      case ContentType.pdf:
        return _buildPdfViewer();
      case ContentType.excel:
        return _buildExcelViewer();
    }
  }

  // ==================== PDF VIEWER ====================
  Widget _buildPdfViewer() {
    // Show loading state
    if (_isLoadingPdf) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _pdfLoadingStatus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File: ${widget.module.gdriveFileId}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_pdfError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _pdfError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'FileID: ${widget.module.gdriveFileId}',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _clearCache('pdf');
                      _loadPdfFile();
                    },
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Clear Cache & Retry'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loadPdfFile,
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No PDF data
    if (_pdfBytes == null) {
      return const Center(child: Text('Tidak ada data PDF'));
    }

    // Show PDF viewer from memory
    return Column(
      children: [
        // Progress indicator
        if (_totalPages > 0)
          LinearProgressIndicator(
            value: _currentPage / _totalPages,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 3,
          ),

        // PDF Viewer from memory
        Expanded(
          child: SfPdfViewer.memory(
            _pdfBytes!,
            key: _pdfViewerKey,
            controller: _pdfController,
            enableTextSelection: true,
            enableDoubleTapZooming: true,
            onDocumentLoaded: (details) {
              _log(
                  '[PDF] Document loaded. Pages: ${details.document.pages.count}');
              setState(() {
                _totalPages = details.document.pages.count;
                _viewedPages.add(1);
              });
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
                _viewedPages.add(details.newPageNumber);
              });
            },
            onDocumentLoadFailed: (details) {
              _log('[PDF] Document load failed: ${details.error}');
              _showErrorSnackBar('Gagal memuat PDF: ${details.error}');
            },
          ),
        ),

        // Page navigation
        _buildPdfPageIndicator(),
      ],
    );
  }

  Widget _buildPdfPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            IconButton(
              onPressed:
                  _currentPage > 1 ? () => _pdfController.previousPage() : null,
              icon: const Icon(Iconsax.arrow_left_2),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage > 1
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),

            // Page indicator with jump to page
            GestureDetector(
              onTap: () => _showGoToPageDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halaman $_currentPage dari $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Iconsax.edit_2,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Next & more options
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfController.nextPage()
                      : null,
                  icon: const Icon(Iconsax.arrow_right_3),
                  style: IconButton.styleFrom(
                    backgroundColor: _currentPage < _totalPages
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Iconsax.more, size: 20),
                  onSelected: (value) async {
                    if (value == 'clear_cache') {
                      await _clearCache('pdf');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache PDF dibersihkan'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (value == 'reload') {
                      await _clearCache('pdf');
                      _loadPdfFile();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_cache',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 18),
                          SizedBox(width: 8),
                          Text('Bersihkan Cache'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reload',
                      child: Row(
                        children: [
                          Icon(Iconsax.refresh, size: 18),
                          SizedBox(width: 8),
                          Text('Muat Ulang'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pergi ke Halaman'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Halaman tidak valid');
              }
            },
            child: const Text('Pergi'),
          ),
        ],
      ),
    );
  }

  // ==================== EXCEL VIEWER ====================
  Widget _buildExcelViewer() {
    if (_isLoadingExcel) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _loadingStatus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File: ${widget.module.gdriveFileId}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_excelError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _excelError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'FileID: ${widget.module.gdriveFileId}',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _clearCache('excel');
                      _loadExcelFile();
                    },
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Clear Cache & Retry'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loadExcelFile,
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_excelData == null || _sheetNames.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    return Column(
      children: [
        // Sheet selector & cache info
        _buildExcelHeader(),

        // Excel data table
        Expanded(child: _buildExcelTable()),
      ],
    );
  }

  Widget _buildExcelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Sheet selector
          if (_sheetNames.length > 1)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sheetNames.map((sheet) {
                    final isSelected = sheet == _selectedSheet;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sheet),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSheet = sheet);
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                _selectedSheet,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

          // Clear cache button
          IconButton(
            onPressed: () async {
              await _clearCache('excel');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache dibersihkan'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Iconsax.trash, size: 20),
            tooltip: 'Clear Cache',
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelTable() {
    final sheet = _excelData!.tables[_selectedSheet];
    if (sheet == null || sheet.rows.isEmpty) {
      return const Center(child: Text('Sheet kosong'));
    }

    final rows = sheet.rows;
    final maxCols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppTheme.primaryColor.withOpacity(0.1),
          ),
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columns: List.generate(
            maxCols,
            (index) => DataColumn(
              label: Text(
                _getColumnHeader(index, rows.isNotEmpty ? rows[0] : []),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          rows: rows.skip(1).map((row) {
            return DataRow(
              cells: List.generate(
                maxCols,
                (index) => DataCell(
                  Text(
                    index < row.length ? _getCellValue(row[index]) : '',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getColumnHeader(int index, List<Data?> firstRow) {
    if (index < firstRow.length && firstRow[index] != null) {
      final value = firstRow[index]!.value;
      if (value != null) return value.toString();
    }
    // Default to Excel-style column names (A, B, C, ...)
    return String.fromCharCode(65 + (index % 26));
  }

  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum ContentType { pdf, excel }
