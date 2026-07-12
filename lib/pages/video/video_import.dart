import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/pages/video/video_database.dart';

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

  @override
  void initState() {
    super.initState();
    _tags = _db.getTags();
    _pickFile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final typeGroup = XTypeGroup(
      label: 'video',
      extensions: ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'wmv', 'flv'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _selectedPath = file.path;
      _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import video')),
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
                        'Tap to choose another file',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
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
          const Text('Video title', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Enter video title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Select tag', style: TextStyle(fontWeight: FontWeight.w600)),
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
                'No tags yet. Create one first.',
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
            label: const Text('Import'),
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
    if (!videosDir.existsSync()) videosDir.createSync(recursive: true);

    final ext = _selectedPath!.split('.').last;
    final destName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destPath = '${videosDir.path}/$destName';

    try {
      await src.copy(destPath);

      double duration = 0;
      try {
        final result = await Process.run(
          'ffprobe',
          [
            '-v',
            'error',
            '-show_entries',
            'format=duration',
            '-of',
            'csv=p=0',
            destPath,
          ],
        );
        if (result.exitCode == 0) {
          duration = double.tryParse(result.stdout.toString().trim()) ?? 0;
        }
      } catch (_) {}

      _db.addVideo(
        _titleController.text.trim().isEmpty
            ? 'Untitled'
            : _titleController.text.trim(),
        destPath,
        duration,
        _selectedTagId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import success')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}
