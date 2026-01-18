import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/error_code_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class ErrorCodesScreen extends StatefulWidget {
  final bool embedded;
  const ErrorCodesScreen({super.key, this.embedded = false});

  @override
  State<ErrorCodesScreen> createState() => _ErrorCodesScreenState();
}

class _ErrorCodesScreenState extends State<ErrorCodesScreen> {
  List<ErrorCodeModel> _errorCodes = [];
  List<ErrorCodeModel> _filteredErrorCodes = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadErrorCodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadErrorCodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getErrorCodes();
      setState(() {
        _errorCodes = data.map((e) => ErrorCodeModel.fromJson(e)).toList();
        _filteredErrorCodes = _errorCodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat error codes: $e';
        _isLoading = false;
      });
    }
  }

  void _filterErrorCodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredErrorCodes = _errorCodes;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredErrorCodes = _errorCodes.where((code) {
          return code.code.toLowerCase().contains(lowerQuery) ||
              code.title.toLowerCase().contains(lowerQuery) ||
              code.cause.toLowerCase().contains(lowerQuery) ||
              code.solution.toLowerCase().contains(lowerQuery) ||
              (code.symptom?.toLowerCase().contains(lowerQuery) ?? false) ||
              (code.errorIdentification?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (code.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
              (code.serialNumber?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (code.category?.toLowerCase().contains(lowerQuery) ?? false) ||
              (code.machineType?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });

    // Log search
    if (query.isNotEmpty) {
      ActivityLogService().logSearch(
          query: query,
          resultsCount: _filteredErrorCodes.length,
          screenName: 'error_codes_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded ? null : AppBar(title: const Text('Error Codes')),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.errorCodeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.warning_2,
                color: AppTheme.errorCodeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error Codes',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${_errorCodes.length} kode error tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadErrorCodes),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _filterErrorCodes,
            decoration: InputDecoration(
              hintText: 'Cari kode, gejala, penyebab...',
              prefixIcon:
                  const Icon(Iconsax.search_normal, color: AppTheme.textLight),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle,
                          color: AppTheme.textLight),
                      onPressed: () {
                        _searchController.clear();
                        _filterErrorCodes('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ditemukan ${_filteredErrorCodes.length} dari ${_errorCodes.length} error code',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadErrorCodes);
    if (_errorCodes.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.warning_2,
          title: 'Belum Ada Error Code',
          subtitle: 'Daftar error code akan muncul di sini');
    if (_filteredErrorCodes.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.search_normal,
          title: 'Tidak Ditemukan',
          subtitle: 'Coba kata kunci lain');

    return RefreshIndicator(
      onRefresh: _loadErrorCodes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredErrorCodes.length,
        itemBuilder: (context, index) {
          final errorCode = _filteredErrorCodes[index];
          return _ErrorCodeCard(
              errorCode: errorCode, onTap: () => _openErrorCode(errorCode));
        },
      ),
    );
  }

  void _openErrorCode(ErrorCodeModel errorCode) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_error_code_${errorCode.id}',
        screenName: 'error_codes_screen');
    Navigator.pushNamed(context, AppRoutes.errorCodeDetail,
        arguments: errorCode);
  }
}

class _ErrorCodeCard extends StatelessWidget {
  final ErrorCodeModel errorCode;
  final VoidCallback onTap;
  const _ErrorCodeCard({required this.errorCode, required this.onTap});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Error code badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.getSeverityColor(errorCode.severity)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorCode.code,
                        style: TextStyle(
                          color: AppTheme.getSeverityColor(errorCode.severity),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeverityBadge(severity: errorCode.severity),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppTheme.textLight),
                  ],
                ),
                const SizedBox(height: 12),
                Text(errorCode.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Show symptom if available, otherwise show cause
                Text(
                  errorCode.symptom ?? errorCode.cause,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (errorCode.machineType != null ||
                    errorCode.category != null ||
                    errorCode.serialNumber != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (errorCode.machineType != null)
                        _buildTag(Iconsax.cpu, errorCode.machineType!),
                      if (errorCode.serialNumber != null)
                        _buildTag(Iconsax.barcode, errorCode.serialNumber!),
                      if (errorCode.category != null)
                        _buildTag(Iconsax.category, errorCode.category!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textLight),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
