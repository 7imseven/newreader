import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:venera/foundation/context.dart';
import 'package:venera/pages/video/video_database.dart';

class VideoPlayerPage extends StatefulWidget {
  final int videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final _db = VideoDatabase();
  late VideoPlayerController _controller;
  late VideoFile _video;
  List<VideoBookmark> _bookmarks = [];
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideTimer;

  // Gesture seek
  double _seekStartOffset = 0;
  double _seekDelta = 0;
  bool _isSeeking = false;

  // Bookmark overlay
  bool _showBookmarks = false;

  @override
  void initState() {
    super.initState();
    _video = _db.getVideo(widget.videoId)!;
    _bookmarks = _db.getBookmarks(widget.videoId);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.file(File(_video.filePath));
    await _controller.initialize();
    setState(() => _isInitialized = true);
    _controller.play();
    _isPlaying = true;
    _startHideTimer();
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
    _startHideTimer();
  }

  void _seekTo(double position) {
    _controller.seekTo(Duration(seconds: position.round()));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ── Gesture Seek ──

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!_isInitialized) return;
    _seekStartOffset = details.localPosition.dx;
    _seekDelta = 0;
    _isSeeking = true;
    setState(() => _showControls = true);
  }

  // ...existing code...

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isInitialized || !_isSeeking) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final deltaPixels = details.localPosition.dx - _seekStartOffset;
    // Convert pixels to seconds: full screen ≈ 60s
    _seekDelta = (deltaPixels / screenWidth) * 60;
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isInitialized || !_isSeeking) return;
    final currentPos = _controller.value.position.inSeconds;
    final targetPos = (currentPos + _seekDelta).clamp(0, _controller.value.duration.inSeconds);
    _seekTo(targetPos.toDouble());
    _isSeeking = false;
    _seekDelta = 0;
    _startHideTimer();
    setState(() {});
  }

  // ── Bookmark ──

  void _showAddBookmarkDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加书签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前时间: ${_formatDuration(_controller.value.position)}'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '书签名称',
                hintText: '例如: 精彩片段',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                _db.addBookmark(
                  widget.videoId,
                  title,
                  _controller.value.position.inMilliseconds / 1000.0,
                );
                _bookmarks = _db.getBookmarks(widget.videoId);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _toggleBookmarkOverlay() {
    setState(() => _showBookmarks = !_showBookmarks);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startHideTimer();
        },
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Stack(
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Seek overlay
            if (_isSeeking)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _seekDelta >= 0 ? Icons.fast_forward : Icons.fast_rewind,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_seekDelta >= 0 ? '+' : ''}${_seekDelta.toStringAsFixed(0)}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls overlay
            if (_showControls) _buildControls(),

            // Bookmark list
            if (_showBookmarks) _buildBookmarkOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.only(bottom: 8),
              colors: VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
            // Time + buttons
            Row(
              children: [
                Text(
                  '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                // Bookmark button
                IconButton(
                  icon: Icon(
                    Icons.bookmark_add_outlined,
                    color: _bookmarks.isNotEmpty ? Colors.amber.shade300 : Colors.white70,
                  ),
                  onPressed: _showAddBookmarkDialog,
                ),
                IconButton(
                  icon: Icon(
                    Icons.bookmarks_outlined,
                    color: _bookmarks.isNotEmpty ? Colors.amber.shade300 : Colors.white70,
                  ),
                  onPressed: _bookmarks.isNotEmpty ? _toggleBookmarkOverlay : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkOverlay() {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('书签', style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleBookmarkOverlay,
            ),
          ),
          Expanded(
            child: _bookmarks.isEmpty
                ? const Center(child: Text('暂无书签', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bm = _bookmarks[index];
                      return ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.amber),
                        title: Text(bm.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          bm.timestampFormatted,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          _seekTo(bm.timestamp);
                          _toggleBookmarkOverlay();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
