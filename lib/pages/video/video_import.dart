import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/pages/video/video_database.dart';

class VideoImportPage extends StatefulWidget {
  const VideoImportPage({super.key});

  @override
  State<VideoImportPage> createState() => _VideoImportPageState();
}

class _VideoImportPageState extends State<VideoImportPage> {
  final _db = VideoDatabase();
  List<VideoTag> _tags = [];
  String? _selectedPath;
  String? _selectedFileName;
  int? _selectedTagId;

  @override
  void initState() {
    super.initState();
    _tags = _db.getTags();
    _pickFile();
  }

  Future<void> _pickFile() async {
    final typeGroup = XTypeGroup(
      label: '视频',
      extensions: ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'wmv', 'flv'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _selectedPath = file.path;
      _selectedFileName = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('导入视频')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // File info card
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
                        _selectedFileName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击选择其他文件',
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
            controller: TextEditingController(text: _selectedFileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? ''),
            decoration: const InputDecoration(
              hintText: '输入视频标题',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _selectedFileName = v,
          ),

          const SizedBox(height: 24),
          const Text('选择标签', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...(_tags.map((tag) => RadioListTile<int>(
            value: tag.id,
            groupValue: _selectedTagId,
            title: Text('${tag.emoji}  ${tag.name}'),
            onChanged: (v) => setState(() => _selectedTagId = v),
          ))),
          if (_tags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('暂无标签，请先创建', style: TextStyle(color: Colors.grey.shade500)),
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

      // Get duration using ffprobe
      double duration = 0;
      try {
        final result = await Process.run(
          'ffprobe',
          ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', destPath],
        );
        if (result.exitCode == 0) {
          duration = double.tryParse(result.stdout.toString().trim()) ?? 0;
        }
      } catch (_) {}

      _db.addVideo(
        _selectedFileName ?? '未命名',
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
