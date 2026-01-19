import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/models/meca_aid_folder_model.dart';
import '../../../shared/models/quiz_model.dart';
import '../../../shared/widgets/common_widgets.dart';

/// ============================================================
/// MECA AID SCREEN - DENGAN 3 FOLDER UTAMA
/// 1. Meca Aid (dari meca_aid_folders)
/// 2. Meca Sheet (dari modules category: meca_sheet)
/// 3. Quiz/Sertifikasi (dari quizzes)
/// ============================================================
class MecaAidScreen extends StatefulWidget {
  final bool embedded;
  const MecaAidScreen({super.key, this.embedded = false});

  @override
  State<MecaAidScreen> createState() => _MecaAidScreenState();
}

class _MecaAidScreenState extends State<MecaAidScreen> {
  // Counts untuk badge
  int _mecaAidFolderCount = 0;
  int _mecaSheetCount = 0;
  int _quizCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      // Load counts dari berbagai sumber
      final mecaAidFolders = await SupabaseService.getMecaAidFolders();
      final mecaSheets =
          await SupabaseService.getModules(category: 'meca_sheet');
      final quizzes = await SupabaseService.getQuizzes();

      setState(() {
        _mecaAidFolderCount = mecaAidFolders.length;
        _mecaSheetCount = mecaSheets.length;
        _quizCount = quizzes.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading counts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded ? null : AppBar(title: const Text('Meca Aid')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _buildHeader(),
            Expanded(child: _buildFolderContent()),
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
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.task_square,
                color: AppTheme.mecaAidColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meca Aid', style: Theme.of(context).textTheme.titleLarge),
                const Text('Pilih kategori materi',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadCounts,
          ),
        ],
      ),
    );
  }

  Widget _buildFolderContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadCounts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // =============================================
            // FOLDER 1: MECA AID
            // =============================================
            _FolderCard(
              icon: Iconsax.folder_open,
              title: 'Meca Aid',
              subtitle: 'Materi dan panduan Meca Aid',
              color: AppTheme.mecaAidColor,
              itemCount: _mecaAidFolderCount,
              onTap: () {
                ActivityLogService().logButtonClick(
                    buttonId: 'open_meca_aid_folder',
                    screenName: 'meca_aid_screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MecaAidFolderListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // =============================================
            // FOLDER 2: MECA SHEET
            // =============================================
            _FolderCard(
              icon: Iconsax.document_text,
              title: 'Meca Sheet',
              subtitle: 'Lembar kerja dan data teknis',
              color: const Color(0xFF2196F3), // Blue
              itemCount: _mecaSheetCount,
              onTap: () {
                ActivityLogService().logButtonClick(
                    buttonId: 'open_meca_sheet_folder',
                    screenName: 'meca_aid_screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MecaSheetListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // =============================================
            // FOLDER 3: QUIZ / SERTIFIKASI
            // =============================================
            _FolderCard(
              icon: Iconsax.award,
              title: 'Quiz / Sertifikasi',
              subtitle: 'Latihan soal dan ujian sertifikasi',
              color: const Color(0xFF9C27B0), // Purple
              itemCount: _quizCount,
              onTap: () {
                ActivityLogService().logButtonClick(
                    buttonId: 'open_quiz_sertifikasi_folder',
                    screenName: 'meca_aid_screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizSertifikasiListScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// FOLDER CARD WIDGET
/// ============================================================
class _FolderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int itemCount;
  final VoidCallback onTap;

  const _FolderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Folder Icon dengan inner icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Iconsax.folder_2, size: 40, color: color),
                      Positioned(
                        bottom: 12,
                        child: Icon(icon, size: 16, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Title, Subtitle & Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Item count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$itemCount item',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    size: 20,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// SCREEN 1: MECA AID FOLDER LIST
/// Menampilkan daftar folder dari tabel meca_aid_folders
/// ============================================================
class MecaAidFolderListScreen extends StatefulWidget {
  const MecaAidFolderListScreen({super.key});

  @override
  State<MecaAidFolderListScreen> createState() =>
      _MecaAidFolderListScreenState();
}

class _MecaAidFolderListScreenState extends State<MecaAidFolderListScreen> {
  List<MecaAidFolder> _folders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getMecaAidFolders();
      setState(() {
        _folders = data.map((e) => MecaAidFolder.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat folder: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meca Aid'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.folder_open,
                color: AppTheme.mecaAidColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Folder Meca Aid',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${_folders.length} folder tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadFolders),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadFolders);
    if (_folders.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.folder_open,
          title: 'Belum Ada Folder',
          subtitle: 'Folder Meca Aid akan muncul di sini');

    return RefreshIndicator(
      onRefresh: _loadFolders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          return _SubFolderCard(
            folder: folder,
            onTap: () => _openFolder(folder),
          );
        },
      ),
    );
  }

  void _openFolder(MecaAidFolder folder) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_meca_aid_folder_${folder.id}',
        screenName: 'meca_aid_folder_list');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MecaAidFolderContentScreen(folder: folder),
      ),
    );
  }
}

/// ============================================================
/// SUB FOLDER CARD
/// ============================================================
class _SubFolderCard extends StatelessWidget {
  final MecaAidFolder folder;
  final VoidCallback onTap;

  const _SubFolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.mecaAidColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.folder_2,
                      color: AppTheme.mecaAidColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.folderName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (folder.description != null &&
                          folder.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          folder.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3,
                    size: 18, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// SCREEN: MECA AID FOLDER CONTENT
/// Menampilkan isi folder (modules dengan parent_folder_id = folder.id)
/// parent_folder_id di modules = id (UUID) di meca_aid_folders
/// ============================================================
class MecaAidFolderContentScreen extends StatefulWidget {
  final MecaAidFolder folder;
  const MecaAidFolderContentScreen({super.key, required this.folder});

  @override
  State<MecaAidFolderContentScreen> createState() =>
      _MecaAidFolderContentScreenState();
}

class _MecaAidFolderContentScreenState
    extends State<MecaAidFolderContentScreen> {
  List<ModuleModel> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Get modules where parent_folder_id matches folder's id (UUID)
      final data = await SupabaseService.getModulesByFolder(widget.folder.id);
      setState(() {
        _items = data.map((e) => ModuleModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat konten: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.folder.folderName),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.folder_open,
                color: AppTheme.mecaAidColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.folder.folderName,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${_items.length} file tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadItems),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadItems);
    if (_items.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.document,
          title: 'Folder Kosong',
          subtitle: 'Belum ada file dalam folder ini');

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _FileItemCard(
            item: item,
            onTap: () => _openItem(item),
          );
        },
      ),
    );
  }

  void _openItem(ModuleModel item) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_meca_aid_item_${item.id}',
        screenName: 'meca_aid_folder_content');

    // Navigate based on file type
    if (item.isExcel) {
      Navigator.pushNamed(context, AppRoutes.excelViewer, arguments: item);
    } else if (item.isVideo) {
      Navigator.pushNamed(context, AppRoutes.animationPlayer, arguments: item);
    } else {
      Navigator.pushNamed(context, AppRoutes.mecaAidDetail, arguments: item);
    }
  }
}

/// ============================================================
/// SCREEN 2: MECA SHEET LIST
/// Menampilkan modules dengan category: meca_sheet
/// ============================================================
class MecaSheetListScreen extends StatefulWidget {
  const MecaSheetListScreen({super.key});

  @override
  State<MecaSheetListScreen> createState() => _MecaSheetListScreenState();
}

class _MecaSheetListScreenState extends State<MecaSheetListScreen> {
  List<ModuleModel> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getModules(category: 'meca_sheet');
      setState(() {
        _items = data.map((e) => ModuleModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat Meca Sheet: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meca Sheet'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.document_text,
                color: Color(0xFF2196F3), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meca Sheet',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${_items.length} sheet tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadItems),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadItems);
    if (_items.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.document_text,
          title: 'Belum Ada Meca Sheet',
          subtitle: 'Meca Sheet akan muncul di sini');

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _FileItemCard(
            item: item,
            color: const Color(0xFF2196F3),
            onTap: () => _openItem(item),
          );
        },
      ),
    );
  }

  void _openItem(ModuleModel item) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_meca_sheet_${item.id}', screenName: 'meca_sheet_list');
    // Buka sesuai file type
    if (item.isExcel) {
      Navigator.pushNamed(context, AppRoutes.excelViewer, arguments: item);
    } else {
      Navigator.pushNamed(context, AppRoutes.mecaAidDetail, arguments: item);
    }
  }
}

