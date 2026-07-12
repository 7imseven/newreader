import 'package:flutter/material.dart';
import 'package:venera/foundation/context.dart';
import 'package:venera/pages/video/video_database.dart';
import 'package:venera/pages/video/video_import.dart';
import 'package:venera/pages/video/video_tag_list.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final _db = VideoDatabase();
  List<VideoTag> _tags = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _tags = _db.getTags());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _importVideo,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Import'),
          ),
        ],
      ),
      body: _tags.isEmpty ? _buildEmptyState() : _buildTagGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No videos yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _importVideo,
            icon: const Icon(Icons.add),
            label: const Text('Import first video'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGrid() {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _tags.length + 1,
        itemBuilder: (context, index) {
          if (index == _tags.length) return _buildNewTagCard();
          return _buildTagCard(_tags[index]);
        },
      ),
    );
  }

  Widget _buildTagCard(VideoTag tag) {
    final color = _parseColor(tag.color);
    return GestureDetector(
      onTap: () {
        context
            .to(() => VideoTagListPage(
                  tagId: tag.id,
                  tagName: tag.name,
                  tagEmoji: tag.emoji,
                ))
            .then((_) => _refresh());
      },
      onLongPress: () => _showTagMenu(tag),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tag.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${tag.videoCount} videos',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTagCard() {
    return GestureDetector(
      onTap: _showCreateTagDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'New tag',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTagDialog() {
    final controller = TextEditingController();
    String selectedEmoji = '🎬';
    String selectedColor = '#4A90D9';

    const emojis = ['🎬', '📺', '🎮', '📽️', '🎵', '📰', '🧪', '📚'];
    const colors = [
      '#4A90D9',
      '#E74C3C',
      '#2ECC71',
      '#F39C12',
      '#9B59B6',
      '#1ABC9C',
      '#E67E22',
      '#34495E',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('New tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Tag name',
                  hintText: 'Example: Games, Education',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Pick an icon', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojis
                    .map(
                      (e) => GestureDetector(
                        onTap: () => setDState(() => selectedEmoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedEmoji == e
                                ? Colors.blue.withOpacity(0.1)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: selectedEmoji == e
                                ? Border.all(color: Colors.blue)
                                : null,
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text('Pick a color', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: colors
                    .map(
                      (c) => GestureDetector(
                        onTap: () => setDState(() => selectedColor = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _parseColor(c),
                            shape: BoxShape.circle,
                            border: selectedColor == c
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _db.addTag(name, emoji: selectedEmoji, color: selectedColor);
                  Navigator.pop(dialogCtx);
                  _refresh();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagMenu(VideoTag tag) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameTagDialog(tag);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete tag', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTag(tag);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameTagDialog(VideoTag tag) {
    final controller = TextEditingController(text: tag.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename tag'),
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _db.updateTag(tag.id, name: name);
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

  void _confirmDeleteTag(VideoTag tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tag'),
        content: Text(
            'Delete "${tag.name}" and all ${tag.videoCount} videos under it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _db.deleteTag(tag.id);
              Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _importVideo() {
    context.to(() => const VideoImportPage()).then((_) => _refresh());
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
