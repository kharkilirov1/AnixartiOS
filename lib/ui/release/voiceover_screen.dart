import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../player/player_screen.dart';
import '../widgets.dart';

/// Выбор озвучки (screenshot 13): полноэкранный список типов
/// «Название · N эп.» + просмотры справа, бейдж «Новинка».
class VoiceoverScreen extends StatefulWidget {
  final Release release;
  const VoiceoverScreen({super.key, required this.release});

  @override
  State<VoiceoverScreen> createState() => _VoiceoverScreenState();
}

class _VoiceoverScreenState extends State<VoiceoverScreen> {
  List<EpisodeType> _types = [];
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final t = await Api.I.episodeTypes(widget.release.id);
      if (mounted) setState(() => _types = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Выберите вариант',
      actions: [
        IconButton(icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary), onPressed: () {}),
      ],
      body: Column(children: [
        // Hint card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('Подсказка', style: TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
              SizedBox(width: 6),
              Icon(Icons.lightbulb_outline, size: 15, color: AppColors.textTertiary),
            ]),
            const SizedBox(height: 6),
            Text('Напротив каждого варианта озвучки указано общее количество доступных серий. Статистика просмотров обновляется ежедневно.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textTertiary.withOpacity(0.85), height: 1.4)),
          ]),
        ),
        Expanded(
          child: _error != null
              ? ErrorCentered(message: _error!, onRetry: _load)
              : _types.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
                  : ListView.separated(
                      itemCount: _types.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
                      itemBuilder: (context, i) {
                        final t = _types[i];
                        final views = t.viewCount ?? 0;
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PlayerLoaderScreen(
                                  release: widget.release, type: t))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            child: Row(children: [
                              Text(t.name ?? '',
                                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              Text('·  ${t.episodesCount ?? 0} эп.',
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
                              const Spacer(),
                              if ((t.name ?? '').toLowerCase().contains('anistar') ||
                                  (t.name ?? '').toLowerCase().contains('новинк'))
                                Container(margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.badgeNew),
                                        borderRadius: BorderRadius.circular(7)),
                                    child: const Text('НОВИНКА',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                            color: AppColors.badgeNew))),
                              Text(_compact(views),
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
                              const SizedBox(width: 8),
                              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textTertiary),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  String _compact(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}K';
    return '$n';
  }
}

/// Loads sources for the selected voiceover and opens the episode picker.
class PlayerLoaderScreen extends StatefulWidget {
  final Release release;
  final EpisodeType type;
  const PlayerLoaderScreen({super.key, required this.release, required this.type});

  @override
  State<PlayerLoaderScreen> createState() => _PlayerLoaderScreenState();
}

class _PlayerLoaderScreenState extends State<PlayerLoaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    try {
      final sources = await Api.I.episodeSources(widget.release.id, widget.type.id);
      if (sources.isEmpty) throw Exception('Нет источников');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => EpisodesScreen(
              release: widget.release, type: widget.type, sources: sources)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.bg,
          body: Center(child: CircularProgressIndicator(color: AppColors.textSecondary)));
}

/// «Выберите серию» (эталон voice_b): вертикальный список серий,
/// подзаголовок с источником, чипы источников если их несколько.
class EpisodesScreen extends StatefulWidget {
  final Release release;
  final EpisodeType type;
  final List<EpisodeSource> sources;
  const EpisodesScreen({super.key, required this.release, required this.type, required this.sources});

  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  late EpisodeSource _source;
  List<Episode> _episodes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source = widget.sources.first;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final eps = await Api.I.episodes(widget.release.id, widget.type.id, _source.id);
      if (mounted) setState(() { _episodes = eps; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // App bar: back, «Выберите серию / Источник …», actions
          SizedBox(
            height: 64,
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 26),
                  onPressed: () => Navigator.maybePop(context)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Выберите серию',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                Text('Источник ${_source.name ?? ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])),
              IconButton(icon: const Icon(Icons.swap_vert_rounded, size: 24, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _episodes = _episodes.reversed.toList())),
              IconButton(icon: const Icon(Icons.history_rounded, size: 24, color: AppColors.textSecondary),
                  onPressed: () {}),
              IconButton(icon: const Icon(Icons.more_vert, size: 24, color: AppColors.textSecondary),
                  onPressed: () {}),
            ]),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Source chips (if several)
          if (widget.sources.length > 1)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.sources.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final src = widget.sources[i];
                  final active = src.id == _source.id;
                  return GestureDetector(
                    onTap: () { if (!active) { _source = src; _load(); } },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(child: Text('${src.name} · ${src.episodesCount ?? 0} эп.',
                          style: TextStyle(fontSize: 13.5,
                              color: active ? Colors.white : AppColors.textSecondary))),
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
                : _error != null
                    ? ErrorCentered(message: _error!, onRetry: _load)
                    : _episodes.isEmpty
                        ? const Center(child: Text('Нет эпизодов',
                            style: TextStyle(color: AppColors.textTertiary)))
                        : ListView.separated(
                            itemCount: _episodes.length + 2,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
                            itemBuilder: (context, i) {
                              // Section header: voiceover name
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                                  child: Align(alignment: Alignment.centerLeft,
                                      child: Text(widget.type.name ?? '',
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                                );
                              }
                              // Hint card
                              if (i == 1) {
                                return Container(
                                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.outline),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Text(
                                      'Если серия не запускается ни через какой видеоплеер, попробуйте сменить источник, если это доступно. Любая реклама в видео к приложению отношения не имеет.',
                                      style: TextStyle(fontSize: 13.5,
                                          color: AppColors.textTertiary.withOpacity(0.9), height: 1.45)),
                                );
                              }
                              final ep = _episodes[i - 2];
                              final watched = ep.isWatched == true;
                              return InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                        release: widget.release, type: widget.type,
                                        source: _source, episodes: _episodes,
                                        initialIndex: i - 2))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  child: Row(children: [
                                    Expanded(child: Text(
                                        ep.name ?? 'Серия ${ep.position ?? i - 1}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: watched ? AppColors.badgeNew : AppColors.textPrimary))),
                                    IconButton(
                                        icon: const Icon(Icons.download_outlined,
                                            size: 22, color: AppColors.textTertiary),
                                        onPressed: () {}),
                                    IconButton(
                                        icon: const Icon(Icons.more_vert,
                                            size: 22, color: AppColors.textTertiary),
                                        onPressed: () {}),
                                  ]),
                                ),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }
}
