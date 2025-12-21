import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/widgets/common_widgets.dart';

class AnimationsScreen extends StatefulWidget {
  final bool embedded;
  const AnimationsScreen({super.key, this.embedded = false});

  @override
  State<AnimationsScreen> createState() => _AnimationsScreenState();
}

class _AnimationsScreenState extends State<AnimationsScreen> {
  List<ModuleModel> _animations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnimations();
  }

  Future<void> _loadAnimations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getModules(category: 'animation');
      setState(() {
        _animations = data.map((e) => ModuleModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat animasi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Animasi Pembelajaran')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _buildHeader(),
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
                color: AppTheme.animationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.play_circle,
                color: AppTheme.animationColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Animasi Pembelajaran',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${_animations.length} video tersedia',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadAnimations),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadAnimations);
    if (_animations.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.play_circle,
          title: 'Belum Ada Animasi',
          subtitle: 'Video animasi akan muncul di sini');

    return RefreshIndicator(
      onRefresh: _loadAnimations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _animations.length,
        itemBuilder: (context, index) {
          final animation = _animations[index];
          return _AnimationCard(
              animation: animation, onTap: () => _openAnimation(animation));
        },
      ),
    );
  }

  void _openAnimation(ModuleModel animation) {
    ActivityLogService().logButtonClick(
        buttonId: 'open_animation_${animation.id}',
        screenName: 'animations_screen');
    Navigator.pushNamed(context, AppRoutes.animationPlayer,
        arguments: animation);
  }
}

class _AnimationCard extends StatelessWidget {
  final ModuleModel animation;
  final VoidCallback onTap;
  const _AnimationCard({required this.animation, required this.onTap});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play button
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.animationColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.animationColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.play5,
                        color: AppTheme.animationColor, size: 40),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animation.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (animation.description != null) ...[
                      const SizedBox(height: 4),
                      Text(animation.description!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Iconsax.video,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        const Text('Video',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textLight)),
                        if (animation.durationMinutes != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Iconsax.clock,
                              size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(animation.durationLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textLight))
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