/// ============================================================
/// SCREEN 3: QUIZ / SERTIFIKASI LIST
/// Menampilkan quizzes dari tabel quizzes
/// ============================================================
class QuizSertifikasiListScreen extends StatefulWidget {
  const QuizSertifikasiListScreen({super.key});

  @override
  State<QuizSertifikasiListScreen> createState() =>
      _QuizSertifikasiListScreenState();
}

class _QuizSertifikasiListScreenState extends State<QuizSertifikasiListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuizModel> _allQuizzes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getQuizzes();
      setState(() {
        _allQuizzes = data.map((e) => QuizModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat quiz: $e';
        _isLoading = false;
      });
    }
  }

  List<QuizModel> get _quizList =>
      _allQuizzes.where((q) => q.quizType == 'quiz').toList();
  List<QuizModel> get _certificationList =>
      _allQuizzes.where((q) => q.quizType == 'certification').toList();
  List<QuizModel> get _practiceTestList =>
      _allQuizzes.where((q) => q.quizType == 'practice_test').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quiz / Sertifikasi'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Quiz (${_quizList.length})'),
            Tab(text: 'Sertifikasi (${_certificationList.length})'),
            Tab(text: 'Latihan (${_practiceTestList.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _loadQuizzes)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuizList(_quizList, 'quiz'),
                    _buildQuizList(_certificationList, 'certification'),
                    _buildQuizList(_practiceTestList, 'practice_test'),
                  ],
                ),
    );
  }

  Widget _buildQuizList(List<QuizModel> quizzes, String type) {
    if (quizzes.isEmpty) {
      return EmptyStateWidget(
        icon: type == 'certification' ? Iconsax.award : Iconsax.task_square,
        title: 'Belum Ada ${_getTypeLabel(type)}',
        subtitle: '${_getTypeLabel(type)} akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return _QuizCard(
            quiz: quiz,
            onTap: () => _openQuiz(quiz),
          );
        },
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'quiz':
        return 'Quiz';
      case 'certification':
        return 'Sertifikasi';
      case 'practice_test':
        return 'Latihan Soal';
      default:
        return type;
    }
  }

  void _openQuiz(QuizModel quiz) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_quiz_${quiz.id}', screenName: 'quiz_sertifikasi_list');
    Navigator.pushNamed(context, AppRoutes.quizDetail, arguments: quiz);
  }
}

