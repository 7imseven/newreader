import 'package:flutter/material.dart';
import 'package:venera/foundation/app.dart';
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
        title: const Text('视频', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _importVideo,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('导入'),
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
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('还没有视频', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _importVideo,
            icon: const Icon(Icons.add),
            label: const Text('导入第一个视频'),
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
        itemCount: _tags.length + 1, // +1 for "new tag" card
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
        context.to(() => VideoTagListPage(tagId: tag.id, tagName: tag.name, tagEmoji: tag.emoji))
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
              '${tag.videoCount} 个视频',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTagCard() {
    return GestureDetector(
      onTap: () => _showCreateTagDialog(),
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
              '新建标签',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTagDialog() {
    final controller = TextEditingController();
    String selectedEmoji = '📁';
    String selectedColor = '#4A90D9';
    final emojis = ['📁', '🎮', '📚', '🎵', '🎬', '📝', '💻', '🎨', '🏃', '🌍', '🔧', '📦'];
    final colors = ['#4A90D9', '#E74C3C', '#2ECC71', '#F39C12', '#9B59B6', '#1ABC9C', '#E67E22', '#34495E'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('新建标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '标签名称',
                  hintText: '例如: 游戏、教育',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('选择图标', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => setDState(() => selectedEmoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedEmoji == e ? Colors.blue.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: selectedEmoji == e ? Border.all(color: Colors.blue) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _db.addTag(controller.text.trim(), emoji: selectedEmoji, color: selectedColor);
                  Navigator.pop(dialogCtx);
                  _refresh();
                }
              },
              child: const Text('创建'),
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
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameTagDialog(tag);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除标签', style: TextStyle(color: Colors.red)),
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
        title: const Text('重命名标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _db.updateTag(tag.id, name: controller.text.trim());
                Navigator.pop(ctx);
                _refresh();
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTag(VideoTag tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('删除「${tag.name}」将同时删除该标签下的 ${tag.videoCount} 个视频，确定吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _db.deleteTag(tag.id);
              Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('删除'),
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
