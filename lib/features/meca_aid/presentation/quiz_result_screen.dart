import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../shared/models/quiz_model.dart';

/// ============================================================
/// QUIZ RESULT SCREEN
/// Menampilkan hasil quiz
/// ============================================================
class QuizResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final Map<String, String>? answers;
  final List<QuestionModel>? questions;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    this.answers,
    this.questions,
  });

  bool get isPassed => score >= quiz.passingScore;

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

  String get _typeLabel {
    switch (quiz.quizType) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Result Icon
              _buildResultIcon(),
              const SizedBox(height: 24),

              // Result Text
              _buildResultText(),
              const SizedBox(height: 32),

              // Score Card
              _buildScoreCard(),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 32),

              // Review Button (jika showCorrectAnswers)
              if (quiz.showCorrectAnswers &&
                  questions != null &&
                  answers != null)
                _buildReviewButton(context),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isPassed
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isPassed ? Iconsax.medal_star : Iconsax.close_circle,
          size: 60,
          color: isPassed ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildResultText() {
    return Column(
      children: [
        Text(
          isPassed ? 'Selamat! 🎉' : 'Coba Lagi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isPassed ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPassed
              ? 'Kamu berhasil menyelesaikan $_typeLabel'
              : 'Kamu belum mencapai nilai minimum',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [Colors.green, Colors.green.shade700]
              : [Colors.red, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Skor Kamu',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPassed ? '✓ LULUS' : '✗ BELUM LULUS',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nilai minimum: ${quiz.passingScore}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.tick_circle,
            label: 'Benar',
            value: '$correctAnswers',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.close_circle,
            label: 'Salah',
            value: '${totalQuestions - correctAnswers}',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.clock,
            label: 'Waktu',
            value: _formatTime(timeSpent),
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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

  Widget _buildReviewButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showReviewSheet(context),
        icon: const Icon(Iconsax.document_text),
        label: const Text('Lihat Pembahasan'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: _typeColor),
          foregroundColor: _typeColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Pop sampai ke Meca Aid screen
              Navigator.of(context).popUntil((route) {
                return route.settings.name == '/meca-aid' || route.isFirst;
              });
            },
            icon: const Icon(Iconsax.home),
            label: const Text('Kembali ke Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _typeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (!isPassed) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Pop dan push ulang quiz detail
                Navigator.of(context).popUntil((route) {
                  return route.settings.name == '/quiz-detail' || route.isFirst;
                });
              },
              icon: const Icon(Iconsax.refresh),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: _typeColor),
                foregroundColor: _typeColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pembahasan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              // Questions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: questions!.length,
                  itemBuilder: (context, index) {
                    final question = questions![index];
                    final userAnswer = answers![question.id];
                    final isCorrect = userAnswer != null &&
                        question.isCorrectAnswer(userAnswer);

                    return _buildReviewItem(
                      index: index,
                      question: question,
                      userAnswer: userAnswer,
                      isCorrect: isCorrect,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required int index,
    required QuestionModel question,
    required String? userAnswer,
    required bool isCorrect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Soal ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCorrect ? Iconsax.tick_circle : Iconsax.close_circle,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                isCorrect ? 'Benar' : 'Salah',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // User answer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jawaban kamu: ',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Expanded(
                child: Text(
                  userAnswer ?? '(tidak dijawab)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          // Correct answer (jika salah)
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jawaban benar: ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Expanded(
                  child: Text(
                    question.correctAnswer,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Explanation
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Iconsax.info_circle, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        'Penjelasan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) {
      return '${secs}s';
    }
    return '${minutes}m ${secs}s';
  }
}
