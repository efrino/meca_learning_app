// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../config/theme.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';

class AnimationPlayerScreen extends StatefulWidget {
  final ModuleModel module;
  const AnimationPlayerScreen({super.key, required this.module});

  @override
  State<AnimationPlayerScreen> createState() => _AnimationPlayerScreenState();
}

class _AnimationPlayerScreenState extends State<AnimationPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final _activityLogService = ActivityLogService();

  bool _isLoading = true;
  String? _error;
  Duration _maxWatchedPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startTracking();
  }

  Future<void> _startTracking() async {
    await _activityLogService.startViewingModule(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      category: widget.module.category,
    );
  }

  Future<void> _initializeVideo() async {
    try {
      final videoUrl =
          'https://drive.google.com/uc?export=download&id=${widget.module.gdriveFileId}';

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _totalDuration = _videoController!.value.duration;

      _videoController!.addListener(_onVideoProgress);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat video: $e';
      });
    }
  }

  void _onVideoProgress() {
    if (_videoController == null) return;

    final currentPosition = _videoController!.value.position;
    if (currentPosition > _maxWatchedPosition) {
      _maxWatchedPosition = currentPosition;
    }

    // Update tracking every 10 seconds
    if (currentPosition.inSeconds % 10 == 0 && currentPosition.inSeconds > 0) {
      final watchPercent = _totalDuration.inSeconds > 0
          ? ((_maxWatchedPosition.inSeconds / _totalDuration.inSeconds) * 100)
              .round()
          : 0;

      _activityLogService.updateCurrentActivity(
        videoWatchPercent: watchPercent,
        actionDetail: 'watching at ${currentPosition.inSeconds}s',
      );
    }
  }

  @override
  void dispose() {
    _endTracking();
    _videoController?.removeListener(_onVideoProgress);
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _endTracking() async {
    final watchPercent = _totalDuration.inSeconds > 0
        ? ((_maxWatchedPosition.inSeconds / _totalDuration.inSeconds) * 100)
            .round()
        : 0;

    await _activityLogService.endCurrentActivity(
      videoWatchPercent: watchPercent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.module.title,
            style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeVideo();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
          _buildVideoInfo(),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            if (widget.module.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.module.description!,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.white.withOpacity(0.5), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Durasi: ${_formatDuration(_totalDuration)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
