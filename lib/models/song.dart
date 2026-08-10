/// 对应后端 music-lib 里的 model.Song 结构，字段名与 JSON key 保持一致，
/// 方便直接从 /api/v1/music/search 等接口的返回值反序列化。
class Song {
  final String id;
  final String name;
  final String artist;
  final String album;
  final int duration; // 秒
  final int bitrate; // kbps
  final String source; // netease, qq, kugou, kuwo, bilibili, soda, migu, fivesing...
  final String cover;
  final String ext;

  const Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.duration,
    required this.bitrate,
    required this.source,
    required this.cover,
    required this.ext,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      album: (json['album'] ?? '').toString(),
      duration: (json['duration'] is int) ? json['duration'] as int : 0,
      bitrate: (json['bitrate'] is int) ? json['bitrate'] as int : 0,
      source: (json['source'] ?? '').toString(),
      cover: (json['cover'] ?? '').toString(),
      ext: (json['ext'] ?? '').toString(),
    );
  }

  String get durationText {
    if (duration <= 0) return '--:--';
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
