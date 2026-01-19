import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/quiz_model.dart';
import '../../../shared/widgets/common_widgets.dart';

/// ============================================================
/// QUIZ DETAIL SCREEN
/// Menampilkan detail quiz, riwayat attempt, dan tombol mulai
/// ============================================================
class QuizDetailScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  List<QuestionModel> _questions = [];
  List<QuizAttemptSummary> _attempts = [];
  bool _isLoading = true;
  bool _isLoadingAttempts = true;
  String? _error;
  int _currentAttemptNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadQuestions(),
      _loadAttemptHistory(),
    ]);
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getQuestionsByQuizId(widget.quiz.id);
      setState(() {
        _questions = data.map((e) => QuestionModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat soal: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttemptHistory() async {
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _isLoadingAttempts = false);
      return;
    }

    setState(() => _isLoadingAttempts = true);
    try {
      final data = await SupabaseService.getQuizAttemptSummary(
        userId: user.id,
        quizId: widget.quiz.id,
      );

      // Get latest attempt number
      final latestAttempt = await SupabaseService.getLatestAttemptNumber(
        userId: user.id,
        quizId: widget.quiz.id,
      );

      setState(() {
        _attempts = data.map((e) => QuizAttemptSummary.fromJson(e)).toList();
        _currentAttemptNumber = latestAttempt;
        _isLoadingAttempts = false;
      });
    } catch (e) {
      debugPrint('Error loading attempts: $e');
      setState(() => _isLoadingAttempts = false);
    }
  }

  Color get _typeColor {
    switch (widget.quiz.quizType) {
      case 'certification':
        return const Color(0xFF9C27B0);
      case 'practice_test':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.mecaAidColor;
    }
  }

  IconData get _typeIcon {
    switch (widget.quiz.quizType) {
      case 'certification':
        return Iconsax.award;
      case 'practice_test':
        return Iconsax.book_1;
      default:
        return Iconsax.task_square;
    }
  }

  String get _typeLabel {
    switch (widget.quiz.quizType) {
      case 'certification':
        return 'Sertifikasi';
      case 'practice_test':
        return 'Latihan Soal';
      default:
        return 'Quiz';
    }
  }

  /// Get best score from attempts
  int? get _bestScore {
    if (_attempts.isEmpty) return null;
    return _attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
  }

  /// Get last attempt
  QuizAttemptSummary? get _lastAttempt {
    if (_attempts.isEmpty) return null;
    return _attempts.first; // Already sorted by newest first
  }

  /// Check if user can attempt again
  bool get _canAttempt {
    if (widget.quiz.maxAttempts == null) return true;
    return _currentAttemptNumber < widget.quiz.maxAttempts!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_typeLabel),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _loadData)
              : _buildContent(),
      bottomNavigationBar:
          _isLoading || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Last Attempt & Best Score Card
            if (_attempts.isNotEmpty) ...[
              _buildScoreOverviewCard(),
              const SizedBox(height: 24),
            ],

            // Info Cards
            _buildInfoSection(),
            const SizedBox(height: 24),

            // Question Types Summary
            _buildQuestionTypesSummary(),
            const SizedBox(height: 24),

            // Attempt History
            if (_attempts.isNotEmpty) ...[
              _buildAttemptHistory(),
              const SizedBox(height: 24),
            ],

            // Rules
            _buildRulesSection(),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor, _typeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _typeColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            widget.quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.quiz.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.quiz.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_currentAttemptNumber > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Attempt ke-${_currentAttemptNumber + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreOverviewCard() {
    final lastAttempt = _lastAttempt;
    final bestScore = _bestScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart, color: _typeColor),
              const SizedBox(width: 8),
              Text(
                'Statistik Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Last Score
              Expanded(
                child: _buildScoreItem(
                  label: 'Nilai Terakhir',
                  score: lastAttempt?.score ?? 0,
                  isPassed: lastAttempt?.isPassed ?? false,
                  subtitle: lastAttempt?.formattedDate ?? '-',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey.shade200,
              ),
              // Best Score
              Expanded(
                child: _buildScoreItem(
                  label: 'Nilai Terbaik',
                  score: bestScore ?? 0,
                  isPassed: (bestScore ?? 0) >= widget.quiz.passingScore,
                  subtitle: '${_attempts.length}x percobaan',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem({
    required String label,
    required int score,
    required bool isPassed,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score%',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isPassed ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isPassed ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isPassed ? 'LULUS' : 'BELUM LULUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPassed ? Colors.green : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Quiz',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Iconsax.document,
                label: 'Jumlah Soal',
                value: '${_questions.length}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Iconsax.clock,
                label: 'Waktu',
                value: widget.quiz.timeLimitMinutes != null
                    ? '${widget.quiz.timeLimitMinutes} menit'
                    : 'Tidak terbatas',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Iconsax.chart,
                label: 'Nilai Lulus',
                value: '${widget.quiz.passingScore}%',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Iconsax.medal_star,
                label: 'Total Poin',
                value: '${_questions.fold<int>(0, (sum, q) => sum + q.points)}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        if (widget.quiz.maxAttempts != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Iconsax.repeat,
                  label: 'Sisa Percobaan',
                  value:
                      '${widget.quiz.maxAttempts! - _currentAttemptNumber}/${widget.quiz.maxAttempts}',
                  color: _canAttempt ? Colors.teal : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypesSummary() {
    final multipleChoice = _questions.where((q) => q.isMultipleChoice).length;
    final trueFalse = _questions.where((q) => q.isTrueFalse).length;
    final essay = _questions.where((q) => q.isEssay).length;

    if (multipleChoice == _questions.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.category, color: _typeColor),
              const SizedBox(width: 8),
              Text(
                'Tipe Soal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (multipleChoice > 0)
            _buildQuestionTypeItem(
              icon: Iconsax.task_square,
              label: 'Pilihan Ganda',
              count: multipleChoice,
              color: Colors.blue,
            ),
          if (trueFalse > 0)
            _buildQuestionTypeItem(
              icon: Iconsax.toggle_on_circle,
              label: 'Benar/Salah',
              count: trueFalse,
              color: Colors.orange,
            ),
          if (essay > 0)
            _buildQuestionTypeItem(
              icon: Iconsax.edit_2,
              label: 'Uraian',
              count: essay,
              color: Colors.purple,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count soal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.timer_1, color: _typeColor),
              const SizedBox(width: 8),
              Text(
                'Riwayat Percobaan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingAttempts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._attempts.take(5).map((attempt) => _buildAttemptItem(attempt)),
          if (_attempts.length > 5)
            TextButton(
              onPressed: () => _showAllAttempts(),
              child: Text(
                'Lihat semua (${_attempts.length})',
                style: TextStyle(color: _typeColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttemptItem(QuizAttemptSummary attempt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: attempt.isPassed
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: attempt.isPassed
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: attempt.isPassed
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${attempt.attemptNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: attempt.isPassed ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skor: ${attempt.score}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: attempt.isPassed ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  '${attempt.correctCount}/${attempt.totalQuestions} benar • ${attempt.formattedTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: attempt.isPassed ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attempt.isPassed ? 'LULUS' : 'GAGAL',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                attempt.formattedDate,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllAttempts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Semua Percobaan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _attempts.length,
                  itemBuilder: (context, index) {
                    return _buildAttemptItem(_attempts[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: _typeColor),
              const SizedBox(width: 8),
              Text(
                'Peraturan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem('Jawab semua pertanyaan dengan teliti'),
          _buildRuleItem(widget.quiz.shuffleQuestions
              ? 'Urutan soal akan diacak'
              : 'Soal ditampilkan secara berurutan'),
          _buildRuleItem(widget.quiz.shuffleOptions
              ? 'Pilihan jawaban akan diacak'
              : 'Pilihan jawaban tidak diacak'),
          if (widget.quiz.timeLimitMinutes != null)
            _buildRuleItem(
                'Waktu pengerjaan ${widget.quiz.timeLimitMinutes} menit'),
          _buildRuleItem(
              'Nilai minimum kelulusan ${widget.quiz.passingScore}%'),
          if (widget.quiz.showCorrectAnswers)
            _buildRuleItem('Jawaban benar akan ditampilkan setelah selesai'),
          if (widget.quiz.maxAttempts != null)
            _buildRuleItem('Maksimal ${widget.quiz.maxAttempts}x percobaan'),
          if (_questions.any((q) => q.isEssay))
            _buildRuleItem('Soal uraian akan diperiksa berdasarkan kata kunci'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _typeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_canAttempt)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Iconsax.warning_2, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anda telah mencapai batas maksimal percobaan',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: _questions.isEmpty || !_canAttempt ? null : _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: _typeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _questions.isEmpty
                        ? Iconsax.close_circle
                        : !_canAttempt
                            ? Iconsax.lock
                            : Iconsax.play,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _questions.isEmpty
                        ? 'Tidak ada soal'
                        : !_canAttempt
                            ? 'Batas Percobaan Tercapai'
                            : _currentAttemptNumber > 0
                                ? 'Mulai Percobaan ke-${_currentAttemptNumber + 1}'
                                : 'Mulai $_typeLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz() {
    ActivityLogService().logButtonClick(
        buttonId: 'start_quiz_${widget.quiz.id}',
        screenName: 'quiz_detail_screen');

    // Shuffle questions jika enabled
    List<QuestionModel> questionsToUse = List.from(_questions);
    if (widget.quiz.shuffleQuestions) {
      questionsToUse.shuffle();
    }

    Navigator.pushNamed(
      context,
      AppRoutes.quizPlay,
      arguments: {
        'quiz': widget.quiz,
        'questions': questionsToUse,
        'attemptNumber': _currentAttemptNumber + 1,
      },
    );
  }
}
