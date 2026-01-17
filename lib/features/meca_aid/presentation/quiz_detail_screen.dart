import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/quiz_model.dart';
import '../../../shared/widgets/common_widgets.dart';

/// ============================================================
/// QUIZ DETAIL SCREEN
/// Menampilkan detail quiz dan tombol mulai
/// ============================================================
class QuizDetailScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
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
              ? ErrorStateWidget(message: _error!, onRetry: _loadQuestions)
              : _buildContent(),
      bottomNavigationBar:
          _isLoading || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Info Cards
          _buildInfoSection(),
          const SizedBox(height: 24),

          // Rules
          _buildRulesSection(),
        ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ],
      ),
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
        child: ElevatedButton(
          onPressed: _questions.isEmpty ? null : _startQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: _typeColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.play, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _questions.isEmpty ? 'Tidak ada soal' : 'Mulai $_typeLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
      },
    );
  }
}
