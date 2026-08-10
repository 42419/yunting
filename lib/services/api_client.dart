import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/song.dart';
import 'backend_launcher.dart';

/// 对接内嵌 go-music-api 后端 `/api/v1/*` 接口的轻量封装。
/// 接口约定见 server/router/router.go 和 server/handler/music.go。
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _base = BackendLauncher.baseUrl;

  /// 综合搜索：既支持关键字搜索，也支持直接粘贴各平台歌曲/歌单/专辑链接解析。
  Future<List<Song>> search(String keyword) async {
    final uri = Uri.parse('$_base/api/v1/music/search').replace(
      queryParameters: {'q': keyword, 'type': 'song'},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('搜索失败: HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw Exception(body['msg']?.toString() ?? '搜索失败');
    }
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final songsJson = data['songs'] as List<dynamic>? ?? const [];
    return songsJson
        .map((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 播放/串流地址：直接把这个 URL 丢给播放器就行，后端会代理原始音频流
  /// (包括处理防盗链、以及汽水音乐的加密音频解密)，支持 HTTP Range。
  Uri streamUrl(Song song) {
    return Uri.parse('$_base/api/v1/music/stream').replace(queryParameters: {
      'id': song.id,
      'source': song.source,
      'name': song.name,
      'artist': song.artist,
    });
  }

  /// 获取 LRC 歌词文本。部分平台/歌曲可能没有歌词，返回空字符串。
  Future<String> lyric(Song song) async {
    final uri = Uri.parse('$_base/api/v1/music/lyric').replace(
      queryParameters: {'id': song.id, 'source': song.source},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return '';
    final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (body['code'] != 200) return '';
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return (data['lyric'] ?? '').toString();
  }
}
