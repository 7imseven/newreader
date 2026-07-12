import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:venera/foundation/app.dart';

class VideoTag {
  final int id;
  final String name;
  final String emoji;
  final String color;
  final DateTime createdAt;
  final int videoCount;

  VideoTag({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.createdAt,
    this.videoCount = 0,
  });

  factory VideoTag.fromRow(Row row, {int videoCount = 0}) => VideoTag(
        id: row['id'] as int,
        name: row['name'] as String,
        emoji: row['emoji'] as String,
        color: row['color'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        videoCount: videoCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color,
      };
}

class VideoFile {
  final int id;
  final String title;
  final String filePath;
  final double duration;
  final int tagId;
  final DateTime createdAt;
  final int bookmarkCount;

  VideoFile({
    required this.id,
    required this.title,
    required this.filePath,
    required this.duration,
    required this.tagId,
    required this.createdAt,
    this.bookmarkCount = 0,
  });

  factory VideoFile.fromRow(Row row, {int bookmarkCount = 0}) => VideoFile(
        id: row['id'] as int,
        title: row['title'] as String,
        filePath: row['file_path'] as String,
        duration: (row['duration'] as num).toDouble(),
        tagId: row['tag_id'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        bookmarkCount: bookmarkCount,
      );

  String get durationFormatted {
    final d = Duration(seconds: duration.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

class VideoBookmark {
  final int id;
  final int videoId;
  final String title;
  final double timestamp;
  final DateTime createdAt;

  VideoBookmark({
    required this.id,
    required this.videoId,
    required this.title,
    required this.timestamp,
    required this.createdAt,
  });

  factory VideoBookmark.fromRow(Row row) => VideoBookmark(
        id: row['id'] as int,
        videoId: row['video_id'] as int,
        title: row['title'] as String,
        timestamp: (row['timestamp'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );

  String get timestampFormatted {
    final d = Duration(seconds: timestamp.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

class VideoDatabase {
  static VideoDatabase? _instance;
  late Database _db;

  VideoDatabase._();

  factory VideoDatabase() => _instance ??= VideoDatabase._();

  void init() {
    _db = sqlite3.open('${App.dataPath}/videos.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        emoji TEXT NOT NULL DEFAULT '📁',
        color TEXT NOT NULL DEFAULT '#4A90D9',
        created_at INTEGER NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL UNIQUE,
        duration REAL NOT NULL DEFAULT 0,
        tag_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        timestamp REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
      );
    ''');
  }

  void dispose() => _db.dispose();

  // ── Tags ──

  List<VideoTag> getTags() {
    final rows = _db.select('''
      SELECT t.*, (SELECT COUNT(*) FROM videos WHERE tag_id = t.id) AS video_count
      FROM tags t ORDER BY t.created_at DESC
    ''');
    return rows.map((r) => VideoTag.fromRow(r, videoCount: r['video_count'] as int)).toList();
  }

  VideoTag? getTag(int id) {
    final rows = _db.select('SELECT * FROM tags WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return VideoTag.fromRow(rows.first);
  }

  int addTag(String name, {String emoji = '📁', String color = '#4A90D9'}) {
    _db.execute(
      'INSERT OR IGNORE INTO tags (name, emoji, color, created_at) VALUES (?, ?, ?, ?)',
      [name, emoji, color, DateTime.now().millisecondsSinceEpoch],
    );
    final result = _db.select('SELECT id FROM tags WHERE name = ?', [name]);
    return result.first['id'] as int;
  }

  void deleteTag(int id) {
    // Delete all videos and bookmarks under this tag first
    final videos = _db.select('SELECT file_path FROM videos WHERE tag_id = ?', [id]);
    for (var v in videos) {
      File(v['file_path'] as String).deleteSync();
    }
    _db.execute('DELETE FROM tags WHERE id = ?', [id]);
  }

  void updateTag(int id, {String? name, String? emoji, String? color}) {
    if (name != null) _db.execute('UPDATE tags SET name = ? WHERE id = ?', [name, id]);
    if (emoji != null) _db.execute('UPDATE tags SET emoji = ? WHERE id = ?', [emoji, id]);
    if (color != null) _db.execute('UPDATE tags SET color = ? WHERE id = ?', [color, id]);
  }

  // ── Videos ──

  List<VideoFile> getVideosByTag(int tagId) {
    final rows = _db.select('''
      SELECT v.*, (SELECT COUNT(*) FROM bookmarks WHERE video_id = v.id) AS bookmark_count
      FROM videos v WHERE v.tag_id = ? ORDER BY v.created_at DESC
    ''', [tagId]);
    return rows.map((r) => VideoFile.fromRow(r, bookmarkCount: r['bookmark_count'] as int)).toList();
  }

  VideoFile? getVideo(int id) {
    final rows = _db.select('SELECT * FROM videos WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return VideoFile.fromRow(rows.first);
  }

  int addVideo(String title, String filePath, double duration, int tagId) {
    _db.execute(
      'INSERT INTO videos (title, file_path, duration, tag_id, created_at) VALUES (?, ?, ?, ?, ?)',
      [title, filePath, duration, tagId, DateTime.now().millisecondsSinceEpoch],
    );
    final result = _db.select('SELECT id FROM videos WHERE file_path = ?', [filePath]);
    return result.first['id'] as int;
  }

  void deleteVideo(int id) {
    final rows = _db.select('SELECT file_path FROM videos WHERE id = ?', [id]);
    if (rows.isNotEmpty) {
      File(rows.first['file_path'] as String).deleteSync();
    }
    _db.execute('DELETE FROM videos WHERE id = ?', [id]);
  }

  void updateVideoTitle(int id, String title) {
    _db.execute('UPDATE videos SET title = ? WHERE id = ?', [title, id]);
  }

  // ── Bookmarks ──

  List<VideoBookmark> getBookmarks(int videoId) {
    final rows = _db.select(
      'SELECT * FROM bookmarks WHERE video_id = ? ORDER BY timestamp ASC',
      [videoId],
    );
    return rows.map((r) => VideoBookmark.fromRow(r)).toList();
  }

  int addBookmark(int videoId, String title, double timestamp) {
    _db.execute(
      'INSERT INTO bookmarks (video_id, title, timestamp, created_at) VALUES (?, ?, ?, ?)',
      [videoId, title, timestamp, DateTime.now().millisecondsSinceEpoch],
    );
    final result = _db.select('SELECT id FROM bookmarks WHERE id = last_insert_rowid()');
    return result.first['id'] as int;
  }

  void deleteBookmark(int id) {
    _db.execute('DELETE FROM bookmarks WHERE id = ?', [id]);
  }

  void updateBookmarkTitle(int id, String title) {
    _db.execute('UPDATE bookmarks SET title = ? WHERE id = ?', [title, id]);
  }
}
