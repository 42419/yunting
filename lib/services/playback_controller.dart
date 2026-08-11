import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'api_client.dart';

/// 全局唯一的播放状态管理，取代原来"播放页自己拿一个 AudioPlayer"的写法。
///
/// 这样做的直接原因：想要一个跟 Spotify/网易云一样、退出播放页之后还能贴在
/// 底部继续显示的迷你播放条，播放状态就不能只活在 PlayerPage 这一个 Widget
/// 里，得挪到一个整个 App 生命周期内都存在的地方，首页的迷你播放条和播放页
/// 各自监听同一份状态就行。
///
/// 没有引入 provider 之类的包，就用最朴素的单例 + ChangeNotifier，配合
/// AnimatedBuilder/ListenableBuilder 监听，够用不折腾。
class PlaybackController extends ChangeNotifier {
  PlaybackController._() {
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  static final PlaybackController instance = PlaybackController._();

  final AudioPlayer player = AudioPlayer();

  List<Song> _queue = const [];
  int _index = -1;
  String? _error;
  bool _loading = false;

  List<Song> get queue => _queue;
  int get index => _index;
  String? get error => _error;
  bool get loading => _loading;

  Song? get current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  bool get hasQueue => current != null;
  bool get hasNext => _index >= 0 && _index < _queue.length - 1;
  bool get hasPrevious => _index > 0;

  /// 开始播放一个新的队列(比如一次搜索结果列表)，从 startIndex 这首开始。
  Future<void> playQueue(List<Song> queue, int startIndex) async {
    _queue = queue;
    _index = startIndex;
    notifyListeners();
    await _playCurrent();
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    _index++;
    notifyListeners();
    await _playCurrent();
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    _index--;
    notifyListeners();
    await _playCurrent();
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _playCurrent() async {
    final song = current;
    if (song == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final uri = ApiClient.instance.streamUrl(song);
      await player.setUrl(uri.toString());
      await player.play();
    } catch (e) {
      _error = '播放失败: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
