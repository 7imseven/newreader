import 'package:flutter/material.dart';
import 'package:venera/foundation/context.dart';
import 'package:venera/pages/video/video_database.dart';
import 'package:venera/pages/video/video_player_page.dart';

class VideoTagListPage extends StatefulWidget {
  final int tagId;
  final String tagName;
  final String tagEmoji;

  const VideoTagListPage({
    super.key,
    required this.tagId,
    required this.tagName,
    required this.tagEmoji,
  });

  @override
  State<VideoTagListPage> createState() => _VideoTagListPageState();
}

class _VideoTagListPageState extends State<VideoTagListPage> {
  final _db = VideoDatabase();
  List<VideoFile> _videos = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _videos = _db.getVideosByTag(widget.tagId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tagEmoji} ${widget.tagName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${_videos.length} videos',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
      body: _videos.isEmpty
          ? Center(
              child: Text('No videos yet',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _videos.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) => _buildVideoTile(_videos[index]),
            ),
    );
  }

  Widget _buildVideoTile(VideoFile video) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.play_circle_fill_outlined,
            size: 28, color: Colors.blue),
      ),
      title: Text(
        video.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          Text(video.durationFormatted,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          if (video.bookmarkCount > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.bookmark, size: 12, color: Colors.amber.shade600),
            const SizedBox(width: 2),
            Text('${video.bookmarkCount}',
                style: TextStyle(
                    fontSize: 12, color: Colors.amber.shade600)),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') _showRenameDialog(video);
          if (value == 'delete') _confirmDelete(video);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: () {
        context.to(() => VideoPlayerPage(videoId: video.id)).then((_) {
          _refresh();
        });
      },
    );
  }

  void _showRenameDialog(VideoFile video) {
    final controller = TextEditingController(text: video.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                _db.updateVideoTitle(video.id, title);
                Navigator.pop(ctx);
                _refresh();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(VideoFile video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete video'),
        content: Text('Delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _db.deleteVideo(video.id);
              Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