/// ============================================================
/// QUIZ CARD WIDGET
/// ============================================================
class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;

  const _QuizCard({required this.quiz, required this.onTap});

  Color get _typeColor {
    switch (quiz.quizType) {
      case 'certification':
        return const Color(0xFF9C27B0);
      case 'practice_test':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.mecaAidColor;
    }
  }

  IconData get _typeIcon {
    switch (quiz.quizType) {
      case 'certification':
        return Iconsax.award;
      case 'practice_test':
        return Iconsax.book_1;
      default:
        return Iconsax.task_square;
    }
  }

  String get _typeLabel {
    switch (quiz.quizType) {
      case 'certification':
        return 'Sertifikasi';
      case 'practice_test':
        return 'Latihan';
      default:
        return 'Quiz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (quiz.description != null &&
                          quiz.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          quiz.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(_typeLabel, _typeColor),
                          const SizedBox(width: 8),
                          _buildInfoBadge(
                              Iconsax.document, '${quiz.totalQuestions} soal'),
                          if (quiz.timeLimitMinutes != null) ...[
                            const SizedBox(width: 8),
                            _buildInfoBadge(Iconsax.clock,
                                '${quiz.timeLimitMinutes} menit'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3,
                    size: 18, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// ============================================================
/// FILE ITEM CARD (untuk Meca Aid & Meca Sheet)
/// color parameter is optional - will auto-detect based on file type
/// ============================================================
class _FileItemCard extends StatelessWidget {
  final ModuleModel item;
  final Color? color; // Made optional
  final VoidCallback onTap;

  const _FileItemCard({
    required this.item,
    this.color, // Now optional
    required this.onTap,
  });

  IconData get _fileIcon {
    switch (item.fileType) {
      case 'pdf':
        return Iconsax.document_text;
      case 'xls':
      case 'xlsx':
        return Iconsax.document_1;
      case 'mp4':
        return Iconsax.play_circle;
      case 'image':
        return Iconsax.image;
      case 'swf':
        return Iconsax.video_play;
      default:
        return Iconsax.document;
    }
  }

  String get _fileTypeLabel {
    switch (item.fileType) {
      case 'pdf':
        return 'PDF';
      case 'xls':
      case 'xlsx':
        return 'Excel';
      case 'mp4':
        return 'Video';
      case 'image':
        return 'Gambar';
      case 'swf':
        return 'Animasi';
      default:
        return item.fileType.toUpperCase();
    }
  }

  /// Get color based on file type if not provided
  Color get _effectiveColor {
    if (color != null) return color!;
    switch (item.fileType) {
      case 'pdf':
        return const Color(0xFFE53935); // Red
      case 'xls':
      case 'xlsx':
        return const Color(0xFF43A047); // Green
      case 'mp4':
        return const Color(0xFF1E88E5); // Blue
      case 'image':
        return const Color(0xFF8E24AA); // Purple
      case 'swf':
        return const Color(0xFFFF9800); // Orange
      default:
        return AppTheme.mecaAidColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _effectiveColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_fileIcon, color: effectiveColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: effectiveColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _fileTypeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: effectiveColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3,
                    size: 18, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
