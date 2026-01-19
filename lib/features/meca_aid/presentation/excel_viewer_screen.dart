import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart'
    hide Border; // Hide Border to avoid conflict with Flutter
import '../../../config/theme.dart';
import '../../../shared/models/module_model.dart';

/// ============================================================
/// EXCEL VIEWER SCREEN
/// Menampilkan file Excel langsung di dalam aplikasi
/// ============================================================
class ExcelViewerScreen extends StatefulWidget {
  final ModuleModel module;
  const ExcelViewerScreen({super.key, required this.module});

  @override
  State<ExcelViewerScreen> createState() => _ExcelViewerScreenState();
}

class _ExcelViewerScreenState extends State<ExcelViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  // Excel data
  Excel? _excel;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  List<List<dynamic>> _currentSheetData = [];

  // Tab controller for sheets
  TabController? _tabController;

  // Scroll controllers
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  String get _gdriveViewUrl =>
      'https://docs.google.com/spreadsheets/d/${widget.module.gdriveFileId}/preview';

  String get _gdriveDownloadUrl =>
      'https://drive.google.com/uc?export=download&id=${widget.module.gdriveFileId}';

  String get _fileExtension {
    if (widget.module.fileType == 'xlsx') return '.xlsx';
    if (widget.module.fileType == 'xls') return '.xls';
    return '.xlsx';
  }

  @override
  void initState() {
    super.initState();
    _loadExcelFile();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExcelFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check cache first
      final cacheDir = await _getCacheDir();
      final cacheFile =
          File('${cacheDir.path}/excel_${widget.module.id}$_fileExtension');

      Uint8List bytes;

      if (await cacheFile.exists()) {
        // Load from cache
        debugPrint('📁 Loading Excel from cache');
        bytes = await cacheFile.readAsBytes();
      } else {
        // Download from Google Drive
        debugPrint('⬇️ Downloading Excel file...');
        setState(() => _isDownloading = true);

        final response = await http.get(Uri.parse(_gdriveDownloadUrl));

        if (response.statusCode == 200) {
          bytes = response.bodyBytes;

          // Save to cache
          await cacheFile.writeAsBytes(bytes);
          debugPrint('✅ Excel cached');
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }

        setState(() => _isDownloading = false);
      }

      // Parse Excel
      _excel = Excel.decodeBytes(bytes);

      if (_excel != null) {
        _sheetNames = _excel!.tables.keys.toList();

        if (_sheetNames.isNotEmpty) {
          _selectedSheet = _sheetNames.first;
          _loadSheetData(_selectedSheet!);

          // Initialize tab controller
          _tabController = TabController(
            length: _sheetNames.length,
            vsync: this,
          );
          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              _onSheetChanged(_sheetNames[_tabController!.index]);
            }
          });
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Excel load error: $e');
      setState(() {
        _error = 'Gagal memuat file: $e';
        _isLoading = false;
        _isDownloading = false;
      });
    }
  }

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/excel_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  void _loadSheetData(String sheetName) {
    if (_excel == null) return;

    final sheet = _excel!.tables[sheetName];
    if (sheet != null) {
      _currentSheetData = sheet.rows;
    }
  }

  void _onSheetChanged(String sheetName) {
    setState(() {
      _selectedSheet = sheetName;
      _loadSheetData(sheetName);
    });
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
      title: Text(
        widget.module.title,
        style: const TextStyle(fontSize: 16),
      ),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Refresh
        IconButton(
          icon: const Icon(Iconsax.refresh),
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadExcelFile,
        ),
        // Open in Browser
        IconButton(
          icon: const Icon(Iconsax.export_1),
          tooltip: 'Buka di Google Sheets',
          onPressed: _openInBrowser,
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.more),
          onSelected: (value) {
            if (value == 'download') {
              _downloadToDevice();
            } else if (value == 'clear_cache') {
              _clearCache();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Iconsax.document_download, size: 20),
                  SizedBox(width: 12),
                  Text('Download ke Perangkat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(Iconsax.trash, size: 20),
                  SizedBox(width: 12),
                  Text('Hapus Cache'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _sheetNames.length > 1 && _tabController != null
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: _sheetNames.map((name) => Tab(text: name)).toList(),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_excel == null || _currentSheetData.isEmpty) {
      return _buildEmptyState();
    }

    return _buildExcelViewer();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF217346).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF217346)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isDownloading ? 'Mengunduh file...' : 'Memuat spreadsheet...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.module.title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat File',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadExcelFile,
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Iconsax.export_1),
                  label: const Text('Buka di Browser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217346),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'File kosong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada data dalam spreadsheet ini',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelViewer() {
    return Column(
      children: [
        // Info bar
        _buildInfoBar(),

        // Excel table
        Expanded(
          child: _buildDataTable(),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    final rowCount = _currentSheetData.length;
    final colCount = _getColumnCount();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // File type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF217346).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.document_text,
                    size: 14, color: Color(0xFF217346)),
                const SizedBox(width: 4),
                Text(
                  widget.module.fileType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF217346),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Row & column count
          Text(
            '$rowCount baris × $colCount kolom',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),

          const Spacer(),

          // Sheet name (if single sheet)
          if (_sheetNames.length == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedSheet ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getColumnCount() {
    if (_currentSheetData.isEmpty) return 0;
    int maxCols = 0;
    for (final row in _currentSheetData) {
      if (row.length > maxCols) maxCols = row.length;
    }
    return maxCols;
  }

  Widget _buildDataTable() {
    if (_currentSheetData.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: _buildTable(),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final columnCount = _getColumnCount();

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFF217346).withOpacity(0.1),
      ),
      dataRowMinHeight: 40,
      dataRowMaxHeight: 60,
      horizontalMargin: 12,
      columnSpacing: 16,
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      columns: _buildColumns(columnCount),
      rows: _buildRows(columnCount),
    );
  }

  List<DataColumn> _buildColumns(int columnCount) {
    // Use first row as header if it looks like headers
    final firstRow =
        _currentSheetData.isNotEmpty ? _currentSheetData.first : [];
    final hasHeaders = _looksLikeHeaders(firstRow);

    if (hasHeaders && firstRow.isNotEmpty) {
      return List.generate(columnCount, (index) {
        final cell = index < firstRow.length ? firstRow[index] : null;
        final value = _getCellValue(cell);
        return DataColumn(
          label: Text(
            value.isNotEmpty ? value : _getColumnLetter(index),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      });
    }

    // Generate A, B, C... headers
    return List.generate(columnCount, (index) {
      return DataColumn(
        label: Text(
          _getColumnLetter(index),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    });
  }

  List<DataRow> _buildRows(int columnCount) {
    final firstRow =
        _currentSheetData.isNotEmpty ? _currentSheetData.first : [];
    final hasHeaders = _looksLikeHeaders(firstRow);
    final startIndex = hasHeaders ? 1 : 0;

    return List.generate(
      _currentSheetData.length - startIndex,
      (rowIndex) {
        final actualRowIndex = rowIndex + startIndex;
        final row = _currentSheetData[actualRowIndex];

        return DataRow(
          color: WidgetStateProperty.resolveWith((states) {
            if (rowIndex.isEven) {
              return Colors.grey.shade50;
            }
            return Colors.white;
          }),
          cells: List.generate(columnCount, (colIndex) {
            final cell = colIndex < row.length ? row[colIndex] : null;
            final value = _getCellValue(cell);

            return DataCell(
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  minWidth: 60,
                ),
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              onTap: value.length > 30 ? () => _showCellDetail(value) : null,
            );
          }),
        );
      },
    );
  }

  bool _looksLikeHeaders(List<dynamic> row) {
    if (row.isEmpty) return false;

    // Check if most cells in first row are text (likely headers)
    int textCount = 0;
    int nonEmptyCount = 0;

    for (final cell in row) {
      if (cell != null) {
        nonEmptyCount++;
        final value = _getCellValue(cell);
        // If it's text and not a number, count it
        if (value.isNotEmpty && double.tryParse(value) == null) {
          textCount++;
        }
      }
    }

    // If most non-empty cells are text, probably headers
    return nonEmptyCount > 0 && textCount / nonEmptyCount > 0.5;
  }

  String _getCellValue(dynamic cell) {
    if (cell == null) return '';

    // Handle Data type from excel package
    if (cell is Data) {
      final value = cell.value;
      if (value == null) return '';
      return _formatCellValue(value);
    }

    // Direct value
    return _formatCellValue(cell);
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '';

    // Handle CellValue types from excel package
    if (value is TextCellValue) {
      return value.value.toString();
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }
    if (value is DoubleCellValue) {
      final num = value.value;
      if (num == num.truncateToDouble()) {
        return num.toInt().toString();
      }
      return num.toStringAsFixed(2);
    }
    if (value is BoolCellValue) {
      return value.value ? 'TRUE' : 'FALSE';
    }
    if (value is DateCellValue) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    if (value is TimeCellValue) {
      return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }
    if (value is DateTimeCellValue) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }
    if (value is FormulaCellValue) {
      return value.formula;
    }

    // Fallback for other types
    if (value is double) {
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    if (value is int) {
      return value.toString();
    }

    return value.toString();
  }

  String _getColumnLetter(int index) {
    String result = '';
    int n = index;
    while (n >= 0) {
      result = String.fromCharCode(65 + (n % 26)) + result;
      n = (n ~/ 26) - 1;
    }
    return result;
  }

  void _showCellDetail(String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Sel'),
        content: SingleChildScrollView(
          child: SelectableText(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse(_gdriveViewUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Tidak dapat membuka browser', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _downloadToDevice() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${widget.module.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}$_fileExtension';
      final downloadDir = Directory('${dir.path}/Downloads');

      // Ensure directory exists
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final file = File('${downloadDir.path}/$fileName');

      // Download
      final response = await http.get(Uri.parse(_gdriveDownloadUrl));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _showSnackBar('File disimpan: ${file.path}');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Gagal download: $e', isError: true);
    }
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await _getCacheDir();
      final cacheFile =
          File('${cacheDir.path}/excel_${widget.module.id}$_fileExtension');

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        _showSnackBar('Cache berhasil dihapus');

        // Reload file
        _loadExcelFile();
      } else {
        _showSnackBar('Tidak ada cache untuk dihapus');
      }
    } catch (e) {
      _showSnackBar('Gagal menghapus cache: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

/// ============================================================
/// SERVICE UNTUK CACHE EXCEL
/// ============================================================
class ExcelCacheService {
  static Future<void> clearAllCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/excel_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('🗑️ Excel cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing Excel cache: $e');
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/excel_cache');
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
      debugPrint('Error getting Excel cache size: $e');
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
