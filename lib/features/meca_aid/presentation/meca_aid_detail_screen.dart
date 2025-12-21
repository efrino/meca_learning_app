// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/models/question_model.dart';

class MecaAidDetailScreen extends StatefulWidget {
  final ModuleModel module;
  const MecaAidDetailScreen({super.key, required this.module});

  @override
  State<MecaAidDetailScreen> createState() => _MecaAidDetailScreenState();
}

class _MecaAidDetailScreenState extends State<MecaAidDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PdfViewerController _pdfController = PdfViewerController();
  final _activityLogService = ActivityLogService();

  int _currentPage = 1;
  int _totalPages = 0;
  final Set<int> _viewedPages = {};
  int _questionCount = 0;
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startTracking();
    _loadQuestionCount();
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  Future<void> _loadQuestionCount() async {
    try {
      final questions =
          await SupabaseService.getQuestionsByModuleId(widget.module.id);
      setState(() {
        _questionCount = questions.length;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  @override
  void dispose() {
    _endTracking();
    _tabController.dispose();
    _pdfController.dispose();
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
      appBar: AppBar(
        title: Text(widget.module.title, style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            const Tab(
                text: 'Materi', icon: Icon(Iconsax.document_text, size: 20)),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.task_square, size: 20),
                  const SizedBox(width: 8),
                  Text('Quiz ($_questionCount)'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPdfTab(),
          _buildQuizTab(),
        ],
      ),
    );
  }

  Widget _buildPdfTab() {
    final pdfUrl =
        'https://drive.google.com/uc?export=download&id=${widget.module.gdriveFileId}';

    return Column(
      children: [
        if (_totalPages > 0)
          LinearProgressIndicator(
            value: _currentPage / _totalPages,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 3,
          ),
        Expanded(
          child: SfPdfViewer.network(
            pdfUrl,
            controller: _pdfController,
            onDocumentLoaded: (details) {
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
          ),
        ),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                _currentPage > 1 ? () => _pdfController.previousPage() : null,
            icon: const Icon(Iconsax.arrow_left_2, size: 20),
            iconSize: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Halaman $_currentPage dari $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.nextPage()
                : null,
            icon: const Icon(Iconsax.arrow_right_3, size: 20),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    if (_isLoadingQuestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questionCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.task_square, size: 80, color: AppTheme.textLight),
            const SizedBox(height: 16),
            const Text('Belum ada soal quiz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Soal quiz akan ditambahkan segera',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.task_square,
                  size: 60, color: AppTheme.mecaAidColor),
            ),
            const SizedBox(height: 24),
            const Text('Quiz Tersedia!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_questionCount soal siap dikerjakan',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Uji pemahaman Anda tentang materi ini',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startQuiz(),
                icon: const Icon(Iconsax.play),
                label: const Text('Mulai Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mecaAidColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz() {
    _activityLogService.logQuizStart(
        moduleId: widget.module.id, moduleTitle: widget.module.title);
    Navigator.pushNamed(context, AppRoutes.quiz, arguments: widget.module);
  }
}
