import 'dart:io';

import 'package:flutter/material.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/pages/video/video_database.dart';
import 'package:venera/utils/io.dart';

class VideoImportPage extends StatefulWidget {
  const VideoImportPage({super.key});

  @override
  State<VideoImportPage> createState() => _VideoImportPageState();
}

class _VideoImportPageState extends State<VideoImportPage> {
  final _db = VideoDatabase();
  final _titleController = TextEditingController();
  List<VideoTag> _tags = [];
  String? _selectedPath;
  int? _selectedTagId;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _tags = _db.getTags();
    // Open file picker immediately on entry
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFile());
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);

    try {
      // Use Venera's built-in selectFile which handles iOS correctly
      final file = await selectFile(ext: ['mp4', 'mov', 'm4v']);
      if (file == null || !mounted) {
        setState(() => _isPicking = false);
        return;
      }
      setState(() {
        _selectedPath = file.path;
        _titleController.text = file.path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
        _isPicking = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPicking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state while picking
    if (_isPicking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No file selected yet - show picker prompt
    if (_selectedPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入视频')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                '选择一个视频文件导入',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: const Text('选择视频文件'),
              ),
            ],
          ),
        ),
      );
    }

    // File selected - show import form
    return Scaffold(
      appBar: AppBar(title: const Text('导入视频')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_file, size: 40, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击重新选择',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickFile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('视频标题', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: '输入视频标题',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('选择标签', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._tags.map(
            (tag) => RadioListTile<int>(
              value: tag.id,
              groupValue: _selectedTagId,
              title: Text('${tag.emoji}  ${tag.name}'),
              onChanged: (v) => setState(() => _selectedTagId = v),
            ),
          ),
          if (_tags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '暂无标签，请先创建',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: (_selectedTagId == null) ? null : _doImport,
            icon: const Icon(Icons.file_download),
            label: const Text('导入到沙盒'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _doImport() async {
    if (_selectedPath == null || _selectedTagId == null) return;

    final src = File(_selectedPath!);
    final videosDir = Directory('${App.dataPath}/videos');
    if (!videosDir.existsSync()) videosDir.createSync();

    final ext = _selectedPath!.split('.').last;
    final destName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destPath = '${videosDir.path}/$destName';

    try {
      await src.copy(destPath);

      double duration = 0;
      try {
        final result = await Process.run('ffprobe', [
          '-v', 'error',
          '-show_entries', 'format=duration',
          '-of', 'csv=p=0', destPath,
        ]);
        if (result.exitCode == 0) {
          duration = double.tryParse(result.stdout.toString().trim()) ?? 0;
        }
      } catch (_) {}

      _db.addVideo(
        _titleController.text.trim().isEmpty
            ? '未命名'
            : _titleController.text.trim(),
        destPath,
        duration,
        _selectedTagId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }
}
