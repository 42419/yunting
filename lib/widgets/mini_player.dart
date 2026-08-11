import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/playback_controller.dart';
import '../theme/app_theme.dart';
import 'song_cover.dart';

/// 贴底的迷你播放条：搜索页/任何页面切走了播放页，这条状态还在，
/// 点一下展开回完整播放页(app.dart 里挂的路由)。
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final controller = PlaybackController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.current;
        if (song == null) return const SizedBox.shrink();

        return Material(
          color: AppColors.surfaceHigh,
          child: InkWell(
            onTap: onExpand,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部一条极细的播放进度线，不占地方但足够传达"正在进行"
                StreamBuilder<Duration>(
                  stream: controller.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = controller.player.duration ?? Duration.zero;
                    final ratio = total.inMilliseconds > 0
                        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0;
                    return LinearProgressIndicator(
                      value: ratio,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                  child: Row(
                    children: [
                      SongCover(url: song.cover, size: 40, radius: 8),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<PlayerState>(
                        stream: controller.player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          final loading = controller.loading ||
                              snapshot.data?.processingState == ProcessingState.loading ||
                              snapshot.data?.processingState == ProcessingState.buffering;
                          if (loading) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              ),
                            );
                          }
                          return IconButton(
                            iconSize: 30,
                            color: AppColors.textPrimary,
                            onPressed: controller.togglePlayPause,
                            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          );
                        },
                      ),
                      IconButton(
                        iconSize: 26,
                        color: AppColors.textSecondary,
                        onPressed: controller.hasNext ? controller.playNext : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
