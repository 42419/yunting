import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/source.dart';
import '../services/api_client.dart';
import '../services/playback_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_cover.dart';
import '../widgets/source_chips.dart';
import 'player_page.dart';

enum _SearchStatus { idle, loading, done, error }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  var _status = _SearchStatus.idle;
  List<Song> _results = const [];
  Set<String> _selectedSources = {};
  String? _error;

  Future<void> _doSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    _focusNode.unfocus();
    setState(() {
      _status = _SearchStatus.loading;
      _error = null;
    });
    try {
      final songs = await ApiClient.instance.search(
        keyword,
        sources: _selectedSources.toList(),
      );
      if (!mounted) return;
      setState(() {
        _results = songs;
        _status = _SearchStatus.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _results = const [];
        _status = _SearchStatus.error;
      });
    }
  }

  void _openPlayer({int? playIndex}) {
    if (playIndex != null) {
      PlaybackController.instance.playQueue(_results, playIndex);
    }
    Navigator.of(context).push(_slideUpRoute(const PlayerPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _SearchField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmit: _doSearch,
              ),
            ),
            SourceChips(
              selected: _selectedSources,
              onChanged: (s) {
                setState(() => _selectedSources = s);
                if (_controller.text.trim().isNotEmpty) _doSearch();
              },
            ),
            const SizedBox(height: 10),
            if (_status == _SearchStatus.loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MiniPlayer(onExpand: () => _openPlayer()),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _SearchStatus.idle:
        return _EmptyState(
          icon: Icons.radio_rounded,
          title: '调到你想听的频道',
          subtitle: '搜歌名，或者直接粘贴一条歌曲链接',
        );
      case _SearchStatus.error:
        return _EmptyState(
          icon: Icons.error_outline_rounded,
          title: '没搜成',
          subtitle: _error ?? '未知错误',
          isError: true,
        );
      case _SearchStatus.loading:
      case _SearchStatus.done:
        if (_results.isEmpty) {
          return _EmptyState(
            icon: Icons.search_off_rounded,
            title: _status == _SearchStatus.loading ? '搜索中…' : '没搜到相关结果',
            subtitle: _status == _SearchStatus.loading ? null : '换个关键词，或者换个频道试试',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final song = _results[index];
            return _SongRow(
              song: song,
              onTap: () => _openPlayer(playIndex: index),
            );
          },
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

Route _slideUpRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 260),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('云听', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '全平台调频',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: '搜歌曲，或粘贴链接',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: controller.clear,
            );
          },
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SongCover(url: song.cover, size: 48, radius: 8),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          MusicSource.shortOf(song.source),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9.5,
                                color: AppColors.textFaint,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(song.durationText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle, this.isError = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: isError ? AppColors.error : AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isError ? AppColors.error : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
