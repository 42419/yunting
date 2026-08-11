import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/playback_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/song_cover.dart';

/// 完整播放页，从首页的迷你播放条或者搜索结果点进来。播放状态全部来自
/// PlaybackController 这个全局单例，这一页本身不持有任何播放器实例，
/// 单纯是个"展开视图"，退出这一页音乐照常播。
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlaybackController.instance;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('正在播放'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final song = controller.current;
          if (song == null) {
            return const Center(
              child: Text('还没有播放任何歌曲', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Column(
                children: [
                  const Spacer(),
                  _GlowingCover(url: song.cover),
                  const SizedBox(height: 32),
                  Text(
                    song.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${song.artist} · ${song.source}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (controller.error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      controller.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  _ProgressBar(player: controller.player),
                  const SizedBox(height: 8),
                  _Controls(controller: controller),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowingCover extends StatelessWidget {
  const _GlowingCover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.12),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SongCover(url: url, size: 260, radius: 20),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.player});

  final AudioPlayer player;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = player.duration ?? Duration.zero;
        final max = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
        final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(position), style: Theme.of(context).textTheme.bodySmall),
                  Text(_fmt(total), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 34,
          color: controller.hasPrevious ? AppColors.textPrimary : AppColors.textFaint,
          onPressed: controller.hasPrevious ? controller.playPrevious : null,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: controller.player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final busy = controller.loading ||
                snapshot.data?.processingState == ProcessingState.loading ||
                snapshot.data?.processingState == ProcessingState.buffering;
            return Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.amber),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.bg),
                    )
                  : IconButton(
                      iconSize: 36,
                      color: AppColors.bg,
                      onPressed: controller.togglePlayPause,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
            );
          },
        ),
        const SizedBox(width: 20),
        IconButton(
          iconSize: 34,
          color: controller.hasNext ? AppColors.textPrimary : AppColors.textFaint,
          onPressed: controller.hasNext ? controller.playNext : null,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}
